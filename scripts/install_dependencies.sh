#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/aniverse"
cd $PROJECT_DIR

echo "=== Updating system and installing OS dependencies ==="
apt-get update -y
apt-get install -y default-libmysqlclient-dev build-essential pkg-config python3-dev python3-venv

echo "=== Setting up virtual environment ==="
# 가상환경이 없으면 새로 생성, 있으면 재사용하여 배포 속도 최적화
if [ ! -d "$PROJECT_DIR/venv" ]; then
    python3 -m venv $PROJECT_DIR/venv
fi

# 권한 부여
chown -R ubuntu:ubuntu $PROJECT_DIR/venv

echo "=== Installing python requirements ==="
source $PROJECT_DIR/venv/bin/activate
pip install --upgrade pip
pip install -r $PROJECT_DIR/requirements.txt

echo "=== Running Django migrations & collectstatic ==="
# 0009 충돌 등 기존 테이블 컬럼 이슈 방지를 위해 fake-initial 병행 처리
python $PROJECT_DIR/manage.py migrate --noinput || python $PROJECT_DIR/manage.py migrate --fake-initial
python $PROJECT_DIR/manage.py collectstatic --noinput

echo "=== Dependency installation completed successfully ==="
