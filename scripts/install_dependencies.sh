#!/bin/bash
set -e

# 1. 기존 가상환경 완전히 초기화 (권한 문제 방지)
sudo rm -rf /home/ec2-user/venv

# 2. 시스템에 설치된 파이썬3 찾기 (3.7이 아닌 최신 버전 확인)
PYTHON_EXE=$(which python3)

# 3. 가상환경 생성 및 소유권 즉시 ec2-user로 변경
$PYTHON_EXE -m venv /home/ec2-user/venv
sudo chown -R ec2-user:ec2-user /home/ec2-user/venv

# 4. 가상환경 활성화
source /home/ec2-user/venv/bin/activate

# 5. pip 업그레이드 및 의존성 설치
pip install --upgrade pip
pip install -r /home/ec2-user/aniverse/requirements.txt

# 6. 마이그레이션 및 정적 파일 수집
python manage.py migrate --noinput
python manage.py collectstatic --noinput
