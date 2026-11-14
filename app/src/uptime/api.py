from fastapi import FastAPI, HTTPException
from psycopg.errors import UniqueViolation
from pydantic import BaseModel, HttpUrl

from uptime.db import connect

app = FastAPI(title="uptime-platform")

STATUS_SQL = """
SELECT t.id, t.url, c.up, c.status_code, c.duration_seconds, c.error, c.checked_at
FROM targets t
LEFT JOIN LATERAL (
    SELECT * FROM checks WHERE target_id = t.id ORDER BY checked_at DESC LIMIT 1
) c ON true
ORDER BY t.id
"""


class Target(BaseModel):
    url: HttpUrl


@app.get("/healthz")
async def healthz():
    return {"status": "ok"}


@app.post("/targets", status_code=201)
async def add_target(target: Target):
    async with await connect() as conn:
        try:
            cur = await conn.execute(
                "INSERT INTO targets (url) VALUES (%s) RETURNING id, url", (str(target.url),)
            )
        except UniqueViolation:
            raise HTTPException(409, "target already exists") from None
        return await cur.fetchone()


@app.get("/targets")
async def list_targets():
    async with await connect() as conn:
        cur = await conn.execute("SELECT id, url FROM targets ORDER BY id")
        return await cur.fetchall()


@app.delete("/targets/{target_id}", status_code=204)
async def delete_target(target_id: int):
    async with await connect() as conn:
        cur = await conn.execute("DELETE FROM targets WHERE id = %s", (target_id,))
        if cur.rowcount == 0:
            raise HTTPException(404, "target not found")


@app.get("/status")
async def status():
    async with await connect() as conn:
        cur = await conn.execute(STATUS_SQL)
        return await cur.fetchall()
