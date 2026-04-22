---
model: claude-sonnet-4-6
---

---

> ⚠️ **STRICT STRUCTURE RULE**
> `CLAUDE.md`, `Tasks/`, and `.context/` must **always** live at the **git repository root** — never inside a plugin subfolder (e.g. never inside `webtoffee-product-feed-pro/`).
>
> **Before doing anything, verify we are at the repo root:**
> ```bash
> git rev-parse --show-toplevel
> pwd
> ```
> These two must match. If they do not — stop and tell the user:
> ```
> ⚠️  You are not at the repository root.
> Please run: cd $(git rev-parse --show-toplevel)
> Then re-run this command.
> ```

---

# /wt-feature — Read Confluence PRD + Figma design → create feature folder → save files

You are acting as a Senior WordPress/WooCommerce product manager.

## Instructions

---

### Step 1: Resolve ticket, PRD link, and feature name

**If a Jira ticket number is provided (e.g. IS-123 or ISCS-322):**
- Fetch the ticket from Jira REST API using credentials from `.claude/settings.json`:
  ```bash
  curl -s -u "$JIRA_USER:$JIRA_TOKEN" \
    "$JIRA_URL/rest/api/3/issue/{TICKET}?fields=summary,description,attachment"
  ```
- Extract: ticket summary (use as feature name suggestion), description text, and any Confluence links mentioned in the description
- If a Confluence link is found in the description → use it automatically
- If no Confluence link → ask: "No Confluence link found in the ticket. Paste it manually, or press Enter to skip."

**If no ticket is provided**, ask:
```
1. Jira ticket number? (e.g. IS-123) — or paste Confluence PRD link directly
2. Short feature name for the folder? (e.g. tiktok-shop-feed)
```

**Feature name:** derive from the Jira ticket summary if available, otherwise ask.

Wait for any missing info before continuing.

---

### Step 1B: Set up release branch

Ask the user:
```
Which release version is this feature targeting? (e.g. 1.2.5)
```

Format the release branch name as `release/{version}` (e.g. `release/1.2.5`).

**Check if the release branch already exists on the remote:**
```bash
git fetch origin
git branch -r | grep "origin/release/{version}"
```

**If the release branch EXISTS remotely:**
```bash
git checkout release/{version} 2>/dev/null || git checkout -b release/{version} origin/release/{version}
git pull origin release/{version}
```
Show: `✅ release/{version} already exists — pulled latest from origin`

**If the release branch does NOT exist remotely:**
```bash
git checkout master
git pull origin master
git checkout -b release/{version}
git push -u origin release/{version}
```
Show: `✅ release/{version} created from master and pushed to origin`

**Now create the feature branch from the release branch:**
```bash
git checkout -b feature/{JIRA-TICKET}-{feature-name}
```
Show: `✅ feature/{JIRA-TICKET}-{feature-name} created from release/{version}`

**Save the target release version** to `Tasks/feature/{JIRA-TICKET}-{feature-name}/.release-version`:
```
{version}
```
This is read by `/wt-commit` to set the correct PR destination branch automatically.

> ⚠️ **master is never touched directly.** Release branches are created from master. Feature branches are created from release branches.

---

### Step 2: Launch parallel research sub-agents

Launch the following sub-agents **simultaneously** using the Agent tool:

**Sub-agent A — Confluence PRD (`prd-fetcher` agent — haiku, effort: low):**
- Use the Atlassian MCP to read the Confluence page at the resolved link
- If no Confluence link exists, use the Jira ticket description as the PRD source
- Return: full PRD content as markdown

**Sub-agent B — Figma design (`design-reader` agent — haiku, effort: low) (if user provides a Figma link):**
- Ask the user first: "Is there a Figma design for this feature? (yes / no — if yes, paste the link)"
- If yes: Use the Figma MCP to read the design file
- Return: screens, components, field names, interactions, UI flows, gaps vs PRD
- If no: return "no Figma"

**Sub-agent C — Codebase scan (`code-explorer` agent — haiku, effort: medium):**
- Scan `includes/` for any existing feature that is similar to this one
- Look for existing channel classes, feed formats, or admin UI patterns that relate to the Jira ticket topic
- Return: list of relevant existing files, class names, and patterns found

Wait for all three sub-agents to complete before continuing.

---

### Step 3: Create the feature folder

Create the folder:
```
Tasks/feature/{JIRA-TICKET}-{feature-name}/
```

For example:
```
Tasks/feature/IS-123-tiktok-shop-feed/
```

---

### Step 4: Save PRD.md

Save the PRD content (from Sub-agent A) to:
```
Tasks/feature/IS-123-feature-name/PRD.md
```

Use this structure:
```markdown
# PRD: [Feature Name]
Jira: IS-123
Confluence: [original link]

## Summary
[One paragraph from Confluence]

## Requirements
[Bullet list of what the feature must do]

## WooCommerce Integration
[Hooks, filters, WC data touched]

## Admin UI
[Settings page, meta box, columns — exact description]

## Frontend (if any)
[Template changes, shortcodes, blocks]

## Data / Database (if any)
[New tables, post meta, options]

## Existing Code to Reuse
[From Sub-agent C — list any existing classes or patterns to build on]

## Out of Scope
[What this explicitly does NOT include]

## Open Questions
[Anything unclear that may affect implementation]
```

---

### Step 5: Save figma-notes.md (if Figma exists)

Save design notes (from Sub-agent B) to:
```
Tasks/feature/IS-123-feature-name/figma-notes.md
```

Use this structure:
```markdown
# Figma Design Notes: [Feature Name]
Figma Link: [original link]

## Screens
[List each screen with description]

## Components Used
[List UI components]

## Field Names
[Exact field labels from design]

## Interactions / Flows
[User flows, button actions, states]

## Gaps vs PRD
[Anything in PRD not in design or vice versa]
```

---

### Step 6: Show summary to user

Display:
```
✅ Branch setup:
   release/{version}               ← base branch (from master)
   feature/{JIRA-TICKET}-{name}    ← your working branch

✅ Feature folder created: Tasks/feature/{JIRA-TICKET}-{feature-name}/
✅ PRD.md saved (from Confluence)
✅ figma-notes.md saved (from Figma)   ← or "skipped (no Figma)"

Existing related code found:
[list from Sub-agent C, or "none"]

Gaps found between PRD and design:
[list any gaps, or "none"]

Ready to generate the implementation plan?
Run /wt-plan to continue.
```
