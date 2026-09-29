# OOM recovery & memory runbook (prod VPS)

Kernel killed a process ("Out of memory: Killed process … MainThread
total-vm:31254824kB") and login then failed. `total-vm` is *virtual* address
space, not resident RAM — the killer reacts to real memory pressure. Deploy
config fixes live in `docker-compose.yml` / Dockerfiles (memory limits,
Postgres tuning, Node build heap cap); this file is what to do on the server.

## 1. Diagnose (do this before touching anything)
```sh
free -h                      # total RAM, swap
swapon --show
dmesg -T | grep -i "out of memory" | tail   # who was killed and when
docker stats --no-stream     # per-container current usage
ps aux --sort=-%mem | head -20
```
Repeat `docker stats` an hour apart: one container climbing steadily = leak;
everything high all the time = structural oversizing.

## 2. Immediate safety net: swap file (skip if `swapon --show` lists one)
```sh
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
sysctl vm.swappiness=10      # prefer reclaiming cache over swapping
```

## 3. Apply the new compose config
```sh
docker compose pull && docker compose up -d --build --force-recreate
docker compose ps
docker stats --no-stream
```
Limits now set per service: postgres 1 GB, backend 768 MB, frontend 128 MB
(`memswap_limit` equals `mem_limit`, so nothing swaps silently inside its
cgroup — a service that exceeds its limit restarts instead of starving the
host). If Dokploy manages the stack with its own copy of these settings,
mirror the same limits there (Dokploy → service → Advanced → Resources).

## 4. Verify
- `journalctl -k | grep -i oom` stays quiet after the redeploy.
- Log in works; `/health` returns ok; `docker compose logs backend | tail`
  shows no restart loop.
- Watch `free -h` + `docker stats` for a few hours: backend RSS should sit
  roughly in the 150–400 MB range and stay flat; Postgres within its 1 GB.

## 5. If it OOMs again
- Check `dmesg` for the new victim and which cgroup it belonged to — with
  per-service limits the killer now acts inside a container first.
- A backend container being OOM-killed repeatedly = memory leak in the app:
  snapshot `tracemalloc` or restart-and-watch RSS growth rate.
- Postgres hitting its limit: check `pg_stat_activity` for runaway sorts;
  raise `work_mem` only for the specific heavy query.
