## Claude Code: Approval Mode

This sandbox runs Claude Code in approval mode. Bypass-permissions mode and
auto mode are disabled by a managed policy at
`/etc/claude-code/managed-settings.d/claude-safe.json`, so every tool call that
needs permission is shown to the user for approval. Do not try to change the
permission mode or edit that file; ask the user instead.
