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

echo "=== Installing OS dependencies (idempotent; also done in user_data) ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  default-libmysqlclient-dev build-essential pkg-config \
  python3-dev python3-venv python3-pip nginx nfs-common awscli curl

# mysqlclient 빌드에 필수 — 과거 EC2에서 mysql_config 없어 pip 실패하던 지점
if ! command -v mysql_config >/dev/null 2>&1; then
  echo "ERROR: mysql_config not found after apt install. default-libmysqlclient-dev missing?" >&2
  dpkg -l 'libmysql*' 'default-libmysql*' || true
  exit 1
fi
echo "mysql_config OK: $(mysql_config --version)"

echo "=== Configuring Nginx (proxy to Gunicorn) ==="
cat << 'EOF' > /etc/nginx/sites-available/aniverse
server {
    listen 80 default_server;
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
ln -sf /etc/nginx/sites-available/aniverse /etc/nginx/sites-enabled/aniverse

echo "=== Ensure Gunicorn systemd unit exists ==="
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
systemctl daemon-reload

chown -R ubuntu:ubuntu "$PROJECT_DIR"

echo "=== Recreating clean virtual environment ==="
rm -rf "$PROJECT_DIR/venv"
python3 -m venv "$PROJECT_DIR/venv"
chown -R ubuntu:ubuntu "$PROJECT_DIR/venv"

echo "=== Installing python requirements (mysqlclient needs build deps above) ==="
"$PROJECT_DIR/venv/bin/pip" install --upgrade pip wheel setuptools
# 실패 원인을 로그에 남기기 위해 mysqlclient 를 먼저 설치 시도
"$PROJECT_DIR/venv/bin/pip" install "mysqlclient>=2.2.0"
"$PROJECT_DIR/venv/bin/pip" install -r "$PROJECT_DIR/requirements.txt"

# 런타임 import 스모크 테스트
# pip 패키지명은 mysqlclient 이지만 import 모듈명은 MySQLdb 이다.
"$PROJECT_DIR/venv/bin/python" - <<'PY'
import django
import MySQLdb  # from mysqlclient
import gunicorn
print("python deps import OK", django.get_version(), MySQLdb.version_info)
PY

echo "=== Running Django migrations & collectstatic ==="
set -a
# shellcheck disable=SC1091
[ -f "$PROJECT_DIR/.env" ] && . "$PROJECT_DIR/.env"
set +a

"$PROJECT_DIR/venv/bin/python" "$PROJECT_DIR/manage.py" migrate --noinput \
  || "$PROJECT_DIR/venv/bin/python" "$PROJECT_DIR/manage.py" migrate --fake-initial
"$PROJECT_DIR/venv/bin/python" "$PROJECT_DIR/manage.py" collectstatic --noinput

# venv 가 준비된 뒤에만 enable (user_data 단계에서는 enable 하지 않음)
systemctl enable aniverse.service

echo "=== Dependency installation completed successfully ==="
