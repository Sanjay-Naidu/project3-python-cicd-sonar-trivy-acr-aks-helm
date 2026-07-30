# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : app/main.py - FastAPI application entrypoint
# =============================================================================
"""DevOps Quotes API.

A small but production-shaped FastAPI service used to demonstrate a full
CI/CD pipeline (GitHub Actions -> SonarCloud -> Trivy -> ACR -> AKS/Helm).

Production traits demonstrated here:
- separate liveness (/healthz) and readiness (/readyz) endpoints for K8s probes
- Prometheus metrics exposed on /metrics
- configuration via environment variables (12-factor), injected by Helm
- version/environment surfaced on the root endpoint so you can *see* which
  build is running in each namespace after a deployment
"""

import logging
import os
import random
import socket

from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator

APP_NAME = "project3-python-app"
# APP_VERSION is injected by the Helm chart (set to the image tag by the CD
# pipeline) so the running pod can report exactly which build it is.
APP_VERSION = os.getenv("APP_VERSION", "0.1.0-local")
ENVIRONMENT = os.getenv("ENVIRONMENT", "local")
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger(APP_NAME)

app = FastAPI(
    title="DevOps Quotes API",
    description="Demo service for Project 3 - Python CI/CD on AKS (by Sanjay Naidu)",
    version=APP_VERSION,
)

# /metrics endpoint for Prometheus scraping (excluded from OpenAPI docs).
Instrumentator().instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)

QUOTES = [
    {"id": 1, "author": "Werner Vogels", "text": "Everything fails, all the time."},
    {
        "id": 2,
        "author": "Gene Kim",
        "text": "Improving daily work is even more important than doing daily work.",
    },
    {
        "id": 3,
        "author": "John Allspaw",
        "text": "Blameless postmortems are a tenet of a learning culture.",
    },
    {
        "id": 4,
        "author": "Kelsey Hightower",
        "text": "Automation is not about replacing humans, it is about amplifying them.",
    },
    {
        "id": 5,
        "author": "Charity Majors",
        "text": "You cannot have quality without observability.",
    },
    {
        "id": 6,
        "author": "Jez Humble",
        "text": "If it hurts, do it more frequently, and bring the pain forward.",
    },
]


@app.get("/")
def root() -> dict:
    """Service info - handy for verifying which version runs in which namespace."""
    return {
        "app": APP_NAME,
        "version": APP_VERSION,
        "environment": ENVIRONMENT,
        "hostname": socket.gethostname(),
        "docs": "/docs",
        "endpoints": ["/api/v1/quotes", "/api/v1/quotes/random", "/healthz", "/readyz", "/metrics"],
    }


@app.get("/healthz")
def liveness() -> dict:
    """Liveness probe: process is up. Kubernetes restarts the pod if this fails."""
    return {"status": "ok"}


@app.get("/readyz")
def readiness() -> dict:
    """Readiness probe: ready for traffic. Kubernetes stops routing if this fails.

    Kept separate from /healthz on purpose: a service can be alive but not
    ready (e.g. warming up, dependency down) - restarting would be wrong.
    """
    return {"status": "ready"}


@app.get("/api/v1/quotes")
def list_quotes() -> dict:
    """Return every quote."""
    return {"count": len(QUOTES), "quotes": QUOTES}


@app.get("/api/v1/quotes/random")
def random_quote() -> dict:
    """Return one random quote."""
    quote = random.choice(QUOTES)
    logger.info("served random quote id=%s", quote["id"])
    return quote


@app.get("/api/v1/quotes/{quote_id}")
def get_quote(quote_id: int) -> dict:
    """Return a quote by id, 404 if unknown."""
    for quote in QUOTES:
        if quote["id"] == quote_id:
            return quote
    raise HTTPException(status_code=404, detail=f"Quote {quote_id} not found")
