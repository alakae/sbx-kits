---
name: fix-dependabot
description: >
  Resolve peer dependency conflicts on a Dependabot branch. Use when npm ci
  (or equivalent) fails with ERESOLVE errors after a Dependabot dependency bump.
  Also handles the case where Dependabot silently omitted a companion package
  from a grouped PR due to shallow peer dependency detection or lockfile-reparse
  drop, a known limitation as of early 2026.
user-invokable: true
disable-model-invocation: false
---

# Fix Dependabot Peer Dependency Conflicts

You are helping resolve peer dependency conflicts on a Dependabot branch.
Follow these steps exactly and in order. Do not skip steps.

---

## Step 1: Verify context

Run `git branch --show-current` and confirm the branch name starts with
`dependabot/`. If it does not, stop and tell the user this skill only applies
to Dependabot-opened branches.

Also read the PR title or branch name to identify which packages were bumped
by Dependabot. Record these as the **Dependabot-bumped set**.

---

## Step 2: Discover the build toolchain

Use a subagent (subagent_type: Explore) to inspect the repo and determine the
correct way to run package manager commands. Check for:

- READMEs and their relevant sections
- Makefiles and their relevant targets
- CI workflow files (`.github/workflows/`) — look at how deps are installed
  and which commands are invoked
- Toolchain config files (`.nvmrc`, `.node-version`, `.tool-versions`)
- Lock file presence (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`) to
  confirm the package manager in use
- Any wrapper scripts or tooling that gates how commands are run

Determine the exact install command (e.g. `npm ci`, `yarn install --frozen-lockfile`,
`pnpm install --frozen-lockfile`) before proceeding.

---

## Step 3: Run the install command and capture conflicts

Run the install command from Step 2 and collect all output.

- If it succeeds with no errors, tell the user the branch is already clean
  and stop.
- If it fails, extract every ERESOLVE block (or equivalent for yarn/pnpm).
  Record each conflict as a structured tuple:
  `{ conflicting_package, peer_dep_range_declared, installed_version_out_of_range }`

---

## Step 4: Classify the root cause

For each conflict tuple from Step 3, determine which of the following applies:

**4-A: Standard peer conflict (package not in the Dependabot-bumped set)**
The conflicting package was not touched by Dependabot. Its peer range is
simply incompatible with a newly bumped transitive or direct dependency.

**4-B: Dependabot grouped-PR omission**
The conflicting package:
- matches the group's `patterns` in `.github/dependabot.yml`, AND
- has a published major version whose peer range covers the Dependabot-bumped
  package, AND
- was NOT included in the Dependabot PR.

This is a known Dependabot limitation as of early 2026: grouped PRs assemble
packages by pattern match, not by dependency graph coherence. Dependabot does
not run a post-assembly install simulation to validate that the combined set
of updates forms a consistent dependency graph. Treat this as a first-class
case, not a generic conflict.

**4-C: Transitive conflict (no direct fix available in package.json)**
The conflict is more than one level deep and cannot be resolved by bumping a
direct dependency. Note this for manual escalation.

Label every conflict before proceeding to Step 5.

---

## Step 5: Find compatible versions

For each conflict, run the appropriate registry lookup to find the latest
published version that satisfies the required peer range.

For **4-B conflicts**, specifically check whether the omitted package has a
published version whose `peerDependencies` field covers the new version of
the Dependabot-bumped package. This is the companion bump that Dependabot
should have included but did not.

If a compatible version exists but cannot be installed due to a date-based
policy (e.g. an npm `before` config or a Dependabot `cooldown.default-days`
constraint), do **not** attempt workarounds. Explain:
- Which compatible version was found
- When it was published
- When the cooldown expires and the fix can be applied

Then stop.

If no compatible version exists at all, escalate to the user with a clear
explanation and stop.

---

## Step 6: Install fixes

Install all compatible fixes in a single command, saving each to the
appropriate `devDependencies` or `dependencies` section as it was originally
declared. Do not change a dev dependency to a prod dependency or vice versa.

For **4-B companion bumps**, add a note in your output:

> `<package>` was bumped to `<version>` because Dependabot omitted it from
> the grouped PR. This is a known Dependabot limitation as of early 2026:
> grouped updates do not perform peer dependency graph validation before
> opening a PR. Consider adding a mandatory `npm ci` CI gate on all
> Dependabot PRs to catch this class of error automatically.

---

## Step 7: Verify

Re-run the install command from Step 2.

- If it succeeds, report all changes made and confirm the branch is clean.
- If it still fails, return to Step 4 with the new conflict output. Do not
  loop more than three times; if unresolved after three passes, report the
  remaining conflicts to the user and stop.

---

## Step 8: Summarize and recommend follow-up

After a successful fix, always append a brief follow-up block:

1. **CI gate recommendation**: If no `npm ci` or equivalent step is present
   as a required status check on Dependabot PRs, recommend adding one. This
   is the most reliable catch for this class of error, since Dependabot itself
   will not detect the conflict before opening the PR.

2. **Dependabot config note**: If the conflict was a 4-B omission, note that
   no `dependabot.yml` option currently forces holistic peer dependency
   resolution. The `groups` feature assembles packages by pattern match only.

3. **Renovate migration note** (only if 4-B conflicts were found): Briefly
   mention that Renovate resolves grouped updates via lockfile simulation and
   validates peer dependency consistency before opening a PR, which eliminates
   this class of failure entirely.
