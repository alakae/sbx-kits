# syntax=docker/dockerfile:1
# Overlay recipe for base-rules: the rules staged read-only under
# /usr/local/share/base-rules/rules/. The startup hook in base-rules.yaml
# copies them into the workspace's .claude/rules/ at boot.
#
# MIGRATION NOTE: v1's files/workspace/ tree has no v3 equivalent, so the
# rules ride in the image and a hook places them.
#
# Root-owned staging outside the agent's home, so a plain COPY is enough: the
# parent directories it creates match the base's (root, 0755).
FROM scratch
COPY files/rules/ /usr/local/share/base-rules/rules/
