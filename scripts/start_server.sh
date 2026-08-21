#!/bin/bash
set -e

# 프로젝트 폴더로 이동
cd /home/ec2-user/aniverse

# 가상환경 활성화
source /home/ec2-user/venv/bin/activate

# 기존에 돌고 있던 Gunicorn 프로세스 종료 (포트 충돌 방지)
pkill -f gunicorn || true

# Gunicorn을 백그라운드로 실행 (에러는 server_error.log에 기록)
nohup gunicorn --bind 0.0.0.0:8000 config.wsgi:application > /home/ec2-user/aniverse/server_error.log 2>&1 &

echo "Django server started successfully in background."
