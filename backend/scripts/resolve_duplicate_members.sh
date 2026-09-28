#!/bin/sh
# Auto-resolve non-rejected members that collide on nid/mobile/email so that
# migration d4e6f8a0b2c4's partial unique indexes can be created. Run before
# `alembic upgrade head` in scripts/migrate.sh.
set -eu

cd "$(dirname "$0")/.."

echo "[resolve-duplicates] Resolving duplicate member identifiers"
python -m scripts.resolve_duplicate_members --apply
