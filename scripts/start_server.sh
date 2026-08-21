#!/bin/bash
cd /home/ec2-user/aniverse

# 가상환경 활성화
source /home/ec2-user/venv/bin/activate

# 기존에 돌고 있던 서버 프로세스 끄기 (포트 충돌 방지)
pkill -f gunicorn || true

# Gunicorn(또는 Daphne)을 백그라운드로 실행
nohup gunicorn --bind 0.0.0.0:8000 config.wsgi:application > /dev/null 2>&1 &
