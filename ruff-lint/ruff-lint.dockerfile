FROM debian:trixie-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*
RUN curl -LsSf https://astral.sh/uv/install.sh -o /tmp/install-uv.sh \
    && sh /tmp/install-uv.sh \
    && rm /tmp/install-uv.sh

ARG RUFF_VERSION
RUN /root/.local/bin/uv tool install "ruff==${RUFF_VERSION}"

FROM scratch
COPY --from=build /root/.local/share/uv/tools/ruff/bin/ruff /usr/local/bin/ruff
