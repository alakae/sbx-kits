# syntax=docker/dockerfile:1
# Content recipe for the `junie-local` workload kit.
#
# Bakes Junie CLI into the sandbox image so nothing is fetched at sandbox
# creation and the kit's network allow-list can stay at a single entry.
#
# `sbx run ./junie-local` builds it from source on your machine, and the image
# never leaves the local builder unless you push it.
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

# The Junie build to install; junie-local.yaml's `version` arg drives it.
# Build-time only: an ARG does not reach the running sandbox, where the
# shim would otherwise read JUNIE_VERSION too.
ARG JUNIE_VERSION=3813.10
RUN curl -fsSL https://junie.jetbrains.com/install.sh | JUNIE_VERSION="${JUNIE_VERSION}" bash

# Fail the build rather than the sandbox if the install did not take, or took
# a different build than `provides` claims. This also forces the shim's
# one-time bootstrap now instead of on first launch.
RUN junie --version | tee /tmp/junie-version \
 && grep -q "(${JUNIE_VERSION})" /tmp/junie-version \
 && rm /tmp/junie-version

# The launch command lives in the image config; the descriptor carries none.
# Declaring ENTRYPOINT also clears the base's inherited CMD (`bash`), so the
# launch is exactly this argv.
ENTRYPOINT ["junie", "--model", "custom:local-qwen3.6-27b-4bit"]
