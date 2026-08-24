#!/bin/bash
set -e

echo "=== Updating system and installing dependencies ==="
apt-get update -y
apt-get install -y default-libmysqlclient-dev build-essential pkg-config python3-dev python3-venv

echo "=== Setting up virtual environment ==="
rm -rf /home/ubuntu/venv
python3 -m venv /home/ubuntu/venv
chown -R ubuntu:ubuntu /home/ubuntu/venv

echo "=== Installing python requirements ==="
source /home/ubuntu/venv/bin/activate
pip install --upgrade pip
pip install -r /home/ubuntu/aniverse/requirements.txt

echo "=== Running Django migrations & collectstatic ==="
python /home/ubuntu/aniverse/manage.py migrate --noinput
python /home/ubuntu/aniverse/manage.py collectstatic --noinput
