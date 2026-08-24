#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/aniverse"
cd $PROJECT_DIR

echo "=== Updating system and installing OS dependencies ==="
apt-get update -y
apt-get install -y default-libmysqlclient-dev build-essential pkg-config python3-dev python3-venv python3-pip

echo "=== Recreating clean virtual environment ==="
# CodeBuild에서 넘어온 깨진 venv 제거 후 EC2 환경에 맞게 재생성
rm -rf $PROJECT_DIR/venv
python3 -m venv $PROJECT_DIR/venv
chown -R ubuntu:ubuntu $PROJECT_DIR/venv

echo "=== Installing python requirements ==="
$PROJECT_DIR/venv/bin/pip install --upgrade pip
$PROJECT_DIR/venv/bin/pip install -r $PROJECT_DIR/requirements.txt

echo "=== Running Django migrations & collectstatic ==="
$PROJECT_DIR/venv/bin/python $PROJECT_DIR/manage.py migrate --noinput || $PROJECT_DIR/venv/bin/python $PROJECT_DIR/manage.py migrate --fake-initial
$PROJECT_DIR/venv/bin/python $PROJECT_DIR/manage.py collectstatic --noinput

echo "=== Dependency installation completed successfully ==="
