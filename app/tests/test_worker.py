import httpx2
import pytest
from prometheus_client import REGISTRY

from uptime.worker import check_all, probe

pytestmark = pytest.mark.anyio


def handler(request):
    if request.url.host == "down.test":
        return httpx2.Response(503)
    if request.url.host == "broken.test":
        raise httpx2.ConnectError("connection refused", request=request)
    return httpx2.Response(200)


def mock_client():
    return httpx2.AsyncClient(transport=httpx2.MockTransport(handler))


@pytest.mark.parametrize(
    ("url", "up", "status_code"),
    [
        ("https://up.test/", True, 200),
        ("https://down.test/", False, 503),
        ("https://broken.test/", False, None),
    ],
)
async def test_probe(url, up, status_code):
    async with mock_client() as client:
        result = await probe(client, url)
    assert (result["up"], result["status_code"]) == (up, status_code)


async def test_check_all_stores_results_and_metrics(db):
    db.execute("INSERT INTO targets (url) VALUES ('https://up.test/'), ('https://broken.test/')")
    async with mock_client() as client:
        await check_all(client)

    rows = db.execute("SELECT target_id, up, status_code FROM checks ORDER BY target_id").fetchall()
    assert rows == [(1, True, 200), (2, False, None)]
    assert REGISTRY.get_sample_value("probe_up", {"target": "https://up.test/"}) == 1
    assert REGISTRY.get_sample_value("probe_up", {"target": "https://broken.test/"}) == 0
