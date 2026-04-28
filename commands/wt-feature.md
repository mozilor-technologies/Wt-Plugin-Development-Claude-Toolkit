---
model: claude-sonnet-4-6
---

---

> ⚠️ **STRICT STRUCTURE RULE**
> `CLAUDE.md`, `Tasks/`, `.context/`, and `ai-context/` must **always** live at the **git repository root** — never inside a plugin subfolder (e.g. never inside `webtoffee-product-feed-pro/`).
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

### Step 1B: Detect multi-plugin scope

Read `CLAUDE.md` in the current repo:
- Check `Plugin Type` section for `Type: wrapper` and any entries under `Addon Repos`
- If `Type: addon` — note the `Core plugin path` (the primary repo is the addon; branching also happens on core)

Also inspect the Jira ticket fields:
- Labels, components, or description for addon slug names that match entries in `CLAUDE.md → Addon Repos`

Build a **repo list** — the ordered set of repos that need branches for this ticket:
1. **Primary repo** — always the CWD (where you are now)
2. **Addon repos** — any `CLAUDE.md → Addon Repos` entries whose slug appears in the ticket body/labels, OR if the ticket has no such signal, ask:
   ```
   This is a core plugin with addon repos configured.
   Does this ticket also require changes in any addon repos?
   Configured addons: {list slugs from CLAUDE.md}
   (Enter slugs comma-separated, or press Enter to skip)
   ```

Store the resolved repo list in memory for use throughout the rest of this command.

---

### Step 1C: Set up release branch

Ask the user:
```
Which release version is this feature targeting? (e.g. 1.2.5)
```

Format the release branch name as `release/{version}` (e.g. `release/1.2.5`).

**For each repo in the repo list**, run the following branch setup (starting with the primary repo, then each addon repo):

```bash
cd {repo_path}
git fetch origin
git branch -r | grep "origin/release/{version}"
```

**If the release branch EXISTS remotely:**
```bash
git checkout release/{version} 2>/dev/null || git checkout -b release/{version} origin/release/{version}
git pull origin release/{version}
```
Show: `✅ [{repo_slug}] release/{version} already exists — pulled latest`

**If the release branch does NOT exist remotely:**
```bash
git checkout master
git pull origin master
git checkout -b release/{version}
git push -u origin release/{version}
```
Show: `✅ [{repo_slug}] release/{version} created from master and pushed`

**Now create the feature branch from the release branch in each repo:**
```bash
cd {repo_path}
git checkout -b feature/{JIRA-TICKET}-{feature-name}
```
Show: `✅ [{repo_slug}] feature/{JIRA-TICKET}-{feature-name} created`

**Save the target release version and repo list** to the primary repo's feature folder:
```
Tasks/feature/{JIRA-TICKET}-{feature-name}/.release-version   → {version}
Tasks/feature/{JIRA-TICKET}-{feature-name}/.repo-list.json    → see format below
```

`.repo-list.json` format:
```json
{
  "primary": {
    "slug": "product-feed-xyz",
    "local_path": "/path/to/product-feed-xyz",
    "bitbucket_repo": "webtoffee/product-feed-xyz",
    "prefix": "WTPFX_"
  },
  "addons": [
    {
      "slug": "wt-addon-subscriptions",
      "local_path": "/path/to/wt-addon-subscriptions",
      "bitbucket_repo": "webtoffee/wt-addon-subscriptions",
      "prefix": "WTADS_"
    }
  ]
}
```

If the ticket only affects the primary repo, `"addons"` is an empty array `[]`.

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

**Sub-agent C — Core plugin codebase scan (`code-explorer` agent — haiku, effort: medium):**
- Scan `includes/` in the PRIMARY repo for any existing feature similar to this one
- Look for existing channel classes, feed formats, or admin UI patterns that relate to the Jira ticket topic
- Return: list of relevant existing files, class names, and patterns found

**Sub-agent D — Addon plugin codebase scan (only if addon repos are in scope):**
- For each addon repo in `.repo-list.json → addons`, launch a `code-explorer` sub-agent (haiku, effort: medium):
  - Scan `{addon.local_path}/includes/` for similar patterns
  - Return: list of relevant existing files, class names, and patterns found in that addon
- Skip this sub-agent entirely if `.repo-list.json → addons` is empty

Wait for all sub-agents to complete before continuing.

---

### Step 3: Create the feature folder in each repo

Create the feature folder in **every repo in scope** (primary first, then each addon):

**Primary (wrapper) repo:**
```
Tasks/feature/{JIRA-TICKET}-{feature-name}/
```

**Each addon repo:**
```bash
mkdir -p {addon.local_path}/Tasks/feature/{JIRA-TICKET}-{feature-name}/
```

Copy `.release-version` into each addon repo's feature folder so `/wt-commit` can resolve the PR destination branch when run from that repo:
```bash
cp Tasks/feature/{JIRA-TICKET}-{feature-name}/.release-version \
   {addon.local_path}/Tasks/feature/{JIRA-TICKET}-{feature-name}/.release-version
```

For example, with two repos in scope:
```
/path/to/product-feed-xyz/Tasks/feature/IS-123-tiktok-shop-feed/
/path/to/wt-addon-subscriptions/Tasks/feature/IS-123-tiktok-shop-feed/
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

Repos in scope for this ticket:
   [primary]  {primary-slug}       ← {local_path}
   [addon]    {addon-slug}         ← {local_path}   (if any)

✅ Feature folder created: Tasks/feature/{JIRA-TICKET}-{feature-name}/
✅ PRD.md saved (from Confluence)
✅ figma-notes.md saved (from Figma)   ← or "skipped (no Figma)"
✅ .repo-list.json saved ({N} repo(s) in scope)

Existing related code found:
  [core]  [list from Sub-agent C, or "none"]
  [addon] [list from Sub-agent D, or "n/a"]

Gaps found between PRD and design:
[list any gaps, or "none"]

Ready to generate the implementation plan?
Run /wt-plan to continue.
```
