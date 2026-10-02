# ruff-lint

A mixin that installs [Ruff](https://docs.astral.sh/ruff/) and adds a shared
user-level `ruff.toml`, so every sandbox starts with the same lint rules.

## Usage

```console
$ sbx run docker.io/docker/sbx-kit-claude:2.1.296 --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" ~/my-project
```

The binary comes from Ruff's PyPI musllinux wheel, installed in a build
stage at publish time. It is statically linked, so it has no dependency on
glibc vs. musl either. Astral's own image (`ghcr.io/astral-sh/ruff`) is not
used: its aarch64 binary aborts with "Unsupported system page size" on the
16K-page kernel of sbx VMs on Apple Silicon.

## What it adds

- `ruff` CLI (pinned version, default `0.17.1`; override with
  `--kit-arg ruff-lint.version=<x.y.z>`) available on `PATH`
- `~/.config/ruff/ruff.toml` with a shared line-length and lint selection,
  used only when the project has no Ruff config of its own

The shared config is written to `/home/agent`, the SPEC-v3 §12 platform
floor, so a root-only workload such as the spec's `examples/alpine` refuses
the kit at sandbox creation ("failed to apply kit to sandbox").

## Customize

Edit the `ruff.toml` content in `ruff-lint.yaml` before loading the kit to
change the shared rules. To preview the spec:

```console
$ sbx kit inspect "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint"
```
