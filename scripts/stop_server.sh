#!/bin/bash
set -euo pipefail

echo "=== Stopping Gunicorn (aniverse.service) ==="
systemctl stop aniverse.service || true
pkill -f gunicorn || true
exit 0
