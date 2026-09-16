#!/bin/bash
set -euo pipefail

# Wait for MySQL/MariaDB when DB_HOST is set (compose service name, etc.)
if [ -n "${DB_HOST:-}" ] && [ "${DB_HOST}" != "127.0.0.1" ]; then
  echo "Waiting for database at ${DB_HOST}:${DB_PORT:-3306}..."
  for i in $(seq 1 60); do
    if python - <<'PY'
import os, socket, sys
host = os.environ.get("DB_HOST", "db")
port = int(os.environ.get("DB_PORT", "3306"))
try:
    with socket.create_connection((host, port), timeout=2):
        sys.exit(0)
except OSError:
    sys.exit(1)
PY
    then
      echo "Database is reachable."
      break
    fi
    sleep 2
    if [ "$i" -eq 60 ]; then
      echo "ERROR: database not reachable" >&2
      exit 1
    fi
  done
fi

# Optional seed (Helm db-restore Job 이 EKS 주 경로). 빈 DB 일 때만.
if [ "${RUN_DB_RESTORE:-false}" = "true" ]; then
  DUMP="${DB_RESTORE_SQL:-/app/data/aniverse_backup.sql}"
  if [ -f "${DUMP}" ] && command -v mysql >/dev/null 2>&1; then
    RESTORE_USER="${DB_ROOT_USER:-root}"
    RESTORE_PWD="${DB_ROOT_PASSWORD:-${DB_PASSWORD:-}}"
    export MYSQL_PWD="${RESTORE_PWD}"
    COUNT="$(mysql -N -B -h"${DB_HOST}" -u"${RESTORE_USER}" -e \
      "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';" 2>/dev/null || echo 0)"
    MIN="${DB_RESTORE_MIN_TABLES:-20}"
    if [ "${COUNT}" -lt "${MIN}" ]; then
      echo "Restoring ${DUMP} (tables=${COUNT})..."
      mysql -h"${DB_HOST}" -u"${RESTORE_USER}" "${DB_NAME}" < "${DUMP}"
    else
      echo "Skip entrypoint restore (tables=${COUNT})"
    fi
    unset MYSQL_PWD
  else
    echo "RUN_DB_RESTORE set but mysql client or dump missing — skip"
  fi
fi

if [ "${RUN_MIGRATE:-true}" = "true" ]; then
  echo "Running migrations..."
  python manage.py migrate --noinput
fi

if [ "${RUN_COLLECTSTATIC:-false}" = "true" ]; then
  echo "Collecting static files..."
  python manage.py collectstatic --noinput
fi

exec "$@"
