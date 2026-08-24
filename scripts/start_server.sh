#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/aniverse"
cd $PROJECT_DIR

echo "=== Stopping existing gunicorn processes ==="
pkill -f gunicorn || true

# 프로세스가 완전히 종료될 때까지 잠시 대기
sleep 2

echo "=== Starting Gunicorn Server ==="
# 1. venv 경로를 프로젝트 하위(/home/ubuntu/aniverse/venv)로 수정
# 2. 타겟그룹이 8000번을 바라보고 있다면 8000, 80번을 직접 받는다면 80으로 지정 (80 바인딩 시 root 권한 필요)
nohup $PROJECT_DIR/venv/bin/gunicorn \
  --bind 0.0.0.0:8000 \
  --workers 2 \
  --worker-class sync \
  config.wsgi:application > $PROJECT_DIR/server.log 2>&1 &

# 백그라운드 프로세스가 제대로 떴는지 2초 후 검증
sleep 2
if pgrep -f gunicorn > /dev/null; then
    echo "Gunicorn server started successfully."
    exit 0
else
    echo "Failed to start Gunicorn."
    cat $PROJECT_DIR/server.log
    exit 1
fi
