#!/usr/bin/env sh
# Runs both test suites. Exits non-zero on any failure so CI / pre-deploy
# gates can stop the line.
#
#   ./scripts/test.sh            # backend + frontend
#   SKIP_BACKEND=1 ./scripts/test.sh
#   SKIP_FRONTEND=1 ./scripts/test.sh
set -eu

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

log() { printf '\n=== %s ===\n' "$1"; }

if [ "${SKIP_BACKEND:-0}" != "1" ]; then
    log "Backend tests (pytest)"
    if [ ! -x "$REPO_DIR/backend/.venv/bin/python" ]; then
        echo "ERROR: backend/.venv not found - create it and run 'pip install -r backend/requirements.txt pytest pytest-asyncio'" >&2
        exit 1
    fi
    (cd "$REPO_DIR/backend" && .venv/bin/python -m pytest -q) || FAILED=1
else
    log "Skipping backend tests (SKIP_BACKEND=1)"
fi

if [ "${SKIP_FRONTEND:-0}" != "1" ]; then
    log "Frontend tests (vitest via ng test)"
    if [ ! -d "$REPO_DIR/frontend/node_modules" ]; then
        echo "ERROR: frontend/node_modules not found - run 'npm ci' in frontend/" >&2
        exit 1
    fi
    (cd "$REPO_DIR/frontend" && npm test -- --watch=false) || FAILED=1
else
    log "Skipping frontend tests (SKIP_FRONTEND=1)"
fi

if [ "$FAILED" != "0" ]; then
    echo "" >&2
    echo "TESTS FAILED - fix before deploying." >&2
    exit 1
fi

log "All tests passed"
