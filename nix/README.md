# nix

A v3 mixin that adds [Nix](https://nixos.org/) in single-user mode,
making `nix-shell` and `nix shell` available to the agent. Nix and the
nixpkgs it resolves are pinned by one nixpkgs commit.

## Usage

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=nix" ~/my-project
```

Standalone: it needs no other kit. Do not combine it with the
[`devbox`](../devbox) mixin, which brings its own Nix and declares a
conflict with this kit. If you want devbox, use that kit alone.

## What it adds

- The Nix CLI (`nix`, `nix-shell`, `nix-store`, …) linked into
  `/usr/local/bin`, built from nixpkgs on `FROM scratch` — the shape of
  Docker's
  [`gh` example](https://github.com/docker/sandbox-kit-spec/tree/main/examples/gh).
- A **registered**, agent-owned store: `nix copy` writes the store paths
  and Nix's database at build time and `/nix` belongs to uid 1000, so the
  agent can install packages and `nix-collect-garbage` keeps what the kit
  shipped (GC roots protect Nix and the pinned nixpkgs). No setup hook.
- The pinned nixpkgs source, registered as the system flake registry's
  `nixpkgs` and as `nix-path`: `nix-shell -p hello` and
  `nix shell nixpkgs#hello` resolve offline to the pin, with no channel.
- Binary cache (`cache.nixos.org`, reads only) allowed at runtime.

## Bumping

Edit the nixpkgs commit in `nix.dockerfile`, rebuild, and update
`provides` in `nix.yaml` and `EXPECTED_NIX_VERSION` in `nix.dockerfile` (the build
fails while they disagree with the pin) from `docker run --rm <image>` (it prints the
Nix version).

## Build and verify

```console
$ cd nix
$ docker buildx build . -f nix.yaml --output type=cacheonly   # validate
$ docker buildx build . -f nix.yaml -t nix-kit:dev --load      # build
$ docker run --rm nix-kit:dev                                  # nix (Nix) 2.34.8
```

Smoke test inside a sandbox:

```console
$ nix-shell -p hello --run hello
Hello, world!
```
