#!/usr/bin/env sh
# Auto-deploy check: pull the published images and redeploy ONLY if they
# changed. Meant to run from a systemd timer or cron every few minutes, so a
# git push (which CI turns into fresh images) reaches production without a
# manual step:
#
#   */5 * * * * /opt/kaundia/scripts/auto-deploy-check.sh /opt/kaundia >> /var/log/kaundia-auto-deploy.log 2>&1
#
# Lockfile prevents overlapping runs if a pull is slow.
set -eu

COMPOSE_DIR="${1:-.}"
LOCK=/tmp/kaundia-auto-deploy.lock

exec 9>"$LOCK"
flock -n 9 || exit 0    # another run is already in flight

cd "$COMPOSE_DIR"

dc() {
    if [ -f docker-compose.prod.yml ]; then
        docker compose -f docker-compose.yml -f docker-compose.prod.yml "$@"
    else
        docker compose "$@"
    fi
}

before="$(dc images -q backend frontend 2>/dev/null | sort | tr '\n' ' ')"

dc pull -q backend frontend >/dev/null 2>&1 || { echo "$(date -Is) pull failed; keeping current containers" >&2; exit 1; }

after="$(dc images -q backend frontend 2>/dev/null | sort | tr '\n' ' ')"

if [ "$before" = "$after" ]; then
    exit 0    # nothing new published
fi

echo "$(date -Is) new image(s) detected ($before -> $after), deploying..."
exec sh "$(dirname "$0")/server-deploy.sh" "$COMPOSE_DIR"
