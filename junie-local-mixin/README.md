# junie-local-mixin

[`junie-local`](../junie-local) as a **mixin**: Junie CLI, a `junie-local`
command that starts it against the `junie-mlx-vlm` engine on your host, the
engine's egress and its bearer token, all layered onto a base you want to keep
instead of being the whole environment.

## Usage

Prerequisites are the same as for [`junie-local`](../junie-local#prerequisites):
Junie Local serving on the host, and its token stored once with
`sbx secret set junie-local`.

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 --kit ./junie-local-mixin ~/my-project
$ sbx run ./claude-safe --kit "git+https://github.com/alakae/sbx-kits.git#dir=junie-local-mixin" ~/my-project
```

Inside the sandbox, start Junie with the local model:

```console
$ junie-local
```

`junie-local` runs `junie --model custom:local-qwen3.6-27b-4bit`. Plain `junie`
is on `PATH` too.

## How it differs from the workload

- No entrypoint: the base keeps its own launch command, which is why the
  overlay adds the `junie-local` command instead.
- The overlay carries only what the Junie installer creates
  (`~/.local/bin/junie` and `~/.local/share/junie`), plus a
  `/usr/local/bin/junie` link and an `/etc/profile.d` export of
  `JUNIE_SKIP_UPDATE_CHECK=1`. `junie-local` sets that variable itself.
- Egress unions with the base's: on a base with cloud hosts allowed, the
  sandbox is no longer limited to the local engine, even though Junie is
  still pointed at it. For the engine-only setup, use the workload.

Like the workload image, the overlay contains JetBrains' proprietary Junie
build. It is built on your machine; **never push it to a registry**.

Composing this mixin with the `junie-local` workload is refused: both provide
`junie-local`.

## Verify

```console
$ cd junie-local-mixin && docker buildx build . -f junie-local-mixin.yaml --output type=cacheonly
```
