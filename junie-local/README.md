# junie-local

[Junie](https://junie.jetbrains.com/) in an `sbx` microVM, wired to the
`junie-mlx-vlm` engine running on the host — the one JetBrains installs as
[Junie Local](https://junie.jetbrains.com/local).

Junie is baked into the image at build time, so the sandbox fetches nothing at
creation and exactly one host is reachable from inside it:

```yaml
permissions:
  network:
    allow:
      - localhost:19239
```

No cloud model provider, no package registry, no git forge — under a
deny-all default network policy.

## Prerequisites

[Junie Local](https://junie.jetbrains.com/local) installed and serving on the
host. This is the model runner only — install *just* that, not the Junie CLI:
the CLI already runs inside the sandbox, baked into the image at build time.

```console
curl -fsSL https://raw.githubusercontent.com/jetbrains-junie/junie/main/local/install.sh | bash
```

The documented entry point, `junie.jetbrains.com/install.sh --local-model`,
always installs the CLI alongside the runner. The URL above is what that
installer runs internally for the runner-only path (its `LOCAL_MODEL_URL`
variable).

```console
~/.local/share/junie-local/current/serverctl.sh status
```

Requires macOS 26+, Apple M5 or newer, 40 GB RAM (60 GB recommended).

Tested against macOS 26.6.1 on Apple M5 Pro, Junie 26.8.24 (2929.5), engine
0.2.2, sbx v0.38.0.

## Bake the image

The kit boots `junie-local-image:latest`, which you build yourself:

```console
docker build -t junie-local-image:latest .
```

`sbx run` reads from `sbx`'s own image store, not Docker's — load it before
running the kit:

```console
docker save junie-local-image:latest -o junie-local-image.tar
sbx template load junie-local-image.tar
docker image rm junie-local-image:latest
rm junie-local-image.tar
```

`docker image rm` / `rm` are optional cleanup; redo the whole cycle on every rebuild.

This repo redistributes nothing — the Dockerfile only fetches Junie from
JetBrains' own installer at build time, on your machine. The **image you
build does** contain JetBrains' proprietary binary, so **never push it to a
registry**; use is subject to the JetBrains AI Service Terms of Service.
Rebuild to update; the shim's self-updater is disabled inside the sandbox.

## Run

Register the engine's bearer token in `sbx`'s secret store — this is the
service name (`junie-local`), not the `apiKey.name` env var:

```console
sbx secret set junie-local
Enter secret: <paste the value of .api_key from ~/.local/share/junie-local/server-config.json>
```

Then start the sandbox:

```console
sbx run --kit ./junie-local junie-local ~/my-project
```

The token stays on the host. The kit declares it as a proxy-managed credential,
so the sandbox proxy injects `Authorization: Bearer …` on requests to the engine
and the container never sees the value.

## How it reaches the host

The engine binds `127.0.0.1:19239` and stays there. The sandbox proxy translates
`host.docker.internal` to `localhost` before forwarding, so:

- the model profile points at `http://host.docker.internal:19239/v1/chat/completions`
- the allow-list entry is `localhost:19239`, the translated address

Nothing on the host needs reconfiguring, and the engine is never exposed beyond
loopback.

## Verify

```console
$ sbx kit validate ./junie-local
$ sbx kit inspect  ./junie-local
```

Smoke test inside a sandbox:

```console
> say hi
```

A response from the local engine (no cloud provider is reachable to answer
instead) confirms the image, credential injection, and network policy are
all wired correctly. `sbx policy log <sandbox>` under a `deny-all` policy is
the fastest way to see exactly what got through if it doesn't.
