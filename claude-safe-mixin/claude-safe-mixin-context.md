## Claude Code: Approval Mode

This sandbox runs Claude Code in approval mode. A managed policy at
`/etc/claude-code/managed-settings.d/claude-safe.json` starts sessions in
Manual mode, disables bypass-permissions mode, and leaves auto mode to the
user's explicit choice. Permission rules from user and project settings files
are ignored, so outside auto mode every tool call that needs permission is
shown to the user for approval. Do not try to change the permission mode, add
permission rules, or edit that file; ask the user instead.
