#!/usr/bin/env python3
"""Fetch khatian (ownership) data for every Uttar Kaundia BDS dag from
settlement.gov.bd and build backend/data/shared/khatians.json.

Dev-only companion to ingest.py. Raw responses are cached line-by-line in
data/_raw/khatians_raw.jsonl, so the run is resumable and reviewable:
rerun it and only the missing dags are fetched.
"""

import json
import ssl
import sys
import time
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
OUT_PATH = REPO / "backend" / "data" / "shared" / "khatians.json"
INDEX_PATH = REPO / "backend" / "data" / "uttar-kaundia" / "dag-index.json"

BASE = "https://settlement.gov.bd"
ENDPOINT = "/Khatian/GetKhatianDataList_MapSearch"
COMCOD = "4105"  # Dhaka district
RSNUM = "201901"  # BDS 2019 — the only survey served for this district
UNITCOD = "010510211"  # Uttar Kaundia mouza, Savar Upazila
DELAY_S = 0.4
RETRIES = 4


def post(dag: str) -> dict:
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
            "Referer": BASE + "/Khatian/MapSearch",
            "User-Agent": "Mozilla/5.0 (khatian-catalog-sync; contact: society app dev)",
        },
        method="POST",
    )
    last_err: Exception | None = None
    for attempt in range(RETRIES):
        try:
            with urllib.request.urlopen(req, timeout=30, context=SSL_CTX) as resp:
                text = resp.read().decode("utf-8")
                return json.loads(text) if text.strip() else {}
        except Exception as err:  # noqa: BLE001 - retry any transient failure
            last_err = err
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError(f"dag {dag}: {last_err}")


def load_cache() -> dict[str, dict]:
    cache: dict[str, dict] = {}
    if RAW_PATH.exists():
        for line in RAW_PATH.read_text().splitlines():
            if not line.strip():
                continue
            rec = json.loads(line)
            cache[rec["dag"]] = rec
    return cache


def dags() -> list[str]:
    index = json.load(INDEX_PATH.open())
    return sorted({key.split(":")[2] for key in index})


def main() -> int:
    all_dags = dags()
    cache = load_cache()
    missing = [d for d in all_dags if d not in cache]
    print(f"{len(all_dags)} dags, {len(missing)} to fetch", flush=True)

    with RAW_PATH.open("a") as raw:
        for i, dag in enumerate(missing):
            try:
                data = post(dag)
            except RuntimeError as err:
                print(err, flush=True)
                continue
            raw.write(json.dumps({"dag": dag, "data": data}, ensure_ascii=False) + "\n")
            raw.flush()
            if (i + 1) % 100 == 0:
                print(f"{i + 1}/{len(missing)} fetched", flush=True)
            time.sleep(DELAY_S)

    cache = load_cache()
    catalog: dict[str, list] = {}
    empty = 0
    for dag, data in sorted(cache.items(), key=lambda kv: int(kv[0])):
        owners = data.get("rptKhtSearch01b") or []
        infos = data.get("rptKhtSearch01a") or []
        if not owners or not infos:
            empty += 1
            continue
        grouped: dict[str, list[str]] = {}
        order: list[str] = []
        for row in owners:
            num = str(row.get("khtnum") or "")
            if num not in grouped:
                grouped[num] = []
                order.append(num)
            name = (row.get("ownname") or "").strip()
            if name:
                grouped[num].append(name)
        entries = []
        for num in order:
            info = next((r for r in infos if str(r.get("khtnum")) == num), {})
            entries.append(
                {
                    "no": num,
                    "owners": grouped[num],
                    "status": (info.get("khtstatus") or "").strip(),
                }
            )
        if entries:
            catalog[dag] = entries

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    header = (
        "Khatian (ownership) records for every BDS dag of Uttar Kaundia mouza, "
        "harvested from settlement.gov.bd /Khatian/GetKhatianDataList_MapSearch "
        "(survey BDS 2019, unitcod 010510211). Keyed by ASCII dag number; each "
        "entry lists the khatian number, recorded owners in portal order and the "
        "khtstatus column (চলমান জর)."
    )
    payload = {"_comment": header, **catalog}
    OUT_PATH.write_text(
        json.dumps(payload, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print(
        f"written {OUT_PATH}: {len(catalog)} dags with data, {empty} empty", flush=True
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
