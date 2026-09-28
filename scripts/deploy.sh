#!/usr/bin/env sh
# Kaundia production deploy.
#
# Run this ON THE PRODUCTION HOST, from the directory containing
# docker-compose.yml (or set COMPOSE_DIR below / pass it as $1):
#
#   ./scripts/deploy.sh [/path/to/kaundia]
#
# What it does, in order:
#   1. Rescues uploads that exist only inside the running backend container
#      (ephemeral filesystem) into the named volume, so a recreate can't lose
#      them - this is the cause of the "/uploads 404" incident.
#   2. Pulls/rebuilds and recreates the stack with the current
#      docker-compose.yml (which mounts backend_uploads:/app/uploads).
#   3. Waits for /health, then verifies the uploads volume is mounted and
#      lists what is being served.
#   4. Optionally purges Cloudflare's cache for the API host, because the zone
#      caches /uploads responses for 4h and would otherwise keep serving 404s
#      for files that are already fixed. Set CF_API_TOKEN + CF_ZONE_ID to
#      enable (see https://dash.cloudflare.com -> API Tokens).
set -eu

COMPOSE_DIR="${1:-.}"
API_HOST="${API_HOST:-kaundiaapi.anshintech.dpdns.org}"
BACKEND_SERVICE=backend
BACKEND_CONTAINER=""          # resolved below
UPLOAD_DIR_IN_CONTAINER=/app/uploads

log() { printf '\n=== %s ===\n' "$1"; }

cd "$COMPOSE_DIR"
[ -f docker-compose.yml ] || { echo "ERROR: $PWD/docker-compose.yml not found (pass the deploy dir as \$1)" >&2; exit 1; }

docker compose version >/dev/null 2>&1 || { echo "ERROR: docker compose not available" >&2; exit 1; }

log "1/4 Current backend container and upload state (BEFORE deploy)"
BACKEND_CONTAINER="$(docker compose ps -q "$BACKEND_SERVICE" | head -n1 || true)"
if [ -n "$BACKEND_CONTAINER" ]; then
    echo "container: $BACKEND_CONTAINER"
    # Everything under /app/uploads that is NOT already backed by the volume
    # would vanish on recreate; copy it into the host-mounted volume first.
    if docker exec "$BACKEND_CONTAINER" sh -c "[ -d '$UPLOAD_DIR_IN_CONTAINER' ]"; then
        VOLUME_MOUNTED="$(docker inspect -f '{{range .Mounts}}{{.Destination}} {{end}}' "$BACKEND_CONTAINER" \
            | tr ' ' '\n' | grep -cx "$UPLOAD_DIR_IN_CONTAINER" || true)"
        if [ "$VOLUME_MOUNTED" = "0" ]; then
            echo "WARNING: $UPLOAD_DIR_IN_CONTAINER is NOT a volume mount in the running container."
            echo "Copying existing uploads into the named volume so they survive this deploy..."
            BACKUP_TMP="$(mktemp -d)"
            docker cp "$BACKEND_CONTAINER:$UPLOAD_DIR_IN_CONTAINER/." "$BACKUP_TMP/"
            mkdir -p backend_uploads_rescue
            cp -a "$BACKUP_TMP/." backend_uploads_rescue/
            rmdir "$BACKUP_TMP" 2>/dev/null || true
            echo "Rescued $(find backend_uploads_rescue -type f | wc -l | tr -d ' ') file(s) to $PWD/backend_uploads_rescue"
            echo "They will be restored into the volume after the new container starts."
        else
            echo "$UPLOAD_DIR_IN_CONTAINER is volume-mounted; no rescue copy needed."
        fi
        echo "Files currently in the container:"
        docker exec "$BACKEND_CONTAINER" sh -c "find '$UPLOAD_DIR_IN_CONTAINER' -type f | head -50" || true
    else
        echo "No $UPLOAD_DIR_IN_CONTAINER in the running container."
    fi
else
    echo "No running backend container (fresh deploy)."
fi

log "2/4 Pulling/building and recreating the stack"
docker compose pull --ignore-pull-failures || true
docker compose build "$BACKEND_SERVICE"
docker compose up -d --force-recreate
# 'docker compose down' is deliberately NOT used: it is unnecessary for a
# recreate and one wrong flag (-v) away from deleting postgres_data and
# backend_uploads.

log "3/4 Waiting for backend health"
i=0
until curl -fsS "http://127.0.0.1:9090/health" >/dev/null 2>&1; do
    i=$((i + 1))
    [ "$i" -ge 30 ] && { echo "ERROR: backend did not become healthy; check: docker compose logs $BACKEND_SERVICE" >&2; exit 1; }
    sleep 2
done
echo "backend healthy"

# Restore anything rescued in step 1 into the (now volume-backed) upload dir.
if [ -d backend_uploads_rescue ]; then
    echo "Restoring rescued uploads into the volume..."
    docker cp backend_uploads_rescue/. "$(docker compose ps -q "$BACKEND_SERVICE"):$UPLOAD_DIR_IN_CONTAINER/"
    rm -rf backend_uploads_rescue
fi

echo "Serving directory per backend logs:"
docker compose logs "$BACKEND_SERVICE" 2>&1 | grep '\[uploads\] serving directory' | tail -n1 || true
echo "Files now served from the volume:"
docker compose exec -T "$BACKEND_SERVICE" sh -c "find '$UPLOAD_DIR_IN_CONTAINER' -type f | head -50"

# The repair script also runs in the container's own startup command; this is
# just its report for the deploy log.
docker compose exec -T "$BACKEND_SERVICE" python -m scripts.repair_document_paths || true

log "4/4 Cloudflare cache purge (optional)"
if [ -n "${CF_API_TOKEN:-}" ] && [ -n "${CF_ZONE_ID:-}" ]; then
    status="$(curl -sS -o /tmp/cf_purge.json -w '%{http_code}' -X POST \
        "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/purge_cache" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data "{\"purge_everything\":true}")"
    cat /tmp/cf_purge.json; echo
    [ "$status" = "200" ] && echo "Cloudflare cache purged." || { echo "WARNING: Cloudflare purge returned HTTP $status" >&2; exit 1; }
else
    echo "Skipping (set CF_API_TOKEN and CF_ZONE_ID to purge automatically)."
    echo "Without a purge, Cloudflare may keep serving cached 404s for up to 4h."
fi

log "Deploy complete"
echo "Sanity check: curl -sS -o /dev/null -w '%{http_code}\n' https://$API_HOST/health"
