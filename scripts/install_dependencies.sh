#!/bin/bash
# 에러가 나면 즉시 스크립트를 중단
set -e

cd /home/ec2-user/aniverse

# 파이썬 가상환경 활성화
source /home/ec2-user/venv/bin/activate

# pip 및 기본 툴 업그레이드 (버전 충돌 방지)
pip install --upgrade pip setuptools wheel

# 필요한 패키지 설치
pip install -r requirements.txt

# DB 마이그레이션 적용 (RDS MariaDB)
python manage.py migrate --noinput

# 정적 파일 모으기
python manage.py collectstatic --noinput
