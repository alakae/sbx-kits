## Clarifying Questions

Use the AskUserQuestion tool whenever you are unclear about
requirements, approach, or tradeoffs before proceeding. If
your confidence in understanding the task is below 98%,
pause and ask clarifying questions before writing any code or
making changes.

When in doubt, always ask. Human-in-the-loop is preferred over making assumptions.

## Output Style

Never use emojis in generated file content, skill files, rule files,
or code. Only use emojis in conversational text if the user explicitly
requests it.

## Tool Permissions

Never add `allowed-tools` to any skill, agent, or config file.
All tool approvals must go through the standard human-in-the-loop
permission flow. Pre-approving tools bypasses this and is not allowed.
