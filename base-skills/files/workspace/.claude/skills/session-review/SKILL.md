---
name: session-review
description: >
  End-of-session retrospective. Fetches latest Claude Code docs, reviews the
  session conversation, bins learnings by confidence, reports knowledge gaps and
  setup improvements, and proposes targeted skill file edits (writes them if
  running from the dotfiles repo).
disable-model-invocation: true
effort: high
---

You are performing an end-of-session retrospective and self-improvement cycle.
The developer just finished implementing something and wants to improve their
Claude Code workflow before clearing this session.

---

## Step 1 — Fetch Latest Docs

Use WebFetch to read each of these pages in full. Record any features,
patterns, or capabilities that are new, changed, or underused relative to what
you observed in this session:

- `https://code.claude.com/docs/en/skills`
- `https://code.claude.com/docs/en/sub-agents`
- `https://code.claude.com/docs/en/memory`
- `https://code.claude.com/docs/en/hooks`
- `https://code.claude.com/docs/en/settings`

---

## Step 2 — Detect Mode and Read Existing Skills

Check whether `.claude/skills/` exists relative to the current working
directory using Glob (`**/.claude/skills/*/SKILL.md` — limit to depth 3):

- If **found**: you are in **dotfiles mode**. Read every `SKILL.md` you found.
- If **not found**: you are in **propose-only mode**. Note this for Step 6.

Understanding what skills already exist lets you avoid proposing duplicates and
lets you target updates at specific files.

---

## Step 3 — Review the Session

Scan the full conversation above. Collect signals in three buckets:

- **Corrections** — the developer said "no, do X instead", had to re-explain
  context, explicitly rejected your output, or undid something you did.
- **Approvals** — patterns you used that the developer explicitly accepted,
  praised, or confirmed without pushback despite being a non-obvious choice.
- **Friction moments** — long back-and-forth to converge on something simple,
  missing subagents that would have helped, repeated context-setting, tool
  inefficiency, or anything that felt slower than it should have been.

---

## Step 4 — Bin the Learnings

Classify every signal from Step 3:

- **HIGH** — explicit corrections. The developer told you something is wrong or
  unwanted. Should become a hard rule immediately.
- **MEDIUM** — patterns that worked well, confirmed preferences, things that
  smoothed the session. Worth encoding as guidance.
- **LOW** — loose observations, hypotheses, or things to watch across more
  sessions. Flag for the developer but do not auto-propose as skill changes.

---

## Step 5 — Output the Review

Produce a structured report with exactly two sections. Be specific and grounded
in what actually happened — no generic advice. Three to five items per section.

---

### Knowledge Gaps

Things the developer could learn that would have directly helped in this session.

For each gap:

- **What**: The concept or feature name
- **Why it matters here**: One sentence tying it to something that happened
- **Read**: Direct doc URL from the pages you fetched in Step 1

---

### Setup

Concrete changes to make to their Claude Code setup.

For each item:

- **What to create/update**: e.g. `.claude/skills/X/SKILL.md`, a rule file,
  `.claude/settings.json`, a subagent definition
- **Problem it solves**: What friction from this session it eliminates
- **Starter snippet**: A ready-to-paste block they can use immediately

---

## Step 6 — Propose Skill Updates

For each HIGH and MEDIUM signal that maps to a skill file improvement:

1. Identify which `SKILL.md` it belongs to (or name a new file to create)
2. Show the exact text to add or replace — a precise diff or block, not a
   vague description
3. Tie it explicitly to the session event that motivated it

Then, depending on mode detected in Step 2:

**Dotfiles mode** — present each proposal and ask for confirmation:
> "Shall I write this to `.claude/skills/<name>/SKILL.md`? (yes / no / edit)"

Wait for the developer's response before writing anything. For confirmed
changes, use the Write tool to update the file. Do not auto-commit — leave
git staging and committing to the developer.

**Propose-only mode** — output each proposal in a fenced block with this note:

> To apply: open your dotfiles repo, paste this into
> `.claude/skills/<name>/SKILL.md`, then `git add -f` and commit.