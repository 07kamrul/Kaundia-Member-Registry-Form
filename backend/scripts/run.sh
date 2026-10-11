#!/bin/sh
# Common command runner. Every operational command for this backend (migrate,
# seed, one-off data fixes, ...) lives here so Docker and humans run the exact
# same thing. Add new commands as a function + a case entry below.
#
# Usage: sh scripts/run.sh <command> [args...]
#   setup               migrate + seed (what the container runs on start)
#   migrate             resolve duplicates, then `alembic upgrade head` (with DB-ready retries)
#   makemigration MSG   alembic revision --autogenerate -m MSG
#   seed                create the admin account
#   resolve-duplicates  auto-resolve duplicate member nid/mobile/email
#   migrate-member-ids  [--apply] rewrite member IDs
#   repair-document-paths [args]
#   serve               start uvicorn on $PORT (default 9090)
set -eu

cd "$(dirname "$0")/.."

log() { echo "[run] $*"; }

cmd_resolve_duplicates() {
    log "Resolving duplicate member identifiers"
    python -m scripts.resolve_duplicate_members --apply
}

cmd_migrate() {
    max_attempts="${MIGRATION_MAX_ATTEMPTS:-30}"
    sleep_seconds="${MIGRATION_SLEEP_SECONDS:-2}"

    cmd_resolve_duplicates || { log "Duplicate resolution failed - aborting" >&2; exit 1; }

    attempt=1
    while :; do
        log "Running Alembic upgrade head (attempt ${attempt}/${max_attempts})"
        if alembic upgrade head; then
            log "Migration completed successfully"
            return 0
        fi
        if [ "$attempt" -ge "$max_attempts" ]; then
            log "Migration failed after ${attempt} attempts - giving up" >&2
            exit 1
        fi
        log "Migration failed (database may not be ready); retrying in ${sleep_seconds}s" >&2
        attempt=$((attempt + 1))
        sleep "$sleep_seconds"
    done
}

cmd_makemigration() {
    [ $# -ge 1 ] || { log "usage: run.sh makemigration \"message\"" >&2; exit 2; }
    alembic revision --autogenerate -m "$1"
}

cmd_seed() { python -m app.seed; }

cmd_setup() { cmd_migrate; cmd_seed; }

cmd_serve() {
    exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-9090}"
}

[ $# -ge 1 ] || { sed -n '2,/^set -eu/p' "$0" | sed '$d' >&2; exit 2; }
command="$1"; shift

case "$command" in
    setup)                  cmd_setup ;;
    migrate)                cmd_migrate ;;
    makemigration)          cmd_makemigration "$@" ;;
    seed)                   cmd_seed ;;
    resolve-duplicates)     cmd_resolve_duplicates ;;
    migrate-member-ids)     python scripts/migrate_member_ids.py "$@" ;;
    repair-document-paths)  python scripts/repair_document_paths.py "$@" ;;
    serve)                  cmd_serve ;;
    *) log "unknown command: $command" >&2; exit 2 ;;
esac
