#!/usr/bin/env python3
"""Fetch the khatian (ownership) popup data for every Uttar Kaundia BDS dag
from settlement.gov.bd into the gitignored raw cache.

Dev-only companion to ingest.py; the app never imports this. Each response of
``POST /Khatian/GetKhatianDataList_MapSearch`` is appended to
``data/_raw/khatians_raw.jsonl`` (one line per dag, flushed immediately), so
the run is resumable and reviewable. Turn the cache into the served dataset
with ``build_khatians.py``.

Politeness: one anonymous session (cookies from loading the MapSearch page, as
a browser does), strictly sequential requests, a delay between them, backoff
on transient errors, and a hard abort on HTTP 403/429 — no circumvention.

    python3 fetch_khatians.py --dry-run   # counts + time estimate only
    python3 fetch_khatians.py             # fetch the missing dags
"""

import argparse
import concurrent.futures
import http.cookiejar
import json
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

try:  # macOS system python often lacks a CA store; certifi ships with requests
    import certifi

    SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    SSL_CTX = ssl.create_default_context()

REPO = Path(__file__).resolve().parents[2]
RAW_PATH = REPO / "data" / "_raw" / "khatians_raw.jsonl"
INDEX_PATH = REPO / "backend" / "data" / "uttar-kaundia" / "dag-index.json"

BASE = "https://settlement.gov.bd"
PAGE = "/Khatian/MapSearch"
ENDPOINT = "/Khatian/GetKhatianDataList_MapSearch"
COMCOD = "4105"  # Dhaka district
RSNUM = "201901"  # BDS 2019 — the only survey served for this district
UNITCOD = "010510211"  # Uttar Kaundia mouza, Savar Upazila
USER_AGENT = "Mozilla/5.0 (khatian-catalog-sync; contact: society app dev)"
DEFAULT_DELAY_S = 0.4
RETRIES = 4
ABORT_STATUSES = (403, 429)


class UpstreamBlocked(RuntimeError):
    """The portal refused us (403/429) — stop immediately, never retry."""


def make_opener() -> urllib.request.OpenerDirector:
    jar = http.cookiejar.CookieJar()
    return urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(jar),
        urllib.request.HTTPSHandler(context=SSL_CTX),
    )


def open_session(opener: urllib.request.OpenerDirector) -> None:
    """Load the MapSearch page once so the server issues its anonymous cookies."""
    req = urllib.request.Request(BASE + PAGE, headers={"User-Agent": USER_AGENT})
    try:
        with opener.open(req, timeout=30) as resp:
            resp.read()
    except urllib.error.HTTPError as err:
        if err.code in ABORT_STATUSES:
            raise UpstreamBlocked(f"HTTP {err.code} on session page") from err
        # The endpoint answers anonymous POSTs; a missing page is not fatal.
        print(f"note: session page returned HTTP {err.code}; continuing anonymously")


def post(opener: urllib.request.OpenerDirector, dag: str) -> dict:
    body = urllib.parse.urlencode(
        {"compcode": COMCOD, "rsnum": RSNUM, "unitcod": UNITCOD, "CurDag": dag}
    ).encode()
    req = urllib.request.Request(
        BASE + ENDPOINT,
        data=body,
        headers={
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "X-Requested-With": "XMLHttpRequest",
            "Origin": BASE,
            "Referer": BASE + PAGE,
            "User-Agent": USER_AGENT,
        },
        method="POST",
    )
    last_err: Exception | None = None
    for attempt in range(RETRIES):
        try:
            with opener.open(req, timeout=30) as resp:
                text = resp.read().decode("utf-8")
                return json.loads(text) if text.strip() else {}
        except urllib.error.HTTPError as err:
            if err.code in ABORT_STATUSES:
                raise UpstreamBlocked(f"HTTP {err.code} on dag {dag}") from err
            last_err = err
        except Exception as err:  # noqa: BLE001 - retry any transient failure
            last_err = err
        time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"dag {dag}: {last_err}")


def load_cache() -> dict[str, dict]:
    cache: dict[str, dict] = {}
    if RAW_PATH.exists():
        for line in RAW_PATH.read_text(encoding="utf-8").splitlines():
            if line.strip():
                rec = json.loads(line)
                cache[rec["dag"]] = rec
    return cache


def geometry_dags() -> list[str]:
    index = json.loads(INDEX_PATH.read_text(encoding="utf-8"))
    return sorted({key.split(":")[2] for key in index}, key=int)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--delay", type=float, default=DEFAULT_DELAY_S)
    parser.add_argument("--dry-run", action="store_true", help="report counts only")
    parser.add_argument(
        "--workers", type=int, default=1, help="parallel requests (keep low; default 1)"
    )
    args = parser.parse_args()

    all_dags = geometry_dags()
    cache = load_cache()
    missing = [d for d in all_dags if d not in cache]
    est_min = len(missing) * (args.delay + 0.3) / 60  # ~0.3 s server latency
    print(
        f"{len(all_dags)} distinct dags, {len(all_dags) - len(missing)} cached, "
        f"{len(missing)} to fetch (~{est_min:.0f} min at {args.delay}s delay)",
        flush=True,
    )
    if args.dry_run or not missing:
        return 0

    opener = make_opener()
    open_session(opener)
    failed: list[str] = []
    blocked: list[str] = []
    RAW_PATH.parent.mkdir(parents=True, exist_ok=True)

    def fetch(dag: str) -> tuple[str, dict | None]:
        if blocked:  # another worker was refused: stop sending requests
            return dag, None
        try:
            data = post(opener, dag)
        except UpstreamBlocked as err:
            blocked.append(str(err))
            return dag, None
        except RuntimeError as err:
            print(err, flush=True)
            failed.append(dag)
            return dag, None
        time.sleep(args.delay)
        return dag, data

    with RAW_PATH.open("a", encoding="utf-8") as raw:
        with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
            for i, (dag, data) in enumerate(pool.map(fetch, missing), start=1):
                if data is None:
                    continue
                raw.write(json.dumps({"dag": dag, "data": data}, ensure_ascii=False) + "\n")
                raw.flush()
                if i % 100 == 0:
                    print(f"{i}/{len(missing)} fetched", flush=True)

    if blocked:
        print(f"ABORT: {blocked[0]}. Not retrying; wait before resuming.", flush=True)
        return 2
    print(f"done; {len(failed)} failed (rerun to retry): {failed[:20]}", flush=True)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
