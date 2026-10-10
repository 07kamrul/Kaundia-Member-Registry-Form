import pytest


@pytest.mark.asyncio
async def test_serves_geo_dataset_without_auth(client):
    res = await client.get("/api/data/bd-geo.json")

    assert res.status_code == 200
    assert {"divisions", "districts", "upazilas"} <= res.json().keys()


@pytest.mark.asyncio
async def test_extension_is_optional(client):
    res = await client.get("/api/data/bd-geo")

    assert res.status_code == 200


@pytest.mark.asyncio
@pytest.mark.parametrize("name", ["missing.json", "..%2Fmeta.json", "meta"])
async def test_unknown_or_traversal_names_return_404(client, name):
    res = await client.get(f"/api/data/{name}")

    assert res.status_code == 404
