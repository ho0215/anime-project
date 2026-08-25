#!/bin/bash
# Restore MariaDB/MySQL from data/aniverse_backup.sql using EC2 .env credentials.
# Run on an app instance (SSM):
#   sudo bash /home/ubuntu/aniverse/scripts/restore_db.sh
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/home/ubuntu/aniverse}"
BACKUP="${1:-$PROJECT_DIR/data/aniverse_backup.sql}"
ENV_FILE="$PROJECT_DIR/.env"

if [ ! -f "$BACKUP" ]; then
  echo "Backup not found: $BACKUP" >&2
  exit 1
fi

if [ ! -f "$ENV_FILE" ] && [ -f /etc/aniverse.env ]; then
  ENV_FILE=/etc/aniverse.env
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "No .env found at $PROJECT_DIR/.env or /etc/aniverse.env" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y mariadb-client

# Parse KEY='value' / KEY=value without bash-sourcing (SECRET_KEY may contain ')')
eval "$(python3 - <<PY
from pathlib import Path
env = Path("$ENV_FILE").read_text(encoding="utf-8", errors="replace").splitlines()
need = ["DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"]
vals = {}
for line in env:
    line = line.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    k, v = line.split("=", 1)
    v = v.strip().strip("'").strip('"')
    if k in need:
        vals[k] = v
missing = [k for k in need if k not in vals]
if missing:
    raise SystemExit(f"Missing keys in env: {missing}")
for k, v in vals.items():
    # shell-escape via repr
    print(f'{k}={v!r}')
PY
)"

echo "Restoring $BACKUP → ${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
echo "WARNING: this replaces tables in the target database."

mysql \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --user="$DB_USER" \
  --password="$DB_PASSWORD" \
  --protocol=TCP \
  "$DB_NAME" < "$BACKUP"

echo "Restore completed successfully."
mysql \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --user="$DB_USER" \
  --password="$DB_PASSWORD" \
  --protocol=TCP \
  -N -B \
  "$DB_NAME" \
  -e "SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema=DATABASE() ORDER BY table_name;"
