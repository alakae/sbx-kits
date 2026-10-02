# syntax=docker/dockerfile:1
# Devbox as a self-contained mixin. Devbox is a front-end to Nix and fails
# without one ("unable to source Nix profile"), so this overlay carries
# its own instead of requiring the nix mixin. Shaped on Docker's gh
# example (sandbox-kit-spec, examples/gh/gh.dockerfile), with the same
# single deviation as the nix mixin: `nix copy` writes a registered store
# owned by the agent (uid 1000) at build time, because devbox installs
# packages into it at runtime.
#
# Standalone by design: this overlay owns /nix and /etc/nix/nix.conf, and
# devbox.yaml declares a conflict with the nix mixin, which does the same.
FROM nixos/nix:2.35.2 AS build
WORKDIR /src
# The pinned commit is the version authority for devbox and its Nix;
# `provides` in devbox.yaml reports what it resolves to. Same pin as the
# nix mixin.
COPY <<'EOF' flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f";
  outputs = { self, nixpkgs }:
    let
      forAll = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ]
        (system: f nixpkgs.legacyPackages.${system});
    in {
      packages = forAll (pkgs: {
        default = pkgs.devbox;
        devbox = pkgs.devbox;
        nix = pkgs.nix;
      });
    };
}
EOF
RUN nix --extra-experimental-features 'nix-command flakes' build .#devbox --out-link devbox \
 && nix --extra-experimental-features 'nix-command flakes' build .#nix --out-link nix
# `provides: ["devbox@…"]` in devbox.yaml is a claim about this content, so
# the build enforces it: bump EXPECTED_DEVBOX_VERSION together with that line
# whenever the pin moves, or the build fails here.
ARG EXPECTED_DEVBOX_VERSION=0.17.5
RUN test "$(./devbox/bin/devbox version)" = "${EXPECTED_DEVBOX_VERSION}" \
 || { echo "pin resolves to devbox $(./devbox/bin/devbox version), expected ${EXPECTED_DEVBOX_VERSION}: update devbox.yaml provides" >&2; exit 1; }
# Registered, not just copied (see nix.dockerfile in the nix mixin).
RUN nix --extra-experimental-features 'nix-command flakes' copy --no-check-sigs \
      --to /out "$(readlink -f devbox)" "$(readlink -f nix)"
RUN set -eu; \
    devbox=$(readlink -f devbox); nix=$(readlink -f nix); \
    mkdir -p /out/usr/local/bin /out/etc/nix /out/nix/var/nix/gcroots /out/nix/var/nix/profiles; \
    # devbox looks up `nix` on PATH, so both go into /usr/local/bin.
    ln -s "$devbox/bin/devbox" /out/usr/local/bin/devbox; \
    for b in "$nix"/bin/*; do ln -s "$b" /out/usr/local/bin/; done; \
    ln -s "$devbox" /out/nix/var/nix/gcroots/sbx-devbox; \
    ln -s "$nix" /out/nix/var/nix/gcroots/sbx-devbox-nix; \
    # Single-user mode. Devbox pins nixpkgs per project, so no registry and
    # no nix-path here.
    printf '%s\n' \
      'build-users-group =' \
      'sandbox = false' \
      'experimental-features = nix-command flakes' \
      > /out/etc/nix/nix.conf; \
    chown -R -h 1000:1000 /out/nix

# The overlay: devbox, its Nix, and a registered, agent-owned store.
FROM scratch
COPY --from=build /out /
ENTRYPOINT ["devbox"]
CMD ["version"]
