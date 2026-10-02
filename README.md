# sbx-kits

My personal collection of kits for
[Docker Sandboxes (`sbx`)](https://docs.docker.com/ai/sandboxes/).

> Based on [dvdksn/kits-cookbook](https://github.com/dvdksn/kits-cookbook) — thanks [@dvdksn](https://github.com/dvdksn)!
> The v3 layout, several kits and the CI follow
> [docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib); see the
> `NOTICE.md` in each directory that carries its code.

> [!IMPORTANT]
> **Experimental: Sandbox Kit v3.** Every kit here uses the v3 kit format,
> which needs **`sbx` v0.45.0 or newer**. v3 kits can't be combined with v1/v2
> kits, so commands from before the migration (`sbx run claude-safe --kit
> ...#dir=claude-safe`) no longer work; use the forms below. The format and
> CLI are still changing. The kit pages on docs.docker.com still describe the
> older `spec.yaml` format.

## My base Claude

My default starting point — Claude Code in approval mode with my base rules
and skills:

```console
$ sbx run "git+https://github.com/alakae/sbx-kits.git#dir=claude-safe" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-rules" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" \
    .
```

## What a kit is

Each top-level directory holding a `<kit>/<kit>.yaml` is a kit:

```text
<kit>/
├── <kit>.yaml           # the descriptor; first line: # syntax=docker/sandbox-kit:3
├── <kit>.dockerfile     # the recipe (optional for a mixin), found by filename stem
├── <kit>-context.md     # text added to the agent's CLAUDE.md / AGENTS.md
├── files/               # assets the recipe COPYs in
└── README.md
```

There are two kinds:

| `kind:` | What it is | How you use it |
|---|---|---|
| `workload` | The whole environment, including the agent and its launch command. Always has a recipe. | First positional argument of `sbx run`, where a built-in agent name would go. |
| `mixin` | Something layered onto a workload: tools, files, credentials, network access, hooks. | `--kit`, repeatable. |

The descriptor declares what the kit needs as typed capabilities (network
policy, credentials, lifecycle hooks, agent context). The build validates it:
if `docker buildx build -f <kit>.yaml` succeeds, the descriptor is well-formed.

## Using a kit

A workload goes first; mixins compose onto it with `--kit`:

```console
$ sbx run "git+https://github.com/alakae/sbx-kits.git#dir=claude-safe" ~/my-project
$ sbx run "git+https://github.com/alakae/sbx-kits.git#dir=claude-safe" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" \
    ~/my-project
```

Mixins also compose onto other v3 workloads — but not onto a bare built-in
agent name (`claude`, `shell`, `opencode`, ...). A bare name selects `sbx`'s
legacy v2 kit for that agent, and v2 kits can't combine with v3 `--kit`
mixins. The positional slot always needs a real v3 workload: one of this
repo's own, or a published one such as Docker's
`docker.io/docker/sbx-kit-shell:1.0.0`:

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=nix" ~/my-project
```

Pin to a revision with `&ref=<branch|tag|commit>`, and quote the URL (`&`
starts a background job in some shells):

```console
$ sbx run "git+https://github.com/alakae/sbx-kits.git#ref=main&dir=claude-safe" ~/my-project
```

From a local clone, use explicit paths (`./kit`, not `kit`, which `sbx`
would read as an agent name):

```console
$ sbx run ./claude-safe --kit ./base-rules --kit ./base-skills .
```

`sbx` builds a local or git kit on first use; there is no separate build or
`sbx template load` step.

## Kit index

### Workloads

| Kit | Mixin sibling | What it is |
|---|---|---|
| [`claude-safe`](./claude-safe) | [`claude-safe-mixin`](./claude-safe-mixin) | Claude Code in approval mode: no bypass mode, no auto mode, no Remote Control at startup (managed policy) |
| [`claude-ollama`](./claude-ollama) | [`claude-ollama-mixin`](./claude-ollama-mixin) | Claude Code routed to a local Ollama instance instead of the Anthropic API |
| [`junie-local`](./junie-local) | [`junie-local-mixin`](./junie-local-mixin) | Junie CLI wired to the Junie Local MLX engine on the host, baked into the image |

Each mixin sibling carries the same wiring as an overlay, for layering onto a
base you want to keep.

### Standalone mixins

| Kit | Requires | What it does |
|---|---|---|
| [`base-rules`](./base-rules) | — | My base Claude Code rules, copied into the workspace's `.claude/rules/` |
| [`base-skills`](./base-skills) | — | My base agent skills (Claude Code, OpenCode), copied into the workspace's `.claude/skills/` |
| [`cloudscale-api`](./cloudscale-api) | — | Access to `api.cloudscale.ch` with Bearer token injection |
| [`devbox`](./devbox) | `nix` | Devbox on top of Nix; inits `devbox.json` in the workspace at start |
| [`nix`](./nix) | `deb/apt` | Nix in single-user mode; makes `nix-shell` available to the agent |
| [`ruff-lint`](./ruff-lint) | — | Ruff plus a shared user-level `ruff.toml` |

`requires` is checked when kits are composed: sbx refuses a composition in
which nothing provides a required name.

## Validating a kit

`sbx kit validate` can't load v3 source kits, so the build is the check. From
a clone:

```console
$ cd ruff-lint && docker buildx build . -f ruff-lint.yaml --output type=cacheonly
$ sbx kit inspect ./ruff-lint     # resolves the kit the way sbx will (needs sbx running)
```

`scripts/test-kit.sh <kit>` runs the build plus `shellcheck` and `yamllint`;
add `--inspect` to also run `sbx kit inspect`:

```console
$ uv tool install yamllint
$ ./scripts/test-kit.sh ruff-lint
$ ./scripts/test-kit.sh --inspect ruff-lint
```

CI ([`.github/workflows/kit-tests.yml`](.github/workflows/kit-tests.yml)) runs
the same script for every kit on each push, pull request, and weekly on a
schedule (to catch drift in base images and upstream installers). `sbx kit
inspect` and running the kits in a real sandbox need `/dev/kvm`, which
GitHub-hosted runners don't provide, so both are done by hand.

## License

MIT. See [LICENSE](./LICENSE). Directories that carry a `NOTICE.md` contain
material from [docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib)
or other upstream projects under their own license (Apache-2.0 or MIT); the
license text is in the `LICENSE-*` file beside each `NOTICE.md`.
