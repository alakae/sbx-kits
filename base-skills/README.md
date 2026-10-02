# base-skills

A mixin that drops a collection of portable agent skills into the sandbox
workspace, under `.claude/skills/`. No per-agent duplication: Claude Code
reads that path directly, and OpenCode treats it as a first-class discovery
location too.

A startup hook copies the skills there each time the sandbox starts. It runs
in the background, so on the very first session the agent may start before
the skills are in place.

## Skills

| Skill | What it does |
| ----- | ------------ |
| `ruff` | Guides the agent to use Ruff for Python linting and formatting |
| `ty` | Guides the agent to use ty for Python type checking |
| `uv` | Guides the agent to use uv for Python package and project management |
| `fix-dependabot` | Resolves peer dependency conflicts on Dependabot branches |
| `kit-author` | Guides the agent to author Docker Sandboxes kits in the **v2** `spec.yaml` format (vendored; carries a banner pointing at v3 guidance) |
| `review-claude-config` | Audits `.claude/` configuration files against best practices (Claude Code-flavored — see note below) |
| `session-review` | End-of-session retrospective — proposes skill and settings improvements (Claude Code-flavored — see note below) |

## Usage

```console
$ sbx run ./claude-safe --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" ~/my-project
```

OpenCode has no v3 workload of its own — Docker publishes it as a mixin
(`docker/sbx-kit-opencode-mixin`) layered onto a shell workload. Confirm the
mixin's published tag (`sbx kit inspect`) before relying on this:

```console
$ sbx run docker.io/docker/sbx-kit-shell:1.0.0 \
    --kit docker.io/docker/sbx-kit-opencode-mixin:<version> \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" \
    ~/my-project
```

Stack with other kits:

```console
$ sbx run ./claude-safe \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" \
    ~/my-project
```

## Agent compatibility

- Most skills behave identically on Claude Code and OpenCode — plain
  `name` + `description` frontmatter, nothing agent-specific.
- Known limitation: OpenCode does not support `disable-model-invocation`,
  so skills that set it to stay manual-only on Claude Code get
  auto-advertised on OpenCode instead.
- OpenCode requires a skill's directory name to equal its frontmatter
  `name`.

## Validating a change

```console
$ ./scripts/test-kit.sh base-skills
```
