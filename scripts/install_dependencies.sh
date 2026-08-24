#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/aniverse"
cd $PROJECT_DIR

echo "=== Updating system and installing OS dependencies ==="
apt-get update -y
apt-get install -y default-libmysqlclient-dev build-essential pkg-config python3-dev python3-venv python3-pip

echo "=== Setting up virtual environment ==="
# venv 디렉터리가 없거나 손상되었으면 생성
if [ ! -f "$PROJECT_DIR/venv/bin/pip" ]; then
    python3 -m venv $PROJECT_DIR/venv
fi

# 권한 부여
chown -R ubuntu:ubuntu $PROJECT_DIR/venv

echo "=== Installing python requirements ==="
# 가상환경 내부의 pip 바이너리를 직접 호출
$PROJECT_DIR/venv/bin/pip install --upgrade pip
$PROJECT_DIR/venv/bin/pip install -r $PROJECT_DIR/requirements.txt

echo "=== Running Django migrations & collectstatic ==="
# 가상환경 내부의 python 바이너리를 직접 호출
$PROJECT_DIR/venv/bin/python $PROJECT_DIR/manage.py migrate --noinput || $PROJECT_DIR/venv/bin/python $PROJECT_DIR/manage.py migrate --fake-initial
$PROJECT_DIR/venv/bin/python $PROJECT_DIR/manage.py collectstatic --noinput

echo "=== Dependency installation completed successfully ==="
