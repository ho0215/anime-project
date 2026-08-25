#!/usr/bin/env bash
# Idempotent repository bootstrap for the Aniverse Django app.
# Runs on Cursor's default Ubuntu base image after checkout (cwd = repo root).
set -euo pipefail

REPO_DIR="$(pwd)"
# config/settings.py hardcodes this AWS RDS endpoint. We point it at a local
# MariaDB instead of the production database, without touching application code.
RDS_HOST="aniverse-rds.cj2o4oeeykic.ap-northeast-2.rds.amazonaws.com"

# settings.py reads these via django-environ at import time (S3 is not used for
# local development, so placeholder values are enough to let Django start).
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-local-dev-unused}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-local-dev-unused}"

echo "== System packages (MariaDB 10.11 + mysqlclient build deps) =="
# MariaDB 10.11 matches the origin of the committed SQL dump and satisfies
# Django 6.x's MariaDB 10.5+ requirement (Ubuntu's MySQL 8.0 does not).
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  build-essential \
  pkg-config \
  python3-dev \
  python3-venv \
  default-libmysqlclient-dev \
  mariadb-server \
  mariadb-client

echo "== Python virtualenv & dependencies =="
if [ ! -x "$REPO_DIR/venv/bin/python" ]; then
  python3 -m venv "$REPO_DIR/venv"
fi
"$REPO_DIR/venv/bin/pip" install --upgrade pip
"$REPO_DIR/venv/bin/pip" install -r "$REPO_DIR/requirements.txt"

echo "== Point the hardcoded RDS host at local MariaDB =="
if ! grep -q "$RDS_HOST" /etc/hosts; then
  echo "127.0.0.1 $RDS_HOST" | sudo tee -a /etc/hosts >/dev/null
fi

echo "== Ensure MariaDB data directory is initialized =="
sudo mkdir -p /etc/mysql/conf.d
if [ ! -d /var/lib/mysql/mysql ]; then
  sudo mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

echo "== Start MariaDB (needed to seed data during install) =="
sudo service mariadb start || true
for _ in $(seq 1 30); do
  if sudo mariadb -e "SELECT 1" >/dev/null 2>&1; then break; fi
  sleep 1
done

echo "== Create local database and application user =="
sudo mariadb <<'SQL'
CREATE DATABASE IF NOT EXISTS aniverse CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin1234!';
CREATE USER IF NOT EXISTS 'admin'@'127.0.0.1' IDENTIFIED BY 'admin1234!';
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin1234!';
GRANT ALL PRIVILEGES ON aniverse.* TO 'admin'@'localhost';
GRANT ALL PRIVILEGES ON aniverse.* TO 'admin'@'127.0.0.1';
GRANT ALL PRIVILEGES ON aniverse.* TO 'admin'@'%';
FLUSH PRIVILEGES;
SQL

# Seed only when the schema is not already present, so re-running install does
# not wipe data created while developing. The dump itself is a full snapshot.
echo "== Seed database from mydb_backup.sql (first run only) =="
TABLE_COUNT="$(sudo mariadb -N -B aniverse -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='aniverse';" 2>/dev/null || echo 0)"
if [ "${TABLE_COUNT:-0}" -lt 20 ] && [ -f "$REPO_DIR/mydb_backup.sql" ]; then
  sudo mariadb aniverse < "$REPO_DIR/mydb_backup.sql"
else
  echo "Existing schema detected (${TABLE_COUNT} tables); skipping seed."
fi

echo "== Django migrations & static files =="
cd "$REPO_DIR"
"$REPO_DIR/venv/bin/python" manage.py migrate --noinput
"$REPO_DIR/venv/bin/python" manage.py collectstatic --noinput

# Leave the data directory in a clean state so environment-build snapshots
# capture a consistent MariaDB datadir. start.sh brings the service back up.
echo "== Stop MariaDB for a clean snapshot =="
sudo service mariadb stop || true

echo "== Install complete =="
