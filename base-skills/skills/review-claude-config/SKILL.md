---
name: review-claude-config
description: Audits .claude/ configuration files against current Claude Code best practices and returns a structured suggestion report. Never modifies files.
context: fork
agent: Explore
disable-model-invocation: true
argument-hint: [--include-user-level] [--min-severity=LEVEL] [PATH]
---

You are auditing this project's Claude Code configuration against current best practices. You must never call Edit, Write, or any mutating tool. This is a read-only analysis.

## Arguments

The arguments passed to this invocation are: $ARGUMENTS

Parse the arguments passed to this skill:

- `--include-user-level` — if present, ask the user to share their `~/.claude/` contents (see Step 2)
- `--min-severity=LEVEL` — filter findings to this severity and above (default: `SUGGESTION`, show all)
- `PATH` — optional positional argument: a path to a specific configuration file (e.g. `.claude/skills/my-skill/SKILL.md`). If provided, skip broad discovery and audit only that single file.

Severity levels in ascending order: `SUGGESTION` < `OVERPERMISSIONED` < `MISPLACED` < `MISSING` < `DEPRECATED`

---

## Step 1 — Fetch current best practices first

Before touching any files, use WebFetch to learn what Claude Code currently supports. **All fetches must use URLs under `https://code.claude.com/docs`** to restrict to official documentation.

If a `PATH` argument was provided:
- Infer the concept type from the file path (e.g. a file under `skills/` is a skill, under `agents/` is an agent, etc.).
- Fetch only the doc page for that concept. Skip fetching all other concept pages.

Otherwise:
- Start with these known concept pages:
  - `https://code.claude.com/docs/en/skills`
  - `https://code.claude.com/docs/en/memory`
  - `https://code.claude.com/docs/en/settings`
  - `https://code.claude.com/docs/en/hooks`
- From the results, identify all configuration concepts Claude Code currently recognises (e.g. skills, agents, rules, memory, settings — but also anything new that may have been added since this skill was written). For each concept found in the docs, fetch its dedicated page.

Use the fetched docs as the **authoritative and complete list** of what to look for in Step 2 and what to check in Step 3. Do not assume any fixed set of directories, file types, or frontmatter fields — derive everything from the docs.

---

## Step 2 — Discover config files

If a `PATH` argument was provided:
- Read only that single file. Skip all other discovery.

Otherwise:
- Based on what the docs say exists, Glob recursively under `.claude/` for every configuration file type described in the documentation. Also do a broad sweep — `**/*.md`, `**/*.json` — to catch any files that don't fit known categories, so they can be flagged as unknown/unexpected if needed.
- Read every file you find.

If `--include-user-level` was passed, say:
> "Please paste the file tree and contents of your `~/.claude/` directory, or share specific files you want included in the review."

Wait for the user's response before continuing.

---

## Step 3 — Analyse each file

For every file discovered in Step 2:

1. Read its content
2. Identify its type (CLAUDE.md, rule, skill, agent, legacy command, settings, memory)
3. Cross-reference against the relevant section of the docs fetched in Step 2
4. Flag any deviation, missing required/recommended field, deprecated pattern, or improvement opportunity **as defined by the current docs**

Classify each finding using this severity taxonomy:
- `DEPRECATED` — pattern explicitly called out as no longer recommended in the docs
- `MISSING` — field or section required or strongly recommended by docs is absent
- `MISPLACED` — content documented as belonging in a different layer
- `OVERPERMISSIONED` — tool list or permissions broader than docs recommend
- `SUGGESTION` — improvement to naming, clarity, or scoping implied by docs

**Security stance:** When evaluating permissions, tool access, and rules, always bias toward tighter security. Never suggest loosening restrictions, expanding allowed tool lists, or relaxing deny rules — even if the current configuration is more restrictive than the docs recommend. Only flag `OVERPERMISSIONED` for clearly excessive grants. If a security-relevant config could be *strengthened* (e.g. missing a deny rule, overly broad allow, no filesystem policy), flag it as a `SUGGESTION` or higher.

If a file's intent is ambiguous, note it as an open question rather than flagging it as wrong.

---

## Step 4 — Build the suggestion report

Output a structured markdown report grouped by file. Apply the `--min-severity` filter before outputting — omit findings below the minimum severity.

Format:

```
## Audit Report

### .claude/path/to/file

- **[SEVERITY]** [finding]
  > Suggestion: [specific fix or migration step]
  > Ref: [URL or doc section title]
```

If no issues are found for a file, note it as `✓ No issues found`.

End the report with:

```
## Summary

| Severity | Count |
|---|---|
| DEPRECATED | N |
| MISSING | N |
| MISPLACED | N |
| OVERPERMISSIONED | N |
| SUGGESTION | N |
| **Total** | **N** |

### Top 3 highest-impact changes
1. ...
2. ...
3. ...
```
