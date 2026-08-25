#!/bin/bash
set -euo pipefail

PROJECT_DIR="/home/ubuntu/aniverse"

echo "=== Restore .env if CodeDeploy wiped it ==="
if [ ! -f "$PROJECT_DIR/.env" ] && [ -f /etc/aniverse.env ]; then
  cp /etc/aniverse.env "$PROJECT_DIR/.env"
  chown ubuntu:ubuntu "$PROJECT_DIR/.env"
  chmod 600 "$PROJECT_DIR/.env"
fi

echo "=== Restarting Nginx ==="
nginx -t
systemctl restart nginx

echo "=== Restarting Gunicorn via systemd ==="
systemctl daemon-reload
systemctl enable aniverse.service
systemctl restart aniverse.service

# 기동 대기
for i in $(seq 1 30); do
  if systemctl is-active --quiet aniverse.service; then
    if curl -sf "http://127.0.0.1:8000/health/" >/dev/null 2>&1; then
      echo "Gunicorn and Nginx started successfully."
      systemctl --no-pager --full status aniverse.service || true
      exit 0
    fi
  fi
  sleep 1
done

echo "Failed to start Gunicorn."
journalctl -u aniverse.service -n 80 --no-pager || true
[ -f "$PROJECT_DIR/gunicorn-error.log" ] && cat "$PROJECT_DIR/gunicorn-error.log"
exit 1
