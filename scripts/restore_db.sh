#!/bin/bash
# Restore MariaDB/MySQL from data/aniverse_backup.sql using EC2 credentials.
# Sources (in order, later overrides earlier for missing keys only via merge):
#   1) /home/ubuntu/aniverse/.env
#   2) /etc/aniverse.env
#   3) Secrets Manager (aniverse/app-runtime or APP_SECRET_ARN)
# Run on an app instance (SSM):
#   sudo bash /home/ubuntu/aniverse/scripts/restore_db.sh
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/home/ubuntu/aniverse}"
BACKUP="${1:-$PROJECT_DIR/data/aniverse_backup.sql}"
SECRET_ID="${APP_SECRET_ARN:-${APP_SECRET_NAME:-aniverse/app-runtime}}"
AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-northeast-2}}"

if [ ! -f "$BACKUP" ]; then
  echo "Backup not found: $BACKUP" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y mariadb-client awscli

# Parse KEY='value' from env files + optional Secrets Manager JSON.
# Prefer complete DB_* set; do not stop at a partial .env (e.g. GEMINI-only).
eval "$(
  ENV_FILE_A="$PROJECT_DIR/.env" \
  ENV_FILE_B="/etc/aniverse.env" \
  SECRET_ID="$SECRET_ID" \
  AWS_REGION="$AWS_REGION" \
  PROJECT_DIR="$PROJECT_DIR" \
  python3 - <<'PY'
import json, os, subprocess, sys
from pathlib import Path

need = ["DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"]
vals = {}

def parse_env_text(text: str) -> None:
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        v = v.strip().strip("'").strip('"')
        if k in need and k not in vals and v != "":
            vals[k] = v

for path in (os.environ.get("ENV_FILE_A"), os.environ.get("ENV_FILE_B")):
    if not path:
        continue
    p = Path(path)
    if p.is_file():
        parse_env_text(p.read_text(encoding="utf-8", errors="replace"))

missing = [k for k in need if k not in vals]
if missing:
    secret_id = os.environ["SECRET_ID"]
    region = os.environ["AWS_REGION"]
    print(f"DB keys missing from env files ({missing}); fetching {secret_id}", file=sys.stderr)
    try:
        raw = subprocess.check_output(
            [
                "aws", "secretsmanager", "get-secret-value",
                "--secret-id", secret_id,
                "--region", region,
                "--query", "SecretString",
                "--output", "text",
            ],
            text=True,
        )
    except subprocess.CalledProcessError as e:
        raise SystemExit(
            f"Missing keys {missing} and Secrets Manager fetch failed for {secret_id}: {e}"
        ) from e
    data = json.loads(raw)
    for k in need:
        if k not in vals and data.get(k) not in (None, ""):
            vals[k] = str(data[k])

    # Refresh local env files so Daphne / future restores see DB_* again.
    order = [
        "DJANGO_SECRET_KEY", "DJANGO_DEBUG", "DJANGO_ALLOWED_HOSTS",
        "DJANGO_CSRF_TRUSTED_ORIGINS", "USE_HTTPS",
        "DB_NAME", "DB_USER", "DB_PASSWORD", "DB_HOST", "DB_PORT",
        "AWS_STORAGE_BUCKET_NAME", "AWS_S3_REGION_NAME",
        "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY",
        "GEMINI_API_KEY", "GEMINI_MODEL", "REDIS_URL",
    ]
    # Merge: secret payload base, then preserve extra keys already on disk (e.g. newer GEMINI).
    merged = {k: ("" if data.get(k) is None else str(data[k])) for k in order if k in data}
    for env_path in (Path(os.environ["PROJECT_DIR"]) / ".env", Path("/etc/aniverse.env")):
        if env_path.is_file():
            for line in env_path.read_text(encoding="utf-8", errors="replace").splitlines():
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                v = v.strip().strip("'").strip('"')
                if k not in merged and v != "":
                    merged[k] = v
    lines = []
    seen = set()
    for key in order:
        if key in merged:
            safe = merged[key].replace("'", "'\"'\"'")
            lines.append(f"{key}='{safe}'")
            seen.add(key)
    for key, val in merged.items():
        if key in seen:
            continue
        safe = val.replace("'", "'\"'\"'")
        lines.append(f"{key}='{safe}'")
    text = "\n".join(lines) + "\n"
    proj = Path(os.environ["PROJECT_DIR"]) / ".env"
    proj.write_text(text, encoding="utf-8")
    Path("/etc/aniverse.env").write_text(text, encoding="utf-8")
    print(f"Refreshed {proj} and /etc/aniverse.env from Secrets Manager", file=sys.stderr)

still_missing = [k for k in need if k not in vals]
if still_missing:
    raise SystemExit(f"Missing keys in env/secret: {still_missing}")

for k, v in vals.items():
    print(f"{k}={v!r}")
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
