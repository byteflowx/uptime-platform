from fastapi.testclient import TestClient

from uptime.api import app

client = TestClient(app)


def test_targets(db):
    response = client.post("/targets", json={"url": "https://example.com"})
    assert response.status_code == 201
    assert response.json() == {"id": 1, "url": "https://example.com/"}

    assert client.post("/targets", json={"url": "https://example.com"}).status_code == 409
    assert client.post("/targets", json={"url": "not a url"}).status_code == 422
    assert client.get("/targets").json() == [{"id": 1, "url": "https://example.com/"}]

    assert client.delete("/targets/1").status_code == 204
    assert client.delete("/targets/1").status_code == 404


def test_status_shows_latest_check(db):
    db.execute("INSERT INTO targets (url) VALUES ('https://a.test/'), ('https://b.test/')")
    db.execute(
        "INSERT INTO checks (target_id, checked_at, up, status_code, duration_seconds) VALUES "
        "(1, now() - interval '1 minute', false, 503, 0.2), (1, now(), true, 200, 0.1)"
    )

    a, b = client.get("/status").json()
    assert (a["up"], a["status_code"]) == (True, 200)
    assert b["up"] is None
