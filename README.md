# sbx-kits

My personal collection of kits for
[Docker Sandboxes (`sbx`)](https://docs.docker.com/ai/sandboxes/).

> Based on [dvdksn/kits-cookbook](https://github.com/dvdksn/kits-cookbook) — thanks [@dvdksn](https://github.com/dvdksn)!
> The v3 layout, several kits and the CI follow
> [docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib); see the
> `NOTICE.md` in each directory that carries its code.

> [!IMPORTANT]
> **Experimental: Sandbox Kit v3.** Every kit here uses the v3 kit format,
> which needs **`sbx` v0.45.0 or newer**. The format and CLI are still
> changing.

## My base Claude

My default starting point — Claude Code in approval mode with my base rules
and skills, layered onto the published Claude Code workload:

```console
$ sbx run docker.io/docker/sbx-kit-claude:2.1.296 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=claude-safe-mixin" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-rules" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" \
    .
```

`sbx` only installs kits from sources in its `kit.allowedSources` setting,
which allows `docker.io/` alone by default, so the `git+https://…` kits here
are refused until you add this repository once:

```console
$ sbx settings set kit.allowedSources '["docker.io/","github.com/alakae/"]'
```

Kits that inject a credential (`cloudscale-api`, `junie-local`) also need
an approved binding before an unattended run; see their READMEs.

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
$ sbx run ./junie-local ~/my-project
$ sbx run ./claude-ollama --kit ./claude-safe-mixin ~/my-project
$ sbx run docker.io/docker/sbx-kit-claude:2.1.296 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" \
    ~/my-project
```

Mixins also compose onto other v3 workloads — but not onto a bare built-in
agent name (`claude`, `shell`, `opencode`, ...), which `sbx` refuses to
combine with these `--kit` mixins. The positional slot always needs a v3
workload: one of this repo's own, or a published one such as Docker's
`docker.io/docker/sbx-kit-shell:1.0.0`:

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=nix" ~/my-project
```

Pin to a revision with `&ref=<branch|tag|commit>`, and quote the URL (`&`
starts a background job in some shells):

```console
$ sbx run "git+https://github.com/alakae/sbx-kits.git#ref=main&dir=junie-local" ~/my-project
```

From a local clone, use explicit paths (`./kit`, not `kit`, which `sbx`
would read as an agent name):

```console
$ sbx run docker.io/docker/sbx-kit-claude:2.1.296 \
    --kit ./claude-safe-mixin --kit ./base-rules --kit ./base-skills .
```

`sbx` builds a local or git kit on first use; there is no separate build
step.

All kits here use `agent-context@1` for the text they add to the agent's
instructions. `agent-context@2` exists in the spec, but `sbx` v0.49.1 rejects
it, and the published workloads declare @1, which can't be combined with @2.

## Kit index

### Workloads

| Kit | What it is |
|---|---|
| [`claude-ollama`](./claude-ollama) | Claude Code routed to a local Ollama instance on the host; grants no Anthropic host. Also provides `claude`, so `claude-safe-mixin` composes onto it |
| [`junie-local`](./junie-local) | Junie CLI wired to the Junie Local MLX engine on the host, baked into the image |

### Standalone mixins

| Kit | Requires | What it does |
|---|---|---|
| [`base-rules`](./base-rules) | — | My base Claude Code rules, delivered via `agent-context@1` (indexed from `~/.claude/CLAUDE.md`; not in the prompt until the agent opens the file) |
| [`base-skills`](./base-skills) | — | My base agent skills (Claude Code, OpenCode), exposed in the agent's own skill directory |
| [`claude-safe-mixin`](./claude-safe-mixin) | `claude` | Claude Code in approval mode (managed policy): starts in Manual mode, no bypass mode, auto mode only when you pick it, only managed permission rules count, no Remote Control at startup |
| [`cloudscale-api`](./cloudscale-api) | — | Access to `api.cloudscale.ch` with Bearer token injection |
| [`devbox`](./devbox) | — | Devbox with its own Nix, pinned by nixpkgs commit; pre-warms an existing `devbox.json` at install |
| [`nix`](./nix) | — | Nix in single-user mode, pinned by nixpkgs commit; makes `nix-shell` / `nix shell` available to the agent |
| [`ruff-lint`](./ruff-lint) | — | Ruff (static binary, any base) plus a shared user-level `ruff.toml` |

`claude-safe-mixin` layers onto any workload that already provides `claude`:
the published `docker.io/docker/sbx-kit-claude` image or this repo's
`claude-ollama`. `claude-ollama` is a workload of its own rather
than a mixin on the Claude Code workload: composed onto that workload, a
mixin's allow list merges with the workload's Anthropic hosts, so the sandbox
could still reach Anthropic.

`requires` is checked when kits are composed: sbx refuses a composition in
which nothing provides a required name. `devbox` and `nix` each bundle their
own Nix store and declare `conflicts` on the other, so composing both onto
the same workload is refused rather than left to corrupt `/nix` at runtime.

## Validating a kit

`sbx kit validate` can't load v3 source kits, so the build is the check.
`scripts/test-kit.sh` (from contrib) builds a kit with the kit frontend into
an OCI layout and judges it with `kit-tck`, the spec's conformance checker,
which catches errors the frontend lets through. Download `kit-tck` from the
[docker/sandbox-kit-spec releases](https://github.com/docker/sandbox-kit-spec/releases)
(the newest `v3.*`) and put it on `PATH`, or point `KIT_TCK` at it. From a
clone:

```console
$ ./scripts/test-kit.sh ruff-lint -v              # build + kit-tck
$ ./scripts/test-kit.sh --validate-only ruff-lint # build only, no kit-tck needed
$ ./scripts/test-kit.sh --inspect ruff-lint       # also `sbx kit inspect` (needs sbx running)
```

Linting is separate, and needs `shellcheck` and `yamllint`:

```console
$ uv tool install yamllint
$ ./scripts/lint-kit.sh ruff-lint
```

CI runs both on each push and pull request:
[`.github/workflows/tck.yml`](.github/workflows/tck.yml) (`Kit TCK`) runs
`test-kit.sh` for every kit, and also weekly on a schedule to catch drift in
base images, upstream installers and new `kit-tck` checks;
[`.github/workflows/lint.yml`](.github/workflows/lint.yml) (`Lint`) runs
`lint-kit.sh` for every kit and shellchecks `scripts/`. `sbx kit inspect` and
running the kits in a real sandbox need `/dev/kvm`, which GitHub-hosted
runners don't provide, so both are done by hand.

## License

MIT. See [LICENSE](./LICENSE). Directories that carry a `NOTICE.md` contain
material from [docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib)
or other upstream projects under their own license (Apache-2.0 or MIT); the
license text is in the `LICENSE-*` file beside each `NOTICE.md`.
