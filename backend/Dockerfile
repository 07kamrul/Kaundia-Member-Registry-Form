FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_ROOT_USER_ACTION=ignore \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    STORAGE_BASE_DIR=/app/uploads

# Runtime hint so Python's allocator returns freed arenas to the OS more
# eagerly; matters on small VPSes where RSS creep from response buffers was
# getting the container OOM-killed under global memory pressure.
ENV MALLOC_ARENA_MAX=2 \
    MALLOC_TRIM_THRESHOLD_=131072

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Strip CRLF in case the repo was checked out on Windows.
RUN sed -i 's/\r$//' scripts/*.sh && chmod +x scripts/entrypoint.sh && mkdir -p /app/uploads

# Uploads must outlive the container; mount persistent storage here.
VOLUME ["/app/uploads"]

EXPOSE 9090

# Entrypoint pins STORAGE_BASE_DIR, prepares uploads, migrates + seeds.
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9090"]
