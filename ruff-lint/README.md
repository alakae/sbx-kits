# ruff-lint

A mixin that installs [Ruff](https://docs.astral.sh/ruff/) and adds a shared
user-level `ruff.toml`, so every sandbox starts with the same lint rules.

## Usage

```console
$ sbx run ./claude-safe --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" ~/my-project
```

Ruff is built once, at publish time, into a standalone binary — the composed
workload doesn't need `uv`, Python, or PyPI access.

## What it adds

- `ruff` CLI (pinned version, default `0.8.4`; override with
  `--kit-arg ruff-lint.version=<x.y.z>`) available on `PATH`
- `~/.config/ruff/ruff.toml` with a shared line-length and lint selection,
  used only when the project has no Ruff config of its own

## Customize

Edit the `ruff.toml` content in `ruff-lint.yaml` before loading the kit to
change the shared rules. To preview the spec:

```console
$ sbx kit inspect "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint"
```
