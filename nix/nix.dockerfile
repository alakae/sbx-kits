FROM debian:trixie-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils \
    && rm -rf /var/lib/apt/lists/*
RUN groupadd --gid 1000 agent \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash agent \
    && mkdir -m 0755 /nix && chown agent:agent /nix

USER agent
ENV USER=agent HOME=/home/agent
RUN curl --proto '=https' --tlsv1.2 -fsSL https://nixos.org/nix/install -o /tmp/install-nix.sh \
    && sh /tmp/install-nix.sh --no-daemon \
    && rm /tmp/install-nix.sh

FROM scratch
COPY --from=build --chown=1000:1000 /nix /nix
# Only the files the Nix installer itself created under /home/agent — not the
# whole directory. useradd --create-home also seeds Debian's skeleton
# dotfiles (.bashrc, .profile, .bash_logout) there, and copying /home/agent
# wholesale would ship those too, overwriting the composed workload's own
# versions (and resetting /home/agent's own mode to this stage's 0700) when
# this mixin layers on top of it.
COPY --from=build --chown=1000:1000 /home/agent/.nix-profile /home/agent/.nix-profile
COPY --from=build --chown=1000:1000 /home/agent/.nix-defexpr /home/agent/.nix-defexpr
COPY --from=build --chown=1000:1000 /home/agent/.nix-channels /home/agent/.nix-channels
COPY --from=build --chown=1000:1000 /home/agent/.cache/nix /home/agent/.cache/nix
COPY --from=build --chown=1000:1000 /home/agent/.local/state/nix /home/agent/.local/state/nix
