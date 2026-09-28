#!/bin/sh
# Run Alembic migrations against the database configured via environment
# variables (alembic/env.py reads DATABASE_URL through app settings).
# Retries while the database is still starting up; fails loudly otherwise.
set -eu

cd "$(dirname "$0")/.."

MAX_ATTEMPTS="${MIGRATION_MAX_ATTEMPTS:-30}"
SLEEP_SECONDS="${MIGRATION_SLEEP_SECONDS:-2}"

log() { echo "[migrate] $*"; }

log "Starting migration (project root: $(pwd))"
attempt=1
while :; do
    log "Running Alembic upgrade head (attempt ${attempt}/${MAX_ATTEMPTS})"
    if alembic upgrade head; then
        log "Migration completed successfully"
        exit 0
    fi
    if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
        log "Migration failed after ${attempt} attempts — giving up" >&2
        exit 1
    fi
    log "Migration failed (database may not be ready); retrying in ${SLEEP_SECONDS}s" >&2
    attempt=$((attempt + 1))
    sleep "$SLEEP_SECONDS"
done
