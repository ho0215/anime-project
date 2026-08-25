#!/usr/bin/env bash
# Per-boot reconciliation: make sure the hostname remap is present and the local
# MariaDB service is up and ready before the app terminal starts.
set -euo pipefail

RDS_HOST="aniverse-rds.cj2o4oeeykic.ap-northeast-2.rds.amazonaws.com"

# /etc/hosts can be reset between boots, so re-apply the remap idempotently.
if ! grep -q "$RDS_HOST" /etc/hosts; then
  echo "127.0.0.1 $RDS_HOST" | sudo tee -a /etc/hosts >/dev/null
fi

sudo mkdir -p /etc/mysql/conf.d

if ! sudo mariadb -e "SELECT 1" >/dev/null 2>&1; then
  echo "Starting MariaDB..."
  sudo service mariadb start || true
fi

for _ in $(seq 1 30); do
  if sudo mariadb -e "SELECT 1" >/dev/null 2>&1; then
    echo "MariaDB is ready."
    exit 0
  fi
  sleep 1
done

echo "MariaDB did not become ready in time." >&2
exit 1
