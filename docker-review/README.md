# docker-review

A mixin that installs a [Claude Code skill][skills] teaching the agent to
review Dockerfiles against common best practices (layer caching, image size,
security, reproducibility).

[skills]: https://code.claude.com/docs/en/skills

## Usage

```console
$ sbx run claude --kit "git+https://github.com/alakae/sbx-kits.git#dir=docker-review" ~/my-project
```

Inside the sandbox, invoke the skill directly:

```text
/docker-review
```

Or ask the agent to review a Dockerfile — the skill's `description` tells
Claude when to apply it automatically.

## How it works

The kit drops a single file into the workspace:

```
.claude/skills/docker-review/SKILL.md
```

Claude Code reads project-scoped skills from `.claude/skills/` on start.
The FAQ covers [why user-level `~/.claude/` doesn't work in sandboxes][faq] —
kits have to target the workspace instead.

[faq]: https://docs.docker.com/ai/sandboxes/faq/#why-doesnt-the-sandbox-use-my-user-level-agent-configuration

## Adapt it to other skills

This kit is a pure static-files mixin — no install step, no network, no
credentials. Use it as a template for any `SKILL.md` you want to ship:

1. Replace the `SKILL.md` body with your skill's instructions.
2. Rename the directory under `files/workspace/.claude/skills/<name>/`.
3. Update `spec.yaml`'s `name` and `description`.

Bundle supporting files (templates, scripts) alongside `SKILL.md` in the
same directory if the skill needs them.
