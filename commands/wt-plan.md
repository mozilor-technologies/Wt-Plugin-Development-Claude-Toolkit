---
model: claude-opus-4-6
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
- `Tasks/feature/{ticket}-{name}/.repo-list.json` (if exists — used to group tasks by plugin)

If `.repo-list.json` exists and contains addon entries, this is a **multi-plugin feature**. Each repo gets its own `plan.md` saved in its own `Tasks/feature/{ticket}-{name}/` folder — no `Plugin:` tags needed.

---

### Step 2: Load plugin context + WordPress skills

**Read /ai-context/ files first (if they exist):**
```
ai-context/architecture.md
ai-context/coding-standards.md
ai-context/testing-standards.md
ai-context/observability-standards.md
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

**Sub-agent A — Existing class map in primary repo (`code-explorer` agent — haiku, effort: medium):**
- Scan `includes/` in the primary repo and list all existing classes, their file paths, and their primary responsibility
- Identify which classes are most relevant to this feature
- Return: structured list of `ClassName → file path → purpose`

**Sub-agent B — Hook & filter inventory in primary repo (`code-explorer` agent — haiku, effort: medium):**
- Scan `includes/` in the primary repo for all `add_action`, `add_filter`, `do_action`, `apply_filters` calls
- Return: list of all registered hooks and filters already in use

**Sub-agent C — Similar feature patterns in primary repo (`code-explorer` agent — haiku, effort: medium):**
- Based on the PRD topic, find the most similar existing feature in `includes/` of the primary repo
- Read that implementation in detail — class structure, method signatures, hook usage
- Return: the pattern to follow for the new feature (with file references)

**Sub-agent D — Jira ticket details (`prd-fetcher` agent — haiku, effort: low):**
- Use the Atlassian MCP to fetch the Jira ticket from the PRD
- Return: ticket title, description, acceptance criteria, linked tickets

**Sub-agents E+ — Addon repo scans (only if `.repo-list.json` has addon entries):**
- For each addon repo, launch a `code-explorer` sub-agent (haiku, effort: medium):
  - Scan `{addon.local_path}/includes/` for class map and hook inventory
  - Return: structured list of `ClassName → file path → purpose` for that addon

Wait for all sub-agents to complete before writing the plan.

---

### Step 4: Generate per-repo plan files (Opus — effort: high)

> This step runs on **claude-opus-4-6** (set in skill frontmatter). Deep architectural reasoning — synthesizes research from all sub-agents into one plan per repo.

#### 4a — Single-repo

Write one file: `Tasks/feature/{ticket}-{name}/plan.md` (standard structure, no changes needed).

#### 4b — Multi-repo

Write **one `plan.md` per repo in scope**, each saved in that repo's own feature folder:

| Repo | Plan file path |
|---|---|
| product-feed-xyz (wrapper) | `Tasks/feature/{ticket}-{name}/plan.md` |
| wt-addon-subscriptions | `{addon.local_path}/Tasks/feature/{ticket}-{name}/plan.md` |

Each plan file contains **only the tasks for that repo** — no `Plugin:` tag needed (the file's location makes the repo implicit).

**Also write** `Tasks/feature/{ticket}-{name}/plan-overview.md` in the wrapper repo as a cross-repo coordination document:

```markdown
# Plan Overview: [Feature Name]
Jira: IS-123
Generated: [date]
Repos in scope: product-feed-xyz, wt-addon-subscriptions

## Cross-repo Architecture
[How the feature spans repos — integration points, shared hooks, data contracts]

## Dependency Order
1. product-feed-xyz — Tasks 1–3 must be complete before addon work begins
2. wt-addon-subscriptions — Tasks 4–5 depend on hooks added in step 1

## Per-repo Plan Files
- Wrapper: Tasks/feature/{ticket}-{name}/plan.md
- Addon (wt-addon-subscriptions): {addon.local_path}/Tasks/feature/{ticket}-{name}/plan.md

## Shared Integration Points
[Hooks the wrapper exposes that the addon consumes, option keys, REST routes, etc.]
```

**Per-repo `plan.md` structure** (used for both wrapper and each addon):

```markdown
# Plan: [Feature Name] — [{repo-slug}]
Jira: IS-123
Repo: {repo-slug}
Generated: [date]

## Summary
[What this repo's portion of the feature does]

## Architecture Decisions
[Class structure, hook strategy, data storage decisions for this repo only]

## Files to Create
| File | Class | Purpose |
|---|---|---|
| includes/[path]/class-[name].php | PREFIX_Class_Name | description |

## Files to Modify
| File | Change |
|---|---|
| admin/class-hooks.php | description |

## Implementation Tasks

### Task 1: [name]
- File: `includes/[path]/class-[name].php`
- Class: `PREFIX_Class_Name`
- What: [precise description]
- Key logic: [specific implementation notes]
- Reuse: [which existing class/pattern to base this on]
- Depends on: none

### Task 2: [name]
...

## Hooks & Filters
| Hook | Type | Purpose |
|---|---|---|
| prefix_{name} | filter | description |

## Database Changes
[New tables, meta keys, options — or "none"]

## Tests to Write
| Class | Method | Scenarios |
|---|---|---|
| PREFIX_Class_Name | method | happy path, empty, null, WC edge cases |

## Security Checklist
- [ ] All inputs sanitized
- [ ] All outputs escaped
- [ ] Nonces on all forms/AJAX
- [ ] Capability checks on admin actions
- [ ] All DB queries use $wpdb->prepare()
```

---

### Step 5: Show plans to user

**Single-repo:** display `plan.md` and ask:
```
Does this plan look right? (yes / change something)
```

**Multi-repo:** display `plan-overview.md` first (cross-repo architecture), then each per-repo `plan.md` in order (wrapper first, then addons). Ask once after showing all:
```
Do all per-repo plans look right? (yes / change something — specify which repo)
```

If changes requested — update the relevant plan file and show again.
Repeat until all plans are confirmed.

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
```

- Branch name must follow: `feature/IS-{ticket}-{description}` for features, `fix/ISCS-{ticket}-{description}` for support
- If branch creation fails (already exists remotely) → `git checkout feature/IS-{ticket}-{feature-name}`

3. Save plans for session persistence and commit tracing:
   Invoke the **context-save-plan** skill for each plan file — saves all plans to `.context/plans/` so they survive session resets and link future commits back to this plan set.

4. Confirm and show next step:

**Single-repo:**
```
✅ Plan approved and saved to Tasks/feature/IS-123-name/plan.md
✅ Plan saved to .context/plans/ (session-persistent, commit-traceable)
✅ Branch ready: feature/IS-123-tiktok-shop-feed
[X] tasks ready for design review.

Next step: Run /wt-design-review to push the plan to Bitbucket for approval.
⚠️  /wt-implement is blocked until the plan is approved by a reviewer.
```

**Multi-repo:**
```
✅ Plans approved and saved:
   Tasks/feature/IS-123-name/plan-overview.md   ← cross-repo architecture
   Tasks/feature/IS-123-name/plan.md            ← product-feed-xyz ([N] tasks)
   {addon_path}/Tasks/feature/IS-123-name/plan.md ← wt-addon-subscriptions ([N] tasks)
✅ All plans saved to .context/plans/
✅ Branch ready in all repos: feature/IS-123-tiktok-shop-feed
[X] total tasks across [N] repos — ready for design review.

Next step: Run /wt-design-review to push the plans to Bitbucket for approval.
⚠️  /wt-implement is blocked until the plans are approved by a reviewer.
```
