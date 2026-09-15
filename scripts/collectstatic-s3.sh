#!/usr/bin/env bash
# 로컬/CI에서 collectstatic → S3 (앱 Pod에 nginx 없음 전제)
# 사전: AWS 자격 증명, 버킷 쓰기 권한, 레포 루트에서 실행
#
#   export AWS_STORAGE_BUCKET_NAME=aniverse-static-ho0215-dev-2026-679583587966-ap-northeast-2
#   export AWS_S3_REGION_NAME=ap-northeast-2
#   ./scripts/collectstatic-s3.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUCKET="${AWS_STORAGE_BUCKET_NAME:-}"
REGION="${AWS_S3_REGION_NAME:-ap-northeast-2}"

if [ -z "${BUCKET}" ]; then
  echo "Set AWS_STORAGE_BUCKET_NAME (Terraform output static_bucket_name)" >&2
  exit 1
fi

export AWS_STORAGE_BUCKET_NAME="${BUCKET}"
export AWS_S3_REGION_NAME="${REGION}"
# settings 가 DB 없이 collectstatic 가능하도록 최소 env
export DJANGO_SECRET_KEY="${DJANGO_SECRET_KEY:-collectstatic-only-not-for-prod}"
export DJANGO_DEBUG="${DJANGO_DEBUG:-False}"
export DJANGO_ALLOWED_HOSTS="${DJANGO_ALLOWED_HOSTS:-localhost}"
export DB_NAME="${DB_NAME:-aniverse}"
export DB_USER="${DB_USER:-aniverse}"
export DB_PASSWORD="${DB_PASSWORD:-unused}"
export DB_HOST="${DB_HOST:-127.0.0.1}"
export DB_PORT="${DB_PORT:-3306}"

if command -v python3 >/dev/null; then
  PY=python3
elif command -v python >/dev/null; then
  PY=python
else
  echo "python3 가 필요합니다 (sudo apt install python3 python3-venv python3-pip)" >&2
  exit 1
fi

if [ -d .venv ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
elif [ -d venv ]; then
  # shellcheck disable=SC1091
  source venv/bin/activate
fi

echo "==> collectstatic → s3://${BUCKET}/static/ (${REGION})"
"${PY}" manage.py collectstatic --noinput

echo "OK — STATIC_URL 예: https://${BUCKET}.s3.${REGION}.amazonaws.com/static/"
