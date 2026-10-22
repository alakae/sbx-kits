# syntax=docker/dockerfile:1
# Overlay recipe for base-skills: each skill staged read-only under its own
# directory in /usr/share/base-skills/. base-skills.yaml's agent-skill@1
# entries point the runtime at each one, which exposes it directly in the
# composed agent's own skill directory (Claude's ~/.claude/skills, OpenCode's
# ~/.config/opencode/skills, ...) — nothing is copied into the workspace.
#
# Root-owned staging outside the agent's home, so a plain COPY is enough: the
# parent directories it creates match the base's (root, 0755).
FROM scratch
COPY --chown=0:0 skills/ /usr/share/base-skills/
