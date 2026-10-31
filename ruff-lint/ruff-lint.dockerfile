# syntax=docker/dockerfile:1
# Ruff comes from its PyPI musllinux wheel: a statically linked binary, so
# it runs on glibc and musl bases alike. Astral's own image
# (ghcr.io/astral-sh/ruff) is static too, but its aarch64 build bundles a
# jemalloc compiled for 4K pages, which aborts with "Unsupported system page
# size" on the 16K-page kernel of sbx VMs on Apple Silicon. The wheel's
# build doesn't.
# Default tracks ruff-lint.yaml's args.version default; the kit frontend
# always overrides it with the real build-arg, but a bare `docker build`
# without that frontend still resolves to a real, pinned release this way
# instead of an empty version.
ARG RUFF_VERSION=0.17.1
FROM python:3.15-alpine3.24 AS build
ARG RUFF_VERSION
# On Alpine, pip only accepts musllinux wheels, and --only-binary rules out
# building from the sdist. `provides: ["ruff@…"]` is a claim about content,
# so the build then checks the binary really is that release.
RUN pip install --no-cache-dir --no-deps --only-binary=:all: \
      --target /out "ruff==${RUFF_VERSION}" \
 && test "$(/out/bin/ruff --version)" = "ruff ${RUFF_VERSION}"

FROM scratch
COPY --from=build /out/bin/ruff /usr/local/bin/ruff
