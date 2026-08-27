# Bakes Junie CLI into the sandbox image so nothing is fetched at sandbox
# creation and the kit's network allow-list can stay at a single entry.
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
