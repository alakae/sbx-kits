# syntax=docker/dockerfile:1
# Content recipe for the `junie-local` workload kit.
#
# Bakes Junie CLI into the sandbox image so nothing is fetched at sandbox
# creation and the kit's network allow-list can stay at a single entry.
#
# MIGRATION NOTE: this is the v2 kit's Dockerfile, renamed to the stem
# junie-local.dockerfile so the descriptor beside it finds it. In v2 you built
# it yourself and loaded it with `sbx template load`; in v3 `sbx run
# ./junie-local` builds it from source on your machine, and the image never
# leaves the local builder unless you push it.
#
# This file redistributes nothing: it fetches Junie from JetBrains' own
# installer at build time, on your machine. Use is subject to the JetBrains AI
# Service Terms of Service. Do not push the resulting image to a public registry.

FROM docker/sandbox-templates:shell-docker

# install.sh aborts early on Linux without unzip (see require_extractor).
USER root
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*

# Install as the agent user so the tree lands in /home/agent/.local, where the
# shim expects it. Running this as root would install into /root and the
# entrypoint would not find it.
USER agent

# The installer appends this to a shell profile, which an exec'd entrypoint
# never sources — set it explicitly so `junie` resolves.
ENV PATH="/home/agent/.local/bin:${PATH}"

# The shim self-updates by re-running the installer over the network. Off.
ENV JUNIE_SKIP_UPDATE_CHECK=1

RUN curl -fsSL https://junie.jetbrains.com/install.sh | bash

# Fail the build rather than the sandbox if the install did not take. This also
# forces the shim's one-time bootstrap now instead of on first launch.
RUN junie --version

# MIGRATION NOTE: v2's `sandbox.entrypoint`, moved into the image config; the
# v3 descriptor carries none. Declaring ENTRYPOINT also clears the base's
# inherited CMD (`bash`), so the launch is exactly this argv.
ENTRYPOINT ["junie", "--model", "custom:local-qwen3.6-27b-4bit"]
