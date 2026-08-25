#!/usr/bin/env bash
# Make the static media bucket publicly readable and sync local media/ to it.
# Usage (GitHub Actions / local with AWS creds):
#   STATIC_BUCKET_NAME=aniverse-static-... bash scripts/sync_media_to_s3.sh
set -euo pipefail

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MEDIA_DIR="${MEDIA_DIR:-$ROOT_DIR/media}"

if [ -z "${STATIC_BUCKET_NAME:-}" ]; then
  STATIC_BUCKET_NAME=$(aws s3api list-buckets \
    --query "Buckets[?starts_with(Name, 'aniverse-static')].Name | [0]" \
    --output text)
fi

if [ -z "$STATIC_BUCKET_NAME" ] || [ "$STATIC_BUCKET_NAME" = "None" ]; then
  echo "STATIC_BUCKET_NAME could not be resolved" >&2
  exit 1
fi

echo "Using bucket: s3://$STATIC_BUCKET_NAME (region=$AWS_REGION)"

# Object Ownership: BucketOwnerEnforced (ACLs off) — bucket policy is enough
aws s3api put-bucket-ownership-controls \
  --bucket "$STATIC_BUCKET_NAME" \
  --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]' \
  >/dev/null || true

# Allow public bucket policy
aws s3api put-public-access-block \
  --bucket "$STATIC_BUCKET_NAME" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false"

POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${STATIC_BUCKET_NAME}/*"
    }
  ]
}
EOF
)
aws s3api put-bucket-policy --bucket "$STATIC_BUCKET_NAME" --policy "$POLICY"

# Optional CORS for browsers / canvas
aws s3api put-bucket-cors --bucket "$STATIC_BUCKET_NAME" --cors-configuration '{
  "CORSRules": [{
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "HEAD"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }]
}' || true

if [ ! -d "$MEDIA_DIR" ]; then
  echo "Media dir missing: $MEDIA_DIR" >&2
  exit 1
fi

echo "Syncing $MEDIA_DIR → s3://$STATIC_BUCKET_NAME/"
aws s3 sync "$MEDIA_DIR/" "s3://$STATIC_BUCKET_NAME/" \
  --region "$AWS_REGION" \
  --exclude "test_check*" \
  --exclude "*.txt" \
  --exclude "*.txtsudo" \
  --cache-control "public,max-age=86400"

# Also pick up any root-level goods_images/works_images leftovers
for extra in goods_images works_images; do
  if [ -d "$ROOT_DIR/$extra" ]; then
    echo "Syncing $ROOT_DIR/$extra → s3://$STATIC_BUCKET_NAME/$extra/"
    aws s3 sync "$ROOT_DIR/$extra/" "s3://$STATIC_BUCKET_NAME/$extra/" \
      --region "$AWS_REGION" \
      --cache-control "public,max-age=86400"
  fi
done

SAMPLE=$(aws s3 ls "s3://$STATIC_BUCKET_NAME/goods_images/" --region "$AWS_REGION" | head -1 | awk '{print $NF}')
if [ -n "$SAMPLE" ]; then
  URL="https://${STATIC_BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com/goods_images/${SAMPLE}"
  echo "Probe: $URL"
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" || true)
  echo "HTTP $CODE"
  if [ "$CODE" != "200" ]; then
    echo "WARNING: sample object not publicly readable (HTTP $CODE)" >&2
  fi
fi

echo "Media sync complete."
