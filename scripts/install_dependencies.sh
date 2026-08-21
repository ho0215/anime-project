#!/bin/bash
set -e

# 1. 파이썬 3.8 확실하게 활성화 및 설치
sudo amazon-linux-extras enable python3.8 || true
sudo yum clean metadata
sudo yum install -y python38 python38-devel mariadb-devel gcc pkgconfig

# 2. 가상환경 생성 시 명시적으로 python3.8 지정
sudo rm -rf /home/ec2-user/venv
python3.8 -m venv /home/ec2-user/venv
sudo chown -R ec2-user:ec2-user /home/ec2-user/venv

# 3. 가상환경 활성화 및 패키지 설치
source /home/ec2-user/venv/bin/activate
pip install --upgrade pip
pip install -r /home/ec2-user/aniverse/requirements.txt

# 4. 마이그레이션 및 정적 파일 수집
python /home/ec2-user/aniverse/manage.py migrate --noinput
python /home/ec2-user/aniverse/manage.py collectstatic --noinput
