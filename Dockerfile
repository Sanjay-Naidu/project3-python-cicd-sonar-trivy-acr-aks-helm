# =============================================================================
# Project : Project 3 - Python App CI/CD on Azure AKS
# Author  : Sanjay Naidu
# File    : Dockerfile - multi-stage, non-root, minimal production image
# =============================================================================
# WHY multi-stage : build tooling (pip, wheels) never ships in the final image
#                   -> smaller image, smaller attack surface, cleaner Trivy scan.
# WHY slim base   : ~120MB vs ~1GB for the full python image.
# WHY non-root    : container breakout blast radius is reduced; also required
#                   by the Helm chart's securityContext (runAsNonRoot: true).

# ---------- Stage 1 : build dependencies ----------
FROM python:3.12-slim AS builder

WORKDIR /build

# Copy only requirements first so Docker layer caching skips re-installing
# dependencies when only application code changes.
COPY app/requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2 : runtime ----------
FROM python:3.12-slim

LABEL org.opencontainers.image.title="project3-python-app" \
      org.opencontainers.image.authors="Sanjay Naidu" \
      org.opencontainers.image.description="FastAPI demo app deployed to AKS via Helm and GitHub Actions" \
      org.opencontainers.image.source="https://github.com/Sanjay-Naidu/project3-python-cicd-sonar-trivy-acr-aks-helm"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Dedicated unprivileged user (high UID avoids clashing with host users).
RUN groupadd --gid 10001 appuser \
    && useradd --uid 10001 --gid 10001 --create-home --shell /usr/sbin/nologin appuser

WORKDIR /opt/project

# Bring in the installed site-packages from the builder stage only.
COPY --from=builder /install /usr/local
COPY app/ ./app/

USER 10001

EXPOSE 8000

# Container-level healthcheck (Kubernetes uses its own HTTP probes, but this
# also makes the image self-diagnosing when run with plain `docker run`).
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/healthz', timeout=2).status == 200 else 1)"]

# 2 workers is right-sized for the B2s nodes; Kubernetes handles horizontal scale.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
