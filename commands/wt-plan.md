---
model: claude-opus-4-6
---

---

> ⚠️ **STRICT STRUCTURE RULE**
> `CLAUDE.md`, `Tasks/`, `.context/` must **always** live at the **git repository root** — never inside a plugin subfolder (e.g. never inside `webtoffee-product-feed-pro/`).
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

# /wt-plan — Generate implementation plan from PRD + Figma notes

You are acting as a Senior WordPress/WooCommerce plugin architect.

## Instructions

---

### Step 1: Find the feature folder

Look for the most recently modified folder under `Tasks/feature/`.
If multiple folders exist, ask:
```
Which feature do you want to plan?
[list folders found under Tasks/feature/]
```

Read:
- `Tasks/feature/{ticket}-{name}/PRD.md`
- `Tasks/feature/{ticket}-{name}/figma-notes.md` (if exists)

---

### Step 2: Load plugin context + WordPress skills

**Read /.context/ files first (if they exist):**
```
.context/architecture.md
.context/coding-standards.md
.context/testing-standards.md
.context/observability-standards.md
```
These files give you plugin-specific architecture, conventions, and constraints that override generic assumptions. If they don't exist yet, remind the user to run `/wt-init-plugin` to generate them.

**Then invoke WordPress skills in order:**

1. **wordpress-router** — classifies this repo (plugin type, prefix, WC dependency)
2. **wp-plugin-development** — loads architecture rules, security patterns, hook standards

Then check PRD.md for additional skill requirements:
- PRD mentions REST API endpoints → invoke **wp-rest-api** skill
- PRD mentions Gutenberg blocks → invoke **wp-block-development** skill
- PRD mentions admin UI / settings pages → invoke **wpds** skill
- PRD mentions WP-CLI → invoke **wp-wpcli-and-ops** skill
- PRD mentions performance / caching → invoke **wp-performance** skill

---

### Step 3: Launch parallel research sub-agents

Launch the following sub-agents **simultaneously** using the Agent tool to research the codebase before planning:

**Sub-agent A — Existing class map (`code-explorer` agent — haiku, effort: medium):**
- Scan `includes/` and list all existing classes, their file paths, and their primary responsibility
- Identify which classes are most relevant to this feature
- Return: structured list of `ClassName → file path → purpose`

**Sub-agent B — Hook & filter inventory (`code-explorer` agent — haiku, effort: medium):**
- Scan `includes/` for all `add_action`, `add_filter`, `do_action`, `apply_filters` calls
- Return: list of all registered hooks and filters already in use

**Sub-agent C — Similar feature patterns (`code-explorer` agent — haiku, effort: medium):**
- Based on the PRD topic, find the most similar existing feature in `includes/`
- Read that implementation in detail — class structure, method signatures, hook usage
- Return: the pattern to follow for the new feature (with file references)

**Sub-agent D — Jira ticket details (`prd-fetcher` agent — haiku, effort: low):**
- Use the Atlassian MCP to fetch the Jira ticket from the PRD
- Return: ticket title, description, acceptance criteria, linked tickets

Wait for all four sub-agents to complete before writing the plan.

---

### Step 4: Generate plan.md (Opus — effort: high)

> This step runs on **claude-opus-4-6** (set in skill frontmatter). Deep architectural reasoning — takes all research from sub-agents and synthesizes a precise, developer-ready plan.

Write `Tasks/feature/{ticket}-{name}/plan.md` using this structure:

```markdown
# Plan: [Feature Name]
Jira: IS-123
Generated: [date]

## Architecture Overview
[How this feature fits into the plugin architecture]
[Which existing classes are touched — from Sub-agent A]
[Which new classes are needed]

## Existing Patterns to Follow
[From Sub-agent C — the similar feature to model this after]

## File Structure
[List every file to create or modify]

## Implementation Tasks
[Ordered by dependency — each task is one atomic unit]

### Task 1: [name]
- File: includes/[path]/class-[name].php
- What: [description]
- Hooks: [WordPress/WooCommerce hooks needed — from Sub-agent B]
- Security: [sanitization, escaping, nonces needed]
- Depends on: none

### Task 2: [name]
...

## WooCommerce Integration Points
[Exact hook names, filter names, WC classes used]

## Admin UI
[Settings API pages, meta boxes, columns — matching Figma design]

## Database Changes
[New tables, meta keys, options — or "none"]

## Security Checklist
[ ] All inputs sanitized with sanitize_*()
[ ] All outputs escaped with esc_*()
[ ] Nonces on all form submissions
[ ] Capability checks on all admin actions
[ ] $wpdb->prepare() on all queries

## Testing Strategy
[What unit tests are needed, what to mock]
```

---

### Step 5: Show plan to user

Display the full `plan.md` content and ask:
```
Does this plan look right? (yes / change something)
```

If they want changes — update `plan.md` and show again.
Repeat until confirmed.

---

### Step 6: Confirm and hand off

Once approved:

1. Check if a branch already exists for this ticket:
```bash
git branch --list "feature/IS-*" "fix/ISCS-*"
git branch --show-current
```

2. If already on the correct branch → skip creation.
   If not → create and switch:
```bash
git checkout -b feature/IS-{ticket}-{feature-name}
# e.g. git checkout -b feature/IS-123-tiktok-shop-feed
```

- Branch name must follow: `feature/IS-{ticket}-{description}` for features, `fix/ISCS-{ticket}-{description}` for support
- If branch creation fails (already exists remotely) → `git checkout feature/IS-{ticket}-{feature-name}`

3. Save the plan for session persistence and commit tracing:
   Invoke the **context-save-plan** skill — this saves the approved plan to `.context/plans/` so it survives session resets and links future commits back to this plan.

4. Confirm and show next step:
```
✅ Plan approved and saved to Tasks/feature/IS-123-name/plan.md
✅ Plan saved to .context/plans/ (session-persistent, commit-traceable)
✅ Branch ready: feature/IS-123-tiktok-shop-feed
[X] tasks ready for design review.

Next step: Run /wt-design-review to push the plan to Bitbucket for approval.
⚠️  /wt-implement is blocked until the plan is approved by a reviewer.
```
