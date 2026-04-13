---
name: context-init
description: Initialize the .context/ folder structure in the current project. Use this skill when the user says "context init", "initialize context", "set up project context", "create .context folder", or wants to start tracking project context or plans in their repo.
argument-hint: [--no-git-hooks]
allowed-tools: [Bash, Read, Write, Glob]
---

# context-init

Initialize the `.context/` folder and install project hooks for context-aware Claude Code sessions.

## Arguments

The user invoked this with: $ARGUMENTS

## What This Skill Does

1. Creates `.context/` directory with required and optionally-selected markdown files
2. Installs the Claude Code session-start hook (reads `.context/*.md` on each session start)
3. Installs git hooks: `pre-commit`, `prepare-commit-msg`, and `post-commit`
4. Creates `.context/plans/` directory with an empty `index.md`

## Execution Steps

### Step 1: Verify We Are in a Git Repository

Run `git rev-parse --show-toplevel` to get `REPO_ROOT`. If not in a git repo, warn the user:

> "This skill works best inside a git repository. Git hooks will not be installed without one. Proceed with context folder only? [y/N]"

If the user says no, stop. Store `REPO_ROOT` for use in subsequent steps.

### Step 2: Check for Existing .context/

If `$REPO_ROOT/.context/` already exists, ask:

> "A `.context/` folder already exists. Re-initialize? Existing files will not be overwritten. [y/N]"

If the user says no, stop.

### Step 3: Present Optional File Selection

Inform the user these files will always be created:
- `architecture.md` — system design and component overview
- `coding-standards.md` — style, formatting, naming conventions
- `testing-standards.md` — test frameworks and coverage requirements
- `observability.md` — logging, metrics, alerting

Then ask:

> "Which optional context files would you like to add?
>
> 1. `glossary.md` — project-specific terms and definitions
> 2. `runbook.md` — operational runbooks and incident procedures
> 3. `integrations.md` — external service integrations and APIs
> 4. `known-issues.md` — known bugs and technical debt
>
> Enter numbers separated by spaces (e.g. `1 3`), or press Enter to skip:"

Wait for user input. Parse the selection.

### Step 4: Create Directory Structure

```bash
mkdir -p "$REPO_ROOT/.context/plans"
```

### Step 5: Copy Templates

Templates live at `${CLAUDE_PLUGIN_ROOT}/templates/`.

For each required file, copy the template if the destination does not already exist:
- `$REPO_ROOT/.context/architecture.md` ← `${CLAUDE_PLUGIN_ROOT}/templates/architecture.md`
- `$REPO_ROOT/.context/coding-standards.md` ← `${CLAUDE_PLUGIN_ROOT}/templates/coding-standards.md`
- `$REPO_ROOT/.context/testing-standards.md` ← `${CLAUDE_PLUGIN_ROOT}/templates/testing-standards.md`
- `$REPO_ROOT/.context/observability.md` ← `${CLAUDE_PLUGIN_ROOT}/templates/observability.md`

For each user-selected optional file, copy its template if not already present.

Always copy plans index template:
- `$REPO_ROOT/.context/plans/index.md` ← `${CLAUDE_PLUGIN_ROOT}/templates/plans/index.md`

**Do NOT overwrite existing files.**

### Step 6: Install Session-Start Hook (Claude Code)

The session-start hook needs to be registered in Claude Code settings. Check if `~/.claude/settings.json` exists and can be read.

Add a SessionStart hook entry pointing to this plugin's `run-hook.cmd session-start`. The hook should only fire when a `.context/` folder exists in the current project (the hook script handles this gracefully already).

If you cannot safely modify `~/.claude/settings.json`, inform the user:

> "Could not automatically register the session-start hook. To register it manually, add this to `~/.claude/settings.json` under `hooks.SessionStart`:
> ```json
> {
>   "matcher": "startup|clear|compact",
>   "hooks": [{ "type": "command", "command": "\"PATH_TO_PLUGIN/hooks/run-hook.cmd\" session-start", "async": false }]
> }
> ```"

### Step 7: Install Git Hooks

Skip if `--no-git-hooks` was passed in arguments, or if not in a git repo.

Copy and make executable:
- `${CLAUDE_PLUGIN_ROOT}/hooks/pre-commit.sh` → `$REPO_ROOT/.git/hooks/pre-commit`
- `${CLAUDE_PLUGIN_ROOT}/hooks/prepare-commit-msg.sh` → `$REPO_ROOT/.git/hooks/prepare-commit-msg`
- `${CLAUDE_PLUGIN_ROOT}/hooks/post-commit.sh` → `$REPO_ROOT/.git/hooks/post-commit`

```bash
chmod +x "$REPO_ROOT/.git/hooks/pre-commit"
chmod +x "$REPO_ROOT/.git/hooks/prepare-commit-msg"
chmod +x "$REPO_ROOT/.git/hooks/post-commit"
```

If any hook file already exists, ask the user whether to overwrite it.

### Step 8: Git Tracking Decision

Ask:

> "Should `.context/` be tracked in git so your team can share context files? [Y/n]"

If yes (default): verify `.context/` is not excluded by `.gitignore`.
If no: append `.context/` to `$REPO_ROOT/.gitignore`.

### Step 9: Print Summary

```
✓ .context/ initialized successfully!

Created files:
  .context/architecture.md
  .context/coding-standards.md
  .context/testing-standards.md
  .context/observability.md
  [any selected optional files]
  .context/plans/index.md

Hooks installed:
  .git/hooks/pre-commit        ← generates session notes on commit
  .git/hooks/prepare-commit-msg ← tags commits with plan ID
  .git/hooks/post-commit        ← records commit hash in plan

Next steps:
  1. Fill in .context/architecture.md with your project's architecture
  2. Fill in .context/coding-standards.md with your coding conventions
  3. After approving a plan, run /context-save-plan to track it
  4. Each Claude Code session will now load your context files automatically
```
