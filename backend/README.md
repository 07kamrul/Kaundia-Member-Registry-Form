# Kaundia Member Registry - Backend

FastAPI backend for the Kaundia Member Registry Form. Provides public
submission intake, admin review/approval, member credential issuance,
member self-service, and installment tracking.

## Stack

- FastAPI + Uvicorn
- SQLAlchemy 2.x (async, asyncpg driver) + Alembic
- PostgreSQL (SQLite supported for local dev/tests)
- JWT auth (access + refresh) via python-jose, passwords hashed with bcrypt
- Local disk file storage under `uploads/`
- Email via aiosmtplib

## Local setup (venv)

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt

cp .env.example .env
# edit .env: set DATABASE_URL, JWT_SECRET_KEY, SMTP_*, ADMIN_* as needed
```

For local dev without Postgres, you can use SQLite:

```
DATABASE_URL=sqlite+aiosqlite:///./dev.db
```

## Database migrations

```bash
alembic upgrade head
```

To generate a new migration after changing models:

```bash
alembic revision --autogenerate -m "describe change"
```

## Seed an initial admin user

Reads `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_NAME` from `.env`:

```bash
python -m app.seed
```

## Run the API

```bash
uvicorn app.main:app --reload --port 9090
```

API is served under `http://localhost:9090/api`, docs at
`http://localhost:9090/docs`, health check at `http://localhost:9090/health`.
Uploaded files are served from `http://localhost:9090/uploads/...`.

## Run tests

```bash
pytest -q
```

Covers the public submission -> admin approval -> member ID generation ->
member login -> change-password flow, plus rejection.

## Docker Compose (from repo root)

```bash
docker compose up --build
```

This starts Postgres and the backend (which runs migrations and the admin
seed script automatically on boot, then serves on port 9090). A commented-out
placeholder `frontend` service is included in the root `docker-compose.yml`
for wiring up the existing Next.js app later.

## Project layout

```
backend/
  app/
    main.py            FastAPI app, routers, static uploads mount
    core/               config.py (settings), security.py (JWT/bcrypt), deps.py (auth deps)
    db/                 base.py (declarative base), session.py (async engine/session)
    models/              SQLAlchemy models (member, property, nominee, admin, credential, installment)
    schemas/             Pydantic request/response DTOs
    api/routes/          submissions.py, auth.py, admin.py, member.py
    services/            email.py, storage.py
    seed.py              admin bootstrap script
  alembic/               migrations
  tests/                 pytest suite (httpx AsyncClient + in-memory SQLite)
```
