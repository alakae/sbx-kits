# base-skills

A mixin that bundles a collection of portable agent skills into the image
and exposes each one directly in the composed agent's own skill directory —
Claude Code's `~/.claude/skills`, OpenCode's `~/.config/opencode/skills` —
via the `agent-skill@1` capability. Nothing is copied into the workspace, so
there's nothing to `.gitignore` and no race with the agent's first session.

## Skills

| Skill | What it does |
| ----- | ------------ |
| `ruff` | Guides the agent to use Ruff for Python linting and formatting |
| `ty` | Guides the agent to use ty for Python type checking |
| `uv` | Guides the agent to use uv for Python package and project management |
| `fix-dependabot` | Resolves peer dependency conflicts on Dependabot branches |
| `create-kit-v3` | Docker's guide to authoring a new v3 kit: workload vs mixin, descriptor, capabilities, version pinning, verification (vendored from docker/sandbox-kit-spec) |
| `migrate-kit-to-v3` | Docker's guide to porting a v2 `spec.yaml` kit to v3, with the field-by-field mapping (vendored from docker/sandbox-kit-spec) |
| `review-claude-config` | Audits `.claude/` configuration files against best practices (Claude Code-flavored — see note below) |
| `session-review` | End-of-session retrospective — proposes skill and settings improvements (Claude Code-flavored — see note below) |

## Usage

```console
$ sbx run docker.io/docker/sbx-kit-claude:2.1.296 --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" ~/my-project
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
$ sbx run docker.io/docker/sbx-kit-claude:2.1.296 \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=base-skills" \
    --kit "git+https://github.com/alakae/sbx-kits.git#dir=ruff-lint" \
    ~/my-project
```

## Agent compatibility

- Every skill is optional: on a workload whose agent declares no skill
  directory (`agent-skills@1`), such as `docker.io/docker/sbx-kit-shell`
  alone, they are skipped instead of refusing the sandbox.
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
