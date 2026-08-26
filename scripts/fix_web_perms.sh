#!/bin/bash
# Allow nginx (www-data) to read Django staticfiles + media under /home/ubuntu.
# Without +x on /home/ubuntu, alias /static/ returns 403 even if files exist.
set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/home/ubuntu/aniverse}"

# Parent path must be traversable by www-data
chmod 755 /home/ubuntu 2>/dev/null || true
chmod 755 "$PROJECT_DIR" 2>/dev/null || true

for dir in staticfiles media static; do
  target="$PROJECT_DIR/$dir"
  [ -d "$target" ] || continue
  find "$target" -type d -exec chmod 755 {} + 2>/dev/null || true
  find "$target" -type f -exec chmod 644 {} + 2>/dev/null || true
done

# Keep secrets private
chmod 600 "$PROJECT_DIR/.env" 2>/dev/null || true
chmod 600 /etc/aniverse.env 2>/dev/null || true

echo "Web perms fixed for $PROJECT_DIR/{staticfiles,media,static}"
