#!/usr/bin/env sh
# Kaundia production deploy from pre-published images.
#
# Run this ON THE PRODUCTION HOST, from the directory containing
# docker-compose.yml:
#
#   ./scripts/server-deploy.sh
#
# Assumes the CI pipeline published fresh images on push (see .env:
# BACKEND_IMAGE / FRONTEND_IMAGE, wired up via docker-compose.prod.yml).
# For one-off image tags override them on the command line:
#
#   BACKEND_IMAGE=docker.io/me/kaundia-backend:v42 ./scripts/server-deploy.sh
#
# What it does:
#   1. Rescues uploads that exist only inside the running backend container
#      into the named volume (same safeguard as deploy.sh).
#   2. Pulls the latest images and recreates the stack.
#   3. Waits for /health and reports.
set -eu

COMPOSE_DIR="${1:-.}"
API_HOST="${API_HOST:-kaundiaapi.anshintech.dpdns.org}"
BACKEND_SERVICE=backend
UPLOAD_DIR_IN_CONTAINER=/app/uploads

log() { printf '\n=== %s ===\n' "$1"; }

cd "$COMPOSE_DIR"
[ -f docker-compose.yml ] || { echo "ERROR: $PWD/docker-compose.yml not found (pass the deploy dir as \$1)" >&2; exit 1; }
[ -f .env ] || echo "WARNING: no .env next to docker-compose.yml; BACKEND_IMAGE/FRONTEND_IMAGE must come from the environment" >&2

dc() {
    if [ -f docker-compose.prod.yml ]; then
        docker compose -f docker-compose.yml -f docker-compose.prod.yml "$@"
    else
        docker compose "$@"
    fi
}

dc version >/dev/null 2>&1 || { echo "ERROR: docker compose not available" >&2; exit 1; }

log "1/3 Current backend container and upload state (BEFORE deploy)"
BACKEND_CONTAINER="$(dc ps -q "$BACKEND_SERVICE" | head -n1 || true)"
if [ -n "$BACKEND_CONTAINER" ]; then
    echo "container: $BACKEND_CONTAINER"
    VOLUME_MOUNTED="$(docker inspect -f '{{range .Mounts}}{{.Destination}} {{end}}' "$BACKEND_CONTAINER" \
        | tr ' ' '\n' | grep -cx "$UPLOAD_DIR_IN_CONTAINER" || true)"
    if [ "$VOLUME_MOUNTED" = "0" ]; then
        echo "WARNING: $UPLOAD_DIR_IN_CONTAINER is NOT a volume mount; rescuing into ./backend_uploads_rescue"
        BACKUP_TMP="$(mktemp -d)"
        docker cp "$BACKEND_CONTAINER:$UPLOAD_DIR_IN_CONTAINER/." "$BACKUP_TMP/"
        mkdir -p backend_uploads_rescue
        cp -a "$BACKUP_TMP/." backend_uploads_rescue/
        rmdir "$BACKUP_TMP" 2>/dev/null || true
        echo "Rescued $(find backend_uploads_rescue -type f | wc -l | tr -d ' ') file(s)"
    else
        echo "$UPLOAD_DIR_IN_CONTAINER is volume-mounted; no rescue copy needed."
    fi
else
    echo "No running backend container (fresh deploy)."
fi

log "2/3 Pulling images and recreating the stack"
dc pull --ignore-buildable backend frontend
dc up -d --force-recreate --no-build
# 'down' is deliberately NOT used: it is one wrong flag (-v) away from
# deleting postgres_data and backend_uploads.

log "3/3 Waiting for backend health"
i=0
until curl -fsS "http://127.0.0.1:9090/health" >/dev/null 2>&1; do
    i=$((i + 1))
    [ "$i" -ge 30 ] && { echo "ERROR: backend did not become healthy; check: docker compose logs backend" >&2; dc logs --tail 40 backend >&2 || true; exit 1; }
    sleep 2
done
echo "backend healthy"

if [ -d backend_uploads_rescue ]; then
    echo "Restoring rescued uploads into the volume..."
    docker cp backend_uploads_rescue/. "$(dc ps -q "$BACKEND_SERVICE"):$UPLOAD_DIR_IN_CONTAINER/"
    rm -rf backend_uploads_rescue
fi

echo
echo "Deployed images:"
dc ps --format '{{.Name}}\t{{.Image}}\t{{.Status}}'
echo "Sanity check: curl -sS -o /dev/null -w '%{http_code}\n' https://$API_HOST/health"
