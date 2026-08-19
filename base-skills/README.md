# base-skills

A mixin that drops a collection of portable agent skills into the sandbox
workspace, under `.claude/skills/`. No per-agent duplication: Claude Code
reads that path directly, and OpenCode treats it as a first-class discovery
location too.

## Skills

| Skill | What it does |
| ----- | ------------ |
| `ruff` | Guides the agent to use Ruff for Python linting and formatting |
| `ty` | Guides the agent to use ty for Python type checking |
| `uv` | Guides the agent to use uv for Python package and project management |
| `fix-dependabot` | Resolves peer dependency conflicts on Dependabot branches |
| `kit-author` | Guides the agent to author Docker Sandboxes kits (spec.yaml, lifecycle, composition, distribution, TCK testing) |
| `review-claude-config` | Audits `.claude/` configuration files against best practices (Claude Code-flavored — see note below) |
| `session-review` | End-of-session retrospective — proposes skill and settings improvements (Claude Code-flavored — see note below) |

## Usage

```console
$ sbx run claude --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" ~/my-project
$ sbx run opencode --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" ~/my-project
```

Stack with other kits:

```console
$ sbx run claude \
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
