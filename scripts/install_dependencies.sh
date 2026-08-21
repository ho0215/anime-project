#!/bin/bash
set -e

echo "=== Installing build dependencies ==="
sudo yum install -y mariadb-devel gcc pkgconfig python3-devel

echo "=== Recreating venv using default python3 (3.7) ==="
sudo rm -rf /home/ec2-user/venv
python3 -m venv /home/ec2-user/venv
sudo chown -R ec2-user:ec2-user /home/ec2-user/venv

echo "=== Installing requirements ==="
source /home/ec2-user/venv/bin/activate
pip install --upgrade pip
pip install -r /home/ec2-user/aniverse/requirements.txt

echo "=== Running migrations & collectstatic ==="
python /home/ec2-user/aniverse/manage.py migrate --noinput
python /home/ec2-user/aniverse/manage.py collectstatic --noinput
