# syntax=docker/dockerfile:1
# Overlay recipe for base-skills: the skills staged read-only under
# /usr/local/share/base-skills/skills/. The startup hook in base-skills.yaml
# copies them into the workspace's .claude/skills/ at boot.
#
# Root-owned staging outside the agent's home, so a plain COPY is enough: the
# parent directories it creates match the base's (root, 0755).
FROM scratch
COPY files/skills/ /usr/local/share/base-skills/skills/
