#!/usr/bin/env bash
# CI guard: the three external land-data domains must only appear in the
# ingest tooling and docs — never in runtime code or config.
set -euo pipefail
cd "$(dirname "$0")/.."

VIOLATIONS=$(grep -rniE 'settlement\.gov\.bd|rajuk\.gov\.bd|arcgis\.com' \
  --include='*.py' --include='*.ts' --include='*.html' --include='*.dart' \
  --include='*.json' --include='*.yml' --include='*.yaml' --include='*.sh' \
  backend/app backend/src 2>/dev/null \
  frontend/src frontend/public \
  mobile/lib 2>/dev/null \
  || true)

if [ -n "$VIOLATIONS" ]; then
  echo "ERROR: external land-data domains referenced outside the ingest tooling:" >&2
  echo "$VIOLATIONS" >&2
  exit 1
fi
echo "OK: no external land-data domain references in runtime code."
