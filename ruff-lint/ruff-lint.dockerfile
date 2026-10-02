# Astral already publishes Ruff itself as a from-scratch, statically
# linked container image (ghcr.io/astral-sh/ruff) meant to be copied out
# of, the same way sbx's own mixins ship a tool. No build of our own:
# the "build" stage below just is Astral's image, at the pinned tag.
# Default tracks ruff-lint.yaml's args.version default; the kit frontend
# always overrides it with the real build-arg, but a bare `docker build`
# without that frontend still resolves to a real, pinned image this way
# instead of an empty tag.
ARG RUFF_VERSION=0.17.1
FROM ghcr.io/astral-sh/ruff:${RUFF_VERSION} AS build

# `provides: ["ruff@…"]` is a claim about content, so the build checks the
# binary really is that release before shipping it. Astral's image has no
# shell, so the check runs in a busybox stage, and the overlay copies the
# binary out of that stage: BuildKit cannot skip a stage the result needs.
FROM busybox:1.37 AS check
ARG RUFF_VERSION
COPY --from=build /ruff /ruff
RUN test "$(/ruff --version)" = "ruff ${RUFF_VERSION}"

FROM scratch
COPY --from=check /ruff /usr/local/bin/ruff
