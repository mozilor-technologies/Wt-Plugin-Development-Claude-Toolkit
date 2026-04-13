---
name: context-load-plan
description: Load a saved plan from .context/plans/ into the current session context. Use when the user says "load plan", "resume the plan", "load the plan for X", "what was my plan for Y", "show me the plan", or is starting a new session and needs to pick up where they left off.
argument-hint: [plan-name-or-partial]
allowed-tools: [Bash, Read, Glob]
---

# context-load-plan

Load a saved plan from `.context/plans/` into the current session.

## Arguments

The user invoked this with: $ARGUMENTS

If `$ARGUMENTS` is provided, use it as the search term. If empty, list all plans and ask the user to choose.

## Execution Steps

### Step 1: Find the Plans Directory

Run `git rev-parse --show-toplevel` to find `REPO_ROOT`.

Verify `$REPO_ROOT/.context/plans/` exists. If not:
> "`.context/plans/` not found. Run `/context-init` to set up the context folder."

### Step 2: Search for Matching Plans

List all `*.md` files in `.context/plans/` excluding `index.md`.

**If `$ARGUMENTS` is provided:**
Find files whose name contains the search term (case-insensitive partial match). Sort by modification date, newest first.

**If `$ARGUMENTS` is empty:**
Read `index.md` and display the plan list. Ask the user to type a plan name or number to select one.

### Step 3: Handle Results

**Single match:** Proceed to Step 4.

**Multiple matches:** Present a numbered list:
```
Multiple plans match "<search term>":
  1. 2026-03-24-add-auth.md       (in-progress, 2026-03-24)
  2. 2026-02-10-add-oauth.md      (completed, 2026-02-10)

Which plan? Enter number:
```
Wait for user selection.

**No match:**
> "No plan found matching '<search term>'. Run `/context-load-plan` with no arguments to list all plans."

### Step 4: Read and Display the Plan

Read the full content of the selected plan file and output it clearly:

```
Loaded plan: 2026-03-24-add-auth.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[full plan content]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status:      in-progress
Last note:   2026-03-24 14:32
Open steps:
  - [ ] Step 2 — Connect to database
  - [ ] Step 3 — Write integration tests
```

Parse the plan to extract status, the most recent session note timestamp, and unchecked steps.

### Step 5: Offer to Set as Active Plan

Ask:
> "Set this as the active plan for commit tracking? (current: <current .current value or 'none'>) [Y/n]"

If yes, write the filename to `$REPO_ROOT/.context/plans/.current`.

Confirm: "Active plan set to `<filename>`."
