# devbox

A mixin that installs [Devbox](https://www.jetify.com/devbox) on top of Nix,
enabling per-project reproducible development environments managed via
`devbox.json`.

Requires the `nix` mixin kit (`requires: ["nix"]`).

## Usage

Stack with the `nix` kit:

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=nix" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=devbox"
```

Or from a local clone:

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 --kit ./nix/ --kit ./devbox/
```

## What it adds

- `devbox` CLI on `PATH` (installed to `/usr/local/bin`)
- `devbox init` and `devbox install` run in the workspace each time the
  sandbox starts (in the background, so the agent may start before they finish)
- Network access to Jetify download endpoints (install-time) and GitHub +
  nixpkgs infrastructure (runtime package resolution)

Note: Devbox performs a self-update to its cached version on first use
(`devbox init`, `devbox add`, etc.), which downloads a release from GitHub.
The required domains are included in the network policy.

## Verify

```console
$ docker buildx build ./devbox -f ./devbox/devbox.yaml --output type=cacheonly
$ sbx kit inspect  ./devbox
```

Smoke test inside a sandbox (stacked on `nix`):

```console
$ devbox version
$ devbox init
$ devbox add nodejs@latest
$ devbox shell
$ node --version
```
