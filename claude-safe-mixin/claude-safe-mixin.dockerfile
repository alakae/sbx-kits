# syntax=docker/dockerfile:1
# Overlay recipe for claude-safe-mixin: the approval-mode policy as a Claude
# Code managed-settings drop-in, landing on any base.
#
# The same file as ../claude-safe/files/claude-safe.json; a kit's build context
# cannot reach outside its own directory, so each kit carries its own copy.
# Keep the two identical.
#
# A plain COPY is enough: the parent directories it creates (/etc,
# /etc/claude-code, managed-settings.d) are root-owned 0755, as on any base,
# and the file stays root-owned so the agent user cannot edit the policy.
FROM scratch
COPY files/claude-safe.json /etc/claude-code/managed-settings.d/claude-safe.json
