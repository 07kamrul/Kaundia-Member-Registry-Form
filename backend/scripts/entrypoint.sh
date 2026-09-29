#!/bin/sh
# Container entrypoint: deploy-time setup, then exec the CMD (uvicorn).
#
# 1. Pins STORAGE_BASE_DIR to an absolute path inside the persistent volume.
#    A relative value (e.g. copied from .env.example into Dokploy's env
#    settings) resolves under /app, which is NOT a volume - uploads written
#    there are lost on every redeploy.
# 2. Ensures the upload root exists and is writable.
# 3. Runs migrations (scripts/migrate.sh owns the DB-ready retry loop - do not
#    run alembic anywhere else) and seeds the admin account.
set -eu

cd "$(dirname "$0")/.."

log() { echo "[entrypoint] $*"; }

DEFAULT_UPLOAD_DIR=/app/uploads

case "${STORAGE_BASE_DIR:-}" in
    /*) ;;
    "")
        export STORAGE_BASE_DIR="$DEFAULT_UPLOAD_DIR"
        ;;
    *)
        log "WARNING: STORAGE_BASE_DIR='${STORAGE_BASE_DIR}' is relative and would not persist;" >&2
        log "WARNING: overriding to ${DEFAULT_UPLOAD_DIR}. Fix the value in your deploy env settings." >&2
        export STORAGE_BASE_DIR="$DEFAULT_UPLOAD_DIR"
        ;;
esac

log "Ensuring upload directory ${STORAGE_BASE_DIR} exists"
mkdir -p "$STORAGE_BASE_DIR"
chmod 755 "$STORAGE_BASE_DIR"

if ! grep -qs " ${STORAGE_BASE_DIR} " /proc/mounts; then
    log "WARNING: ${STORAGE_BASE_DIR} is not a mounted volume - uploads will be lost on redeploy." >&2
    log "WARNING: mount persistent storage at ${STORAGE_BASE_DIR} (Dokploy: Advanced -> Volumes)." >&2
fi

sh scripts/migrate.sh
python -m app.seed

log "Setup complete, starting: $*"
exec "$@"
