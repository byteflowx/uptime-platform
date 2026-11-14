import asyncio
import logging
import os
import time

import httpx2
from prometheus_client import Gauge, start_http_server

from uptime.db import connect

log = logging.getLogger("uptime.worker")

UP = Gauge("probe_up", "1 if the site answered with a status below 400", ["target"])
DURATION = Gauge("probe_duration_seconds", "Response time of the last check", ["target"])
STATUS = Gauge("probe_http_status", "HTTP status of the last check, 0 on error", ["target"])


async def probe(client: httpx2.AsyncClient, url: str) -> dict:
    start = time.perf_counter()
    try:
        response = await client.get(url)
        status_code, error = response.status_code, None
    except httpx2.HTTPError as exc:
        status_code, error = None, f"{type(exc).__name__}: {exc}"
    return {
        "up": status_code is not None and status_code < 400,
        "status_code": status_code,
        "duration_seconds": time.perf_counter() - start,
        "error": error,
    }


async def check_all(client: httpx2.AsyncClient) -> None:
    async with await connect() as conn:
        targets = await (await conn.execute("SELECT id, url FROM targets")).fetchall()
        results = await asyncio.gather(*(probe(client, t["url"]) for t in targets))
        async with conn.cursor() as cur:
            await cur.executemany(
                "INSERT INTO checks (target_id, up, status_code, duration_seconds, error) "
                "VALUES (%(target_id)s, %(up)s, %(status_code)s, %(duration_seconds)s, %(error)s)",
                [{"target_id": t["id"], **r} for t, r in zip(targets, results, strict=True)],
            )

    for gauge in (UP, DURATION, STATUS):
        gauge.clear()
    for target, result in zip(targets, results, strict=True):
        UP.labels(target["url"]).set(result["up"])
        DURATION.labels(target["url"]).set(result["duration_seconds"])
        STATUS.labels(target["url"]).set(result["status_code"] or 0)


async def main() -> None:
    logging.basicConfig(level=logging.INFO)
    start_http_server(8001)
    interval = float(os.environ.get("CHECK_INTERVAL_SECONDS", "30"))
    async with httpx2.AsyncClient(timeout=10, follow_redirects=True) as client:
        while True:
            try:
                await check_all(client)
            except Exception:
                log.exception("check round failed")
            await asyncio.sleep(interval)


if __name__ == "__main__":
    asyncio.run(main())
