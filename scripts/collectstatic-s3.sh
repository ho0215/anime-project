#!/usr/bin/env bash
# 로컬/CI에서 collectstatic → S3 (앱 Pod에 nginx 없음 전제)
#
# Django storages 의 파일별 HeadObject 는 랩 네트워크에서 매우 느릴 수 있어
# 1) 로컬 staticfiles/ 로 collectstatic
# 2) aws s3 sync 로 업로드
#
#   export AWS_STORAGE_BUCKET_NAME=aniverse-static-841535407395-ap-northeast-2
#   export AWS_S3_REGION_NAME=ap-northeast-2
#   ./scripts/collectstatic-s3.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUCKET="${AWS_STORAGE_BUCKET_NAME:-}"
REGION="${AWS_S3_REGION_NAME:-ap-northeast-2}"

if [ -z "${BUCKET}" ]; then
  echo "Set AWS_STORAGE_BUCKET_NAME" >&2
  exit 1
fi

if ! command -v aws >/dev/null; then
  echo "aws CLI 필요" >&2
  exit 1
fi

if command -v python3 >/dev/null; then
  PY=python3
elif command -v python >/dev/null; then
  PY=python
else
  echo "python3 필요" >&2
  exit 1
fi

if [ -d .venv ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
elif [ -d venv ]; then
  # shellcheck disable=SC1091
  source venv/bin/activate
fi

export AWS_DEFAULT_REGION="${REGION}"
export AWS_S3_REGION_NAME="${REGION}"

# collectstatic 은 로컬 디스크에만 (S3 storage 끄기)
unset AWS_STORAGE_BUCKET_NAME
export DJANGO_SECRET_KEY="${DJANGO_SECRET_KEY:-collectstatic-only-not-for-prod}"
export DJANGO_DEBUG="${DJANGO_DEBUG:-False}"
export DJANGO_ALLOWED_HOSTS="${DJANGO_ALLOWED_HOSTS:-localhost}"
export DB_NAME="${DB_NAME:-aniverse}"
export DB_USER="${DB_USER:-aniverse}"
export DB_PASSWORD="${DB_PASSWORD:-unused}"
export DB_HOST="${DB_HOST:-127.0.0.1}"
export DB_PORT="${DB_PORT:-3306}"

echo "==> 1/2 collectstatic → ./staticfiles/ (local)"
"${PY}" manage.py collectstatic --noinput -v 1

if [ ! -d staticfiles ] || [ -z "$(ls -A staticfiles 2>/dev/null || true)" ]; then
  echo "staticfiles/ 비어 있음" >&2
  exit 1
fi

echo "==> 2/2 aws s3 sync → s3://${BUCKET}/static/"
aws s3 sync staticfiles/ "s3://${BUCKET}/static/" \
  --region "${REGION}" \
  --only-show-errors

echo
echo "OK"
echo "  sample: https://${BUCKET}.s3.${REGION}.amazonaws.com/static/admin/css/base.css"
echo "  check:  aws s3 ls s3://${BUCKET}/static/ | head"
