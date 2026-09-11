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

if [ "${RUN_MIGRATE:-true}" = "true" ]; then
  echo "Running migrations..."
  python manage.py migrate --noinput
fi

if [ "${RUN_COLLECTSTATIC:-false}" = "true" ]; then
  echo "Collecting static files..."
  python manage.py collectstatic --noinput
fi

exec "$@"
