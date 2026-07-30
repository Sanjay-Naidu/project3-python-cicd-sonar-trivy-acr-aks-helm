# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : tests/test_main.py - API tests (run by CI, coverage fed to Sonar)
# =============================================================================

from fastapi.testclient import TestClient

from app.main import QUOTES, app

client = TestClient(app)


def test_root_reports_app_metadata():
    response = client.get("/")
    assert response.status_code == 200
    body = response.json()
    assert body["app"] == "project3-python-app"
    assert "version" in body
    assert "environment" in body


def test_liveness_probe():
    response = client.get("/healthz")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_probe():
    response = client.get("/readyz")
    assert response.status_code == 200
    assert response.json() == {"status": "ready"}


def test_list_quotes_returns_all():
    response = client.get("/api/v1/quotes")
    assert response.status_code == 200
    body = response.json()
    assert body["count"] == len(QUOTES)
    assert len(body["quotes"]) == len(QUOTES)


def test_random_quote_is_a_known_quote():
    response = client.get("/api/v1/quotes/random")
    assert response.status_code == 200
    assert response.json() in QUOTES


def test_get_quote_by_id():
    response = client.get("/api/v1/quotes/1")
    assert response.status_code == 200
    assert response.json()["id"] == 1


def test_get_unknown_quote_returns_404():
    response = client.get("/api/v1/quotes/999")
    assert response.status_code == 404


def test_metrics_endpoint_exposed():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_request" in response.text
