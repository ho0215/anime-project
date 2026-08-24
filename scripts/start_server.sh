#!/bin/bash
set -e

cd /home/ubuntu/aniverse

# 기존 구동 중이던 gunicorn 프로세스 종료
pkill -f gunicorn || true

# 가상환경 안의 gunicorn 절대 경로로 백그라운드 실행
nohup /home/ubuntu/venv/bin/gunicorn --bind 0.0.0.0:8000 config.wsgi:application > /home/ubuntu/aniverse/server_error.log 2>&1 &

echo "Gunicorn server started successfully on Ubuntu."
