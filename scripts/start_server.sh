#!/bin/bash
set -euo pipefail

PROJECT_DIR="/home/ubuntu/aniverse"

echo "=== Ensure runtime .env (DB + S3 bucket) ==="
chmod +x "$PROJECT_DIR/scripts/ensure_runtime_env.sh" 2>/dev/null || true
if [ -x "$PROJECT_DIR/scripts/ensure_runtime_env.sh" ]; then
  bash "$PROJECT_DIR/scripts/ensure_runtime_env.sh" || echo "WARN: ensure_runtime_env failed" >&2
elif [ ! -f "$PROJECT_DIR/.env" ] && [ -f /etc/aniverse.env ]; then
  cp /etc/aniverse.env "$PROJECT_DIR/.env"
  chown ubuntu:ubuntu "$PROJECT_DIR/.env"
  chmod 600 "$PROJECT_DIR/.env"
fi

# Nginx 가 /media/ 를 읽을 수 있도록 (ubuntu-only 700 이면 403)
mkdir -p "$PROJECT_DIR/media"
chmod 755 "$PROJECT_DIR/media" || true
find "$PROJECT_DIR/media" -type d -exec chmod 755 {} + 2>/dev/null || true
find "$PROJECT_DIR/media" -type f -exec chmod 644 {} + 2>/dev/null || true

# S3 에 미디어가 있으면 EFS/local 로도 동기화 (/media/ fallback + 신규 업로드 전 대비)
BUCKET=""
if [ -f "$PROJECT_DIR/.env" ]; then
  BUCKET=$(grep -E '^AWS_STORAGE_BUCKET_NAME=' "$PROJECT_DIR/.env" | head -1 | cut -d= -f2- | tr -d "'\"")
fi
if [ -z "$BUCKET" ] && [ -f /etc/aniverse.env ]; then
  BUCKET=$(grep -E '^AWS_STORAGE_BUCKET_NAME=' /etc/aniverse.env | head -1 | cut -d= -f2- | tr -d "'\"")
fi
if [ -n "$BUCKET" ] && command -v aws >/dev/null 2>&1; then
  echo "=== Sync media from s3://$BUCKET → $PROJECT_DIR/media ==="
  aws s3 sync "s3://$BUCKET/" "$PROJECT_DIR/media/" \
    --region "${AWS_REGION:-ap-northeast-2}" \
    --exclude "test_check*" \
    --only-show-errors || echo "WARN: media sync from S3 failed" >&2
  chown -R ubuntu:ubuntu "$PROJECT_DIR/media" || true
  find "$PROJECT_DIR/media" -type d -exec chmod 755 {} + 2>/dev/null || true
  find "$PROJECT_DIR/media" -type f -exec chmod 644 {} + 2>/dev/null || true
fi

echo "=== Restarting Nginx ==="
nginx -t
systemctl restart nginx

echo "=== Restarting Daphne via systemd ==="
systemctl daemon-reload
systemctl enable aniverse.service
systemctl restart aniverse.service

# 기동 대기 — Host 를 도메인으로 보내 DisallowedHost 방지
HEALTH_HOST="${DJANGO_HEALTH_HOST:-aniverse.my}"
for i in $(seq 1 30); do
  if systemctl is-active --quiet aniverse.service; then
    if curl -sf -H "Host: ${HEALTH_HOST}" "http://127.0.0.1:8000/health/" >/dev/null 2>&1 \
      || curl -sf "http://127.0.0.1:8000/health/" >/dev/null 2>&1; then
      echo "Daphne and Nginx started successfully."
      systemctl --no-pager --full status aniverse.service || true
      exit 0
    fi
  fi
  sleep 1
done

echo "Failed to start Daphne."
journalctl -u aniverse.service -n 80 --no-pager || true
[ -f "$PROJECT_DIR/daphne-access.log" ] && tail -n 50 "$PROJECT_DIR/daphne-access.log" || true
[ -f "$PROJECT_DIR/gunicorn-error.log" ] && cat "$PROJECT_DIR/gunicorn-error.log" || true
exit 1
