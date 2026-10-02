# syntax=docker/dockerfile:1
# Overlay recipe for junie-local-mixin: Junie CLI plus a `junie-local` command
# that starts it against the host engine, landing on any base.
#
# The install steps are the junie-local workload's own (../junie-local/
# junie-local.dockerfile), run on the same base as a build stage. Only the
# paths the installer creates are shipped: the shim and its payload. The base's
# other ~/.local content is not copied, so it is not overwritten.
#
# This overlay contains JetBrains' proprietary Junie build, exactly like the
# workload image. It is built on your machine; do not push it to a registry.
# Use is subject to the JetBrains AI Service Terms of Service.
FROM docker/sandbox-templates:shell-docker AS build

# install.sh aborts early on Linux without unzip (see require_extractor).
USER root
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*

# Install as the agent user so the tree lands in /home/agent/.local, where the
# shim expects it.
USER agent
ENV PATH="/home/agent/.local/bin:${PATH}"
ENV JUNIE_SKIP_UPDATE_CHECK=1
RUN curl -fsSL https://junie.jetbrains.com/install.sh | bash

# Fail the build rather than the sandbox if the install did not take.
RUN junie --version

# Stage the overlay. /home stays root-owned and /home/agent and below belong
# to uid 1000, as on the base.
#
#   * /usr/local/bin/junie        link to the shim, so `junie` is on every PATH
#                                 without a profile edit
#   * /usr/local/bin/junie-local  the workload's launch command as a command:
#                                 the mixin cannot own the entrypoint
#   * /etc/profile.d/...          JUNIE_SKIP_UPDATE_CHECK for login shells; a
#                                 mixin's ENV does not reach the composed image
USER root
RUN set -eux; \
    mkdir -p /out/home/agent/.local/bin /out/home/agent/.local/share /out/usr/local/bin /out/etc/profile.d; \
    cp -a /home/agent/.local/bin/junie /out/home/agent/.local/bin/junie; \
    cp -a /home/agent/.local/share/junie /out/home/agent/.local/share/junie; \
    chown -R 1000:1000 /out/home/agent; \
    ln -s /home/agent/.local/bin/junie /out/usr/local/bin/junie; \
    printf '%s\n' 'export JUNIE_SKIP_UPDATE_CHECK=1' > /out/etc/profile.d/junie-local-env.sh
COPY --chmod=0755 <<'SCRIPT' /out/usr/local/bin/junie-local
#!/usr/bin/env bash
# Start Junie against the host's junie-mlx-vlm engine (junie-local-mixin).
set -euo pipefail
export JUNIE_SKIP_UPDATE_CHECK=1
exec /home/agent/.local/bin/junie --model custom:local-qwen3.6-27b-4bit "$@"
SCRIPT

FROM scratch
COPY --from=build /out /
