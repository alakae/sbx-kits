# devbox

A v3 mixin that adds [Devbox](https://www.jetify.com/devbox) for
per-project reproducible development environments managed via
`devbox.json`. Devbox and the Nix it drives are pinned by one nixpkgs
commit.

## Usage

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=devbox" ~/my-project
```

Standalone: it needs no other kit. Devbox cannot work without Nix, so
this overlay carries its own, and it declares `conflicts: ["nix"]`, so
composing it with the [`nix`](../nix) mixin is refused rather than
breaking at runtime.

## What it adds

- `devbox` and the Nix CLI it drives, linked into `/usr/local/bin`,
  built from nixpkgs on `FROM scratch` — the shape of Docker's
  [`gh` example](https://github.com/docker/sandbox-kit-spec/tree/main/examples/gh).
- A **registered**, agent-owned store (`nix copy` at build time, `/nix`
  owned by uid 1000), so devbox can install packages and
  `nix-collect-garbage` keeps devbox and its Nix. No store setup hook.
- An install hook that pre-warms packages when the workspace already has
  a `devbox.json`. It runs in your workspace, so like any `devbox install`
  it writes `devbox.lock` and a `.devbox/` directory there (on the host),
  and it adds the download time to sandbox creation — about 70 s for
  `hello` on a fresh sandbox.
- Network access for devbox's package resolution: `cache.nixos.org`,
  `api.github.com` / `github.com` / `codeload.github.com` (nixpkgs
  lookup and archive) and `search.devbox.sh`, all reads only. Devbox
  resolves its own nixpkgs per project.

## Bumping

Edit the nixpkgs commit in `devbox.dockerfile`, rebuild, and update
`provides` in `devbox.yaml` and `EXPECTED_DEVBOX_VERSION` in `devbox.dockerfile` (the build
fails while they disagree with the pin) from `docker run --rm <image>` (it prints the
devbox version).

## Build and verify

```console
$ cd devbox
$ docker buildx build . -f devbox.yaml --output type=cacheonly   # validate
$ docker buildx build . -f devbox.yaml -t devbox-kit:dev --load   # build
$ docker run --rm devbox-kit:dev                                  # 0.17.5
```

Smoke test inside a sandbox:

```console
$ devbox init
$ devbox add hello
$ devbox run -- hello
Hello, world!
```
