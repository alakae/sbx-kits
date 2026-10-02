# syntax=docker/dockerfile:1
# Nix itself as a mixin: the agent gets nix-shell / nix shell and can fetch
# packages at runtime. Shaped on Docker's gh example (sandbox-kit-spec,
# examples/gh/gh.dockerfile): a nixos/nix build stage, the result on FROM
# scratch. It deviates in one place, because this store must stay
# writable: instead of copying the closure, `nix copy` writes a
# *registered* store (paths plus database) and the whole of /nix is owned
# by the agent (uid 1000) at build time — a single-user install without
# the curl | sh installer.
#
# Standalone by design: this overlay owns /nix and /etc/nix/nix.conf.
# The devbox mixin carries its own Nix the same way and declares a
# conflict with this kit, so the two are never composed together.
FROM nixos/nix:2.35.2 AS build
WORKDIR /src
# The pinned commit is the version authority for both the Nix binary and
# the nixpkgs the agent resolves packages from; `provides` in nix.yaml
# reports what it resolves to. Same pin as Docker's gh example.
COPY <<'EOF' flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f";
  outputs = { self, nixpkgs }:
    let
      forAll = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ]
        (system: f nixpkgs.legacyPackages.${system});
    in {
      packages = forAll (pkgs: { default = pkgs.nix; });
    };
}
EOF
RUN nix --extra-experimental-features 'nix-command flakes' build .
# `provides: ["nix@…"]` in nix.yaml is a claim about this content, so the
# build enforces it: bump EXPECTED_NIX_VERSION together with that line
# whenever the pin moves, or the build fails here.
ARG EXPECTED_NIX_VERSION=2.34.8
RUN test "$(./result/bin/nix --version)" = "nix (Nix) ${EXPECTED_NIX_VERSION}" \
 || { echo "pin resolves to $(./result/bin/nix --version), expected ${EXPECTED_NIX_VERSION}: update nix.yaml provides" >&2; exit 1; }
# The nixpkgs source tree the flake was locked to. Shipping it makes
# `nixpkgs` resolve to the pin offline: no channel, no GitHub at runtime.
RUN nix --extra-experimental-features 'nix-command flakes' eval --raw --impure \
      --expr '(builtins.getFlake "path:/src").inputs.nixpkgs.outPath' > /nixpkgs-path
# `nix copy` to a chroot store writes the paths *and* registers them in
# /out/nix/var/nix/db, which a plain cp of the closure would not. Without
# the registration Nix would not know the shipped paths and the garbage
# collector would treat them as garbage.
RUN nix --extra-experimental-features 'nix-command flakes' copy --no-check-sigs \
      --to /out "$(readlink -f result)" "$(cat /nixpkgs-path)"
RUN set -eu; \
    pkg=$(readlink -f result); nixpkgs=$(cat /nixpkgs-path); \
    mkdir -p /out/usr/local/bin /out/etc/nix /out/nix/var/nix/gcroots /out/nix/var/nix/profiles; \
    # Every Nix command on PATH by link, as gh's single link — no ENV PATH,
    # which would have to merge with the workload's.
    for b in "$pkg"/bin/*; do ln -s "$b" /out/usr/local/bin/; done; \
    # GC roots: nix-collect-garbage never deletes Nix or the pinned nixpkgs.
    ln -s "$pkg" /out/nix/var/nix/gcroots/sbx-nix; \
    ln -s "$nixpkgs" /out/nix/var/nix/gcroots/sbx-nix-nixpkgs; \
    # Single-user mode: no nixbld group, no build sandbox (the sandbox VM
    # is the boundary). nix-path makes `nix-shell -p` resolve <nixpkgs>
    # through the registry below, in config rather than an ENV NIX_PATH.
    printf '%s\n' \
      'build-users-group =' \
      'sandbox = false' \
      'experimental-features = nix-command flakes' \
      'flake-registry =' \
      'nix-path = nixpkgs=flake:nixpkgs' \
      > /out/etc/nix/nix.conf; \
    # System registry: `nixpkgs` means the pinned source shipped above.
    printf '{"version":2,"flakes":[{"from":{"type":"indirect","id":"nixpkgs"},"to":{"type":"path","path":"%s"}}]}\n' \
      "$nixpkgs" > /out/etc/nix/registry.json; \
    # The agent owns the store and the database. -h so the gc-root links
    # are re-owned themselves rather than having their targets chased.
    chown -R -h 1000:1000 /out/nix

# The overlay: a registered, agent-owned Nix store plus config.
FROM scratch
COPY --from=build /out /
ENTRYPOINT ["nix"]
CMD ["--version"]
