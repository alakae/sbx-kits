# ruff-lint

A mixin that installs [Ruff](https://docs.astral.sh/ruff/) and drops a shared
`ruff.toml` into the workspace, so every sandbox starts with the same lint
rules.

## Usage

```console
$ sbx run claude --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" ~/my-project
```

The built-in `claude`, `codex`, and `gemini` agent templates already include
`uv`, so the install command works without bootstrapping it.

## What it adds

- `ruff` CLI available on `PATH`
- `ruff.toml` in the workspace with a shared line-length and lint selection

## Customize

Edit `files/workspace/ruff.toml` before loading the kit to change the shared
rules. To preview the spec:

```console
$ sbx kit inspect "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint"
```
