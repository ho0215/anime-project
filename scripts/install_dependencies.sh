#!/bin/bash
set -euo pipefail

PROJECT_DIR="/home/ubuntu/aniverse"
cd "$PROJECT_DIR"

echo "=== Preserve runtime env files (written by EC2 user_data) ==="
if [ ! -f "$PROJECT_DIR/.env" ] && [ -f /etc/aniverse.env ]; then
  cp /etc/aniverse.env "$PROJECT_DIR/.env"
  chown ubuntu:ubuntu "$PROJECT_DIR/.env"
  chmod 600 "$PROJECT_DIR/.env"
fi

echo "=== Updating system and installing OS dependencies ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  default-libmysqlclient-dev build-essential pkg-config \
  python3-dev python3-venv python3-pip nginx nfs-common awscli

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

    location /health/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
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

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/aniverse /etc/nginx/sites-enabled/

echo "=== Ensure Gunicorn systemd unit exists ==="
if [ ! -f /etc/systemd/system/aniverse.service ]; then
  cat > /etc/systemd/system/aniverse.service <<'UNIT'
[Unit]
Description=Aniverse Django (Gunicorn)
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/aniverse
EnvironmentFile=-/home/ubuntu/aniverse/.env
EnvironmentFile=-/etc/aniverse.env
ExecStart=/home/ubuntu/aniverse/venv/bin/gunicorn \
  --bind 127.0.0.1:8000 \
  --workers 2 \
  --worker-class sync \
  --access-logfile /home/ubuntu/aniverse/gunicorn-access.log \
  --error-logfile /home/ubuntu/aniverse/gunicorn-error.log \
  config.wsgi:application
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT
fi
systemctl daemon-reload
systemctl enable aniverse.service

chown -R ubuntu:ubuntu "$PROJECT_DIR"

echo "=== Recreating clean virtual environment ==="
rm -rf "$PROJECT_DIR/venv"
python3 -m venv "$PROJECT_DIR/venv"
chown -R ubuntu:ubuntu "$PROJECT_DIR/venv"

echo "=== Installing python requirements ==="
"$PROJECT_DIR/venv/bin/pip" install --upgrade pip
"$PROJECT_DIR/venv/bin/pip" install -r "$PROJECT_DIR/requirements.txt"

echo "=== Running Django migrations & collectstatic ==="
# .env 가 있으면 RDS/S3 설정이 적용된다.
set -a
# shellcheck disable=SC1091
[ -f "$PROJECT_DIR/.env" ] && . "$PROJECT_DIR/.env"
set +a

"$PROJECT_DIR/venv/bin/python" "$PROJECT_DIR/manage.py" migrate --noinput \
  || "$PROJECT_DIR/venv/bin/python" "$PROJECT_DIR/manage.py" migrate --fake-initial
"$PROJECT_DIR/venv/bin/python" "$PROJECT_DIR/manage.py" collectstatic --noinput

echo "=== Dependency installation completed successfully ==="
