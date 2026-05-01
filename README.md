# sbx-kits

My personal collection of [kits](https://docs.docker.com/ai/sandboxes/customize/kits/)
for [Docker Sandboxes (`sbx`)](https://docs.docker.com/ai/sandboxes/).

> Based on [dvdksn/kits-cookbook](https://github.com/dvdksn/kits-cookbook) — thanks [@dvdksn](https://github.com/dvdksn)!

## Kits

| Kit | Kind | What it does |
| --- | ---- | ------------ |
| [`base-rules`](./base-rules) | mixin | My base Claude Code behavioral rules used across many different repos |
| [`base-skills`](./base-skills) | mixin | My base Claude Code skills used across many different repos |
| [`ruff-lint`](./ruff-lint) | mixin | Installs Ruff and drops a shared `ruff.toml` into the workspace |
| [`claude-ollama`](./claude-ollama) | agent | Fork of the built-in `claude` agent wired to a local Ollama instance instead of the Anthropic API |
| [`claude-safe`](./claude-safe) | agent | Fork of the built-in `claude` agent that runs without `--dangerously-skip-permissions` |

## Loading a kit

Each directory is a self-contained kit. Load one with the Git URL form,
passing `#dir=<kit-name>` to point at a subdirectory:

```console
$ sbx run claude --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" ~/my-project
```

Pin to a revision with `&ref=<branch|tag|commit>`:

```console
$ sbx run claude --kit "git+https://github.com/alakae/sbx-kits.git#ref=v1.0&dir=ruff-lint" ~/my-project
```

Quote the URL — `&` starts a background job in some shells.

Stack several kits on the same sandbox by repeating `--kit`:

```console
$ sbx run claude \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" \
    ~/my-project
```

## Validating a kit

If you're iterating on one of these, validate before loading:

```console
$ git clone https://github.com/alakae/sbx-kits.git
$ sbx kit validate ./sbx-kits/ruff-lint
$ sbx kit inspect  ./sbx-kits/ruff-lint
```

## License

MIT. See [LICENSE](./LICENSE).
