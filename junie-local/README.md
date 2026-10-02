# junie-local

[Junie](https://junie.jetbrains.com/) in an `sbx` microVM, wired to the
`junie-mlx-vlm` engine running on the host — the one JetBrains installs as
[Junie Local](https://junie.jetbrains.com/local).

Junie is baked into the image at build time, so the sandbox fetches nothing at
creation and exactly one host is reachable from inside it:

```yaml
- type: com.docker.sandbox/network-policy@1
  config:
    runtime:
      allow:
        - localhost:19239   # the host's loopback; see "How it reaches the host"
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

The v2 kit was tested against macOS 26.6.1 on Apple M5 Pro, Junie 26.8.24
(2929.5), engine 0.2.2, sbx v0.38.0. The v3 kit needs sbx v0.45.0 or newer.

## Bake the image

`sbx run ./junie-local` builds the image from
[`junie-local.dockerfile`](./junie-local.dockerfile) on your machine the first
time, and again whenever the recipe changes. There is no separate
`docker build` / `sbx template load` step.

This repo redistributes nothing — the recipe only fetches Junie from
JetBrains' own installer at build time, on your machine. The **image you
build does** contain JetBrains' proprietary binary, so **never push it to a
registry**; use is subject to the JetBrains AI Service Terms of Service.
The shim's self-updater is disabled inside the sandbox. Junie is pinned by
the kit's `version` argument (Junie's build number, default `3659.7` =
26.10.12); to update, bump the default in `junie-local.yaml` and
`junie-local.dockerfile`, or build with `--kit-arg version=<build>`. Builds
are listed in
[update-info.jsonl](https://raw.githubusercontent.com/jetbrains-junie/junie/main/update-info.jsonl).

## Run

Store the engine's bearer token in `sbx`'s secret store — this is the
service name (`junie-local`), not the `apiKey.name` env var:

```console
sbx secret set junie-local
Enter secret: <paste the value of .api_key from ~/.local/share/junie-local/server-config.json>
```

Then approve this kit's use of it. `sbx` asks the first time you run the kit
interactively; for `--detach`, scripts or CI, write the binding yourself in
`~/.config/sbx/credentials.yaml` (merge it into the file if one exists):

```yaml
bindings:
  junie-local:
    apiKey:
      domains: ["localhost:19239"]
```

Without a binding `sbx` starts the sandbox anyway, prints `no binding
authorizes junie-local — the credential was not injected`, and every request
to the engine fails authentication.

Then start the sandbox:

```console
sbx run ./junie-local ~/my-project
```

The token stays on the host. The kit declares it as a proxy-managed credential,
so the sandbox proxy injects `Authorization: Bearer …` on requests to the engine
and the container never sees the value.

## How it reaches the host

The engine binds `127.0.0.1:19239` and stays there. Inside the sandbox
`localhost` is the sandbox itself, so Junie's model profile points at
`http://host.docker.internal:19239/v1/chat/completions`. The sandbox proxy
forwards `host.docker.internal` to the host's `localhost`, and it applies the
network policy and credential injection to the **rewritten** address. So the
allow entry and the credential's inject domain both name `localhost:19239`;
with `host.docker.internal:19239` there, requests are held as "Approval
required for localhost:19239" and the token is never injected (verified with
sbx v0.49.1).

Nothing on the host needs reconfiguring, and the engine is never exposed beyond
loopback.

The kit's instructions go to `~/.junie/AGENTS.md` inside the sandbox, which
is where Junie reads user-level guidelines; a project's own `AGENTS.md` or
`.junie/guidelines.md` still applies on top.

## Verify

```console
$ docker buildx build ./junie-local -f ./junie-local/junie-local.yaml --output type=cacheonly
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
