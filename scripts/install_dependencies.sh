#!/bin/bash
set -e

PROJECT_DIR="/home/ubuntu/aniverse"
cd $PROJECT_DIR

echo "=== Updating system and installing OS dependencies ==="
apt-get update -y
apt-get install -y default-libmysqlclient-dev build-essential pkg-config python3-dev python3-venv python3-pip nginx

echo "=== Configuring Nginx ==="
cat << 'EOF' > /etc/nginx/sites-available/aniverse
server {
    listen 80;
    server_name _;

    client_max_body_size 128M;

    location /static/ {
        alias /home/ubuntu/aniverse/staticfiles/;
    }

    location /media/ {
        alias /home/ubuntu/aniverse/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Nginx 심볼릭 링크 연결 및 기본 설정 제거
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/aniverse /etc/nginx/sites-enabled/

# staticfiles 폴더 권한 부여
chown -R ubuntu:ubuntu $PROJECT_DIR

echo "=== Recreating clean virtual environment ==="
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
