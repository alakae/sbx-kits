# devbox

A mixin that installs [Devbox](https://www.jetify.com/devbox) on top of Nix,
enabling per-project reproducible development environments managed via
`devbox.json`.

Designed to be stacked on top of the `nix` mixin kit.

## Usage

Stack with the `nix` kit:

```console
$ sbx run shell --kit "git+https://github.com/alakae/sbx-kits.git#dir=nix" \
                --kit "git+https://github.com/alakae/sbx-kits.git#dir=devbox"
```

Or from a local clone:

```console
$ sbx run shell --kit ./nix/ --kit ./devbox/
```

## What it adds

- `devbox` CLI on `PATH` (installed to `/usr/local/bin`)
- Network access to Jetify download endpoints (install-time) and GitHub +
  nixpkgs infrastructure (runtime package resolution)

Note: Devbox performs a self-update to its cached version on first use
(`devbox init`, `devbox add`, etc.), which downloads a release from GitHub.
The required domains are included in the network policy.

## Verify

```console
$ sbx kit validate ./devbox
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
