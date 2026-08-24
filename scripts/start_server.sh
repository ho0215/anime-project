#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/aniverse"
cd $PROJECT_DIR

echo "=== Restarting Nginx ==="
nginx -t
systemctl restart nginx

echo "=== Stopping existing gunicorn processes ==="
pkill -f gunicorn || true
sleep 2

echo "=== Starting Gunicorn Server ==="
# Nginx 프록시를 받으므로 127.0.0.1 로컬 바인딩
nohup $PROJECT_DIR/venv/bin/gunicorn \
  --bind 127.0.0.1:8000 \
  --workers 2 \
  --worker-class sync \
  config.wsgi:application > $PROJECT_DIR/server.log 2>&1 &

sleep 3

if pgrep -f gunicorn > /dev/null; then
    echo "Gunicorn and Nginx started successfully."
    exit 0
else
    echo "Failed to start Gunicorn."
    cat $PROJECT_DIR/server.log
    exit 1
fi
