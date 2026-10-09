Based on [docker/sbx-kits-contrib](https://github.com/docker/sbx-kits-contrib/tree/7f8518ce98d439a35096ff7f6d00e9b8f65b0f53/claude) (Apache-2.0).

Modified for alakae/sbx-kits (each delta is marked `MIGRATION NOTE (claude-safe)` in the file):

- claude-safe.yaml (from claude.yaml): display name and description; the install hooks no longer seed bypass-mode settings (`bypassPermissionsModeAccepted`, `permissions.defaultMode: bypassPermissions`, `skipDangerousModePermissionPrompt`) and write settings.json as one JSON line; the agent context points at claude-safe-context.md.
- claude-safe.dockerfile (from claude.dockerfile): installs the managed-settings drop-in files/claude-safe.json at /etc/claude-code/managed-settings.d/; `ENTRYPOINT ["claude"]` instead of `claude --dangerously-skip-permissions`; flavor label `claude-safe`.
- claude-safe-context.md (from claude-context.md): an "Approval Mode" section is prepended.
- files/claude-safe.json: new.
