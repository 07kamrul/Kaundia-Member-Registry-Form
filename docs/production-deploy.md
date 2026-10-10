# Production deploy from published images

The pipeline is: `git push` → CI builds and publishes Docker images → the
server pulls them and recreates the stack.

## One-time server setup

On the production host, in the deploy directory (the one containing
`docker-compose.yml`):

1. Put the published image names in `.env`:

   ```
   BACKEND_IMAGE=docker.io/<you>/kaundia-backend:latest
   FRONTEND_IMAGE=docker.io/<you>/kaundia-frontend:latest
   ```

2. Get the scripts (they live in the repo, so a checkout of `main` works):
   `scripts/server-deploy.sh` and `scripts/auto-deploy-check.sh`.

## Manual deploy (after a push)

```sh
./scripts/server-deploy.sh
```

Pulls the latest images, rescues/uploads-safety-checks, recreates the stack,
waits for `/health`, and prints deployed image + status.

## Fully automatic deploys

Run the checker every 5 minutes; it only redeploys when the pulled images
actually changed:

```sh
(crontab -l 2>/dev/null; echo '*/5 * * * * /bin/sh /path/to/kaundia/scripts/auto-deploy-check.sh /path/to/kaundia >> /var/log/kaundia-auto-deploy.log 2>&1') | crontab -
```

## Roll back to a known tag

```sh
BACKEND_IMAGE=docker.io/<you>/kaundia-backend:<old-tag> ./scripts/server-deploy.sh
```

`docker-compose.prod.yml` overrides the `build:` sections, so nothing is
compiled on the server.
