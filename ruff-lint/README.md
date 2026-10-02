# ruff-lint

A mixin that installs [Ruff](https://docs.astral.sh/ruff/) and adds a shared
user-level `ruff.toml`, so every sandbox starts with the same lint rules.

## Usage

```console
$ sbx run docker.io/docker/sbx-kit-claude:2.1.296 --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" ~/my-project
```

The binary is copied straight out of Astral's own published image
(`ghcr.io/astral-sh/ruff`) at publish time — no build step of our own, and
(since that binary is statically linked) no dependency on glibc vs. musl
either.

## What it adds

- `ruff` CLI (pinned version, default `0.17.1`; override with
  `--kit-arg ruff-lint.version=<x.y.z>`) available on `PATH`
- `~/.config/ruff/ruff.toml` with a shared line-length and lint selection,
  used only when the project has no Ruff config of its own

## Customize

Edit the `ruff.toml` content in `ruff-lint.yaml` before loading the kit to
change the shared rules. To preview the spec:

```console
$ sbx kit inspect "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint"
```
