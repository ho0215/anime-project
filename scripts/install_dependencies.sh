#!/bin/bash
cd /home/ec2-user/aniverse

# 파이썬 가상환경 활성화 (ec2-user 경로에 맞춤)
source /home/ec2-user/venv/bin/activate

# 필요한 패키지 업데이트
pip install -r requirements.txt

# DB 마이그레이션 적용 (RDS MariaDB)
python manage.py migrate --noinput

# 정적 파일 모으기 (EFS 마운트 경로로 자동 이동)
python manage.py collectstatic --noinput
