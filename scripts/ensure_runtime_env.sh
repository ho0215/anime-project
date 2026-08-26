#!/bin/bash
# Ensure /home/ubuntu/aniverse/.env has required runtime keys.
# Prefer /etc/aniverse.env, then Secrets Manager (aniverse/app-runtime).
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/home/ubuntu/aniverse}"
ENV_FILE="$PROJECT_DIR/.env"
ETC_ENV="/etc/aniverse.env"
SECRET_ID="${APP_SECRET_ARN:-${APP_SECRET_NAME:-aniverse/app-runtime}}"
AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-ap-northeast-2}}"

need_keys=("DB_HOST" "AWS_STORAGE_BUCKET_NAME")

env_has_key() {
  local file="$1" key="$2" line val
  [ -f "$file" ] || return 1
  line=$(grep -E "^${key}=" "$file" | head -1 || true)
  [ -n "$line" ] || return 1
  val="${line#*=}"
  val="${val#\'}"
  val="${val%\'}"
  val="${val#\"}"
  val="${val%\"}"
  [ -n "$val" ]
}

needs_restore=0
if [ ! -f "$ENV_FILE" ]; then
  needs_restore=1
else
  for k in "${need_keys[@]}"; do
    if ! env_has_key "$ENV_FILE" "$k"; then
      needs_restore=1
      break
    fi
  done
fi

if [ "$needs_restore" -eq 0 ]; then
  exit 0
fi

if [ -f "$ETC_ENV" ] && env_has_key "$ETC_ENV" "DB_HOST" && env_has_key "$ETC_ENV" "AWS_STORAGE_BUCKET_NAME"; then
  cp "$ETC_ENV" "$ENV_FILE"
  chown ubuntu:ubuntu "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  echo "Restored $ENV_FILE from $ETC_ENV"
  exit 0
fi

echo "Refreshing env from Secrets Manager ($SECRET_ID)"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ID" \
  --region "$AWS_REGION" \
  --query SecretString \
  --output text > "$TMP"

PROJECT_DIR="$PROJECT_DIR" python3 - "$TMP" <<'PY'
import json, os, sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
order = [
    "DJANGO_SECRET_KEY", "DJANGO_DEBUG", "DJANGO_ALLOWED_HOSTS",
    "DJANGO_CSRF_TRUSTED_ORIGINS", "USE_HTTPS",
    "DB_NAME", "DB_USER", "DB_PASSWORD", "DB_HOST", "DB_PORT",
    "AWS_STORAGE_BUCKET_NAME", "AWS_S3_REGION_NAME",
    "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY",
    "GEMINI_API_KEY", "GEMINI_MODEL", "REDIS_URL",
]
merged = {}
for path in (Path("/etc/aniverse.env"), Path(os.environ["PROJECT_DIR"]) / ".env"):
    if not path.is_file():
        continue
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        merged[k] = v.strip().strip("'").strip('"')
for k, v in data.items():
    if v is not None and str(v) != "":
        merged[k] = str(v)

lines = []
seen = set()
for key in order:
    if key not in merged:
        continue
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
print("bucket=", merged.get("AWS_STORAGE_BUCKET_NAME", ""))
print("db_host=", merged.get("DB_HOST", ""))
PY

chown ubuntu:ubuntu "$ENV_FILE"
chmod 600 "$ENV_FILE" "$ETC_ENV"
echo "Wrote $ENV_FILE and $ETC_ENV from Secrets Manager"
