# Keep the uv version aligned with .github/workflows/ci.yml.
# Tag: uv:0.12.10-python3.12-trixie-slim (pinned by digest; Dependabot bumps this).
FROM ghcr.io/astral-sh/uv@sha256:4bf11151c225e2a4d60e2a576b67d925660055199389d9a64fbdc02b6f3d43d5

# 0.0.0.0 is non-loopback, so the server refuses to start over HTTP unless
# MONARCH_MCP_HTTP_TOKEN is passed at run time (never bake it into the image).
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_NO_CACHE=1 \
    UV_PYTHON_DOWNLOADS=0 \
    MONARCH_MCP_TRANSPORT=streamable-http \
    MONARCH_MCP_HOST=0.0.0.0 \
    PATH="/app/.venv/bin:$PATH"

WORKDIR /app

# Install locked runtime dependencies separately so source changes reuse this layer.
COPY pyproject.toml uv.lock ./
RUN uv sync --locked --no-dev --no-install-project

COPY README.md LICENSE ./
COPY src/ ./src/
RUN uv sync --locked --no-dev --no-editable

COPY login_setup.py ./

# Session credentials live in this user's home and can be persisted with a volume.
RUN useradd --create-home --uid 10001 app \
    && mkdir /home/app/.monarch-mcp-server \
    && chown app:app /home/app/.monarch-mcp-server
USER app

EXPOSE 8000
CMD ["monarch-mcp-server"]
