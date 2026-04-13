---
name: context-find-plan
description: Find the plan associated with a specific git commit hash. Use when the user says "what plan was this commit part of", "find the plan for commit <hash>", "which plan does <hash> belong to", or wants to trace a commit back to its originating plan.
argument-hint: <commit-hash>
allowed-tools: [Bash, Read, Glob, Grep]
---

# context-find-plan

Find which plan a given git commit hash belongs to, then load that plan into context.

## Arguments

The user invoked this with: $ARGUMENTS

The argument should be a full or partial git commit hash (e.g. `abc1234` or `abc1234def5678`).

## Execution Steps

### Step 1: Validate Input

If `$ARGUMENTS` is empty, ask:
> "Please provide a commit hash (full or partial). Example: `/context-find-plan abc1234`"

Extract the hash from `$ARGUMENTS` (it may include surrounding text — find the first hex-only token of 4+ characters).

### Step 2: Verify Commit Exists

```bash
git rev-parse --verify <hash>
```

If the command fails, tell the user:
> "Commit hash '<hash>' not found in this repository. Check the hash and try again."

Resolve to both forms:
- `FULL_HASH=$(git rev-parse <hash>)`
- `SHORT_HASH=${FULL_HASH:0:7}`

### Step 3: Search Plan Files

Find `REPO_ROOT` via `git rev-parse --show-toplevel`. Search all plan files for the hash:

```bash
grep -rl "$SHORT_HASH" "$REPO_ROOT/.context/plans/" 2>/dev/null | grep -v index.md
```

Also search using the full hash in case partial wasn't written.

### Step 4: Handle Results

**Single match:** Proceed to Step 5.

**Multiple matches** (unusual): Present a numbered list and ask the user to select one.

**No match — fallback search:**
1. Check commit message for a plan reference:
   ```bash
   git log -1 --format="%B" <hash> | grep "\[plan:"
   ```
2. Extract the plan ID from `[plan:YYYY-MM-DD-<name>]` and look for that file in `.context/plans/`
3. If still nothing found:
   > "No plan found referencing commit `<short-hash>`. This commit may predate plan tracking, or the plan file may have been deleted.
   >
   > Commit details:
   >   Hash:    <full-hash>
   >   Date:    <commit date>
   >   Message: <commit message>"

### Step 5: Display Results

Show commit context and the full plan:

```
Found commit <short-hash> in plan: 2026-03-24-add-auth.md

Commit:
  Hash:    <full-hash>
  Date:    <date>
  Message: <message>

This commit appears in the plan's ## Commits section:
  - abc1234 2026-03-24 14:32 fix: add JWT validation middleware [plan:2026-03-24-add-auth]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[full plan content]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 6: Offer to Set as Active Plan

Ask:
> "Set `2026-03-24-add-auth` as the active plan for commit tracking? [y/N]"

If yes, write the filename to `$REPO_ROOT/.context/plans/.current`.
