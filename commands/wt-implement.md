---
model: claude-sonnet-4-6
---

---

> ⚠️ **STRICT STRUCTURE RULE**
> `CLAUDE.md`, `Skills/`, `.context/`, and `ai-context/` must **always** live at the **git repository root** — never inside a plugin subfolder (e.g. never inside `webtoffee-product-feed-pro/`).
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

# /wt-implement — Implement tasks from plan.md

You are acting as a Senior WordPress/WooCommerce plugin developer.

## Instructions

---

### Step 0: Plan Approval Gate

Before doing anything else, check whether implementation is allowed.

**Read the current branch:**
```bash
git branch --show-current
```

**Determine ticket type:**
- Branch starts with `feature/IS-*` → **Feature ticket** — plan approval is REQUIRED
- Branch starts with `fix/ISCS-*`   → **Support ticket** — ask:
  ```
  Does this fix require changes to plugin files on this branch? (yes / no)
  ```
  - **yes** → plan approval is REQUIRED
  - **no** (standalone code snippet only, no branch file changes) → skip gate, proceed to Step 1

**For any case where plan approval is REQUIRED:**

Check if `.plan-approved` exists:
```
Skills/feature/{ticket}-{name}/.plan-approved
```

Also check `Support/{ticket}/.plan-approved` for support tickets.

If `.plan-approved` does NOT exist → **STOP**:
```
🚫 Implementation blocked.

The plan for {ticket} has not been approved yet.

Steps to unblock:
1. Run /wt-design-review to push the plan to Bitbucket
2. Assign a reviewer and wait for their approval
3. Once approved, run /wt-implement again

Do not implement on this branch until the plan is approved.
```

If `.plan-approved` EXISTS → show:
```
✅ Plan approved — implementation is unblocked.
   Approved by: {approved_by from file}
   PR: {pr_url from file}
```
Then proceed to Step 1.

---

### Step 1: Restore session context + find the active plan

**Load saved plan context (AI Engineering Playbook — session continuity):**
Invoke the **context-load-plan** skill to restore the approved plan from `.context/plans/` into the current session. This ensures implementation always starts from the saved, approved plan — not from memory.

If no saved plan is found → look for `plan.md` under `Skills/feature/` subfolders as fallback.
If multiple exist, ask the user which feature to implement.

**Read /ai-context/ files (plugin-specific context):**
```
ai-context/architecture.md
ai-context/coding-standards.md
ai-context/testing-standards.md
ai-context/observability-standards.md
```
These must be loaded before writing any code. If not present, remind the user to run `/wt-init-plugin`.

**Check iteration counter:**
Read `Skills/feature/{ticket}-{name}/.claude-iterations` (create with value `0` if missing).
Increment by 1 and save. If the count reaches **5**:
```
⚠️  Iteration limit reached (5/5).

Claude has made 5 implementation passes on this feature.
This is a signal to pause and get human input before continuing.

Please review the current state of the code and tell me:
1. What is still not working?
2. Should I continue, or do you want to take over this part?

Type your answer to continue.
```
Wait for the user to respond before proceeding.

---

### Step 2: Load WordPress skills

Always invoke:
1. **wp-plugin-development** — architecture rules, security patterns, coding standards

Then check plan.md for additional skill requirements:
- Plan has REST endpoints       → invoke **wp-rest-api** skill
- Plan has Gutenberg blocks     → invoke **wp-block-development** skill
- Plan has admin settings UI    → invoke **wpds** skill
- Plan has Interactivity API    → invoke **wp-interactivity-api** skill
- Plan has queries or caching   → invoke **wp-performance** skill
- Plan has WP-CLI               → invoke **wp-wpcli-and-ops** skill

---

### Step 3: Pre-implementation codebase research (sub-agents)

Before writing any code, launch the following sub-agents **simultaneously** using the Agent tool:

**Sub-agent A — Existing class structure (`code-explorer` agent — haiku, effort: medium):**
- Read the most similar existing class in `includes/` (identified in plan.md under "Existing Patterns to Follow")
- Return: full class structure, method signatures, constructor, hook registrations

**Sub-agent B — Constants & config (`code-explorer` agent — haiku, effort: medium):**
- Scan `includes/` for all defined constants, plugin options keys, and any config/registry arrays
- Return: list of constants and option keys already in use (to avoid conflicts)

**Sub-agent C — Test coverage baseline (`code-explorer` agent — haiku, effort: medium):**
- Scan `tests/unit/` to see what test patterns already exist
- Return: example test file structure to follow for new tests

Wait for all three sub-agents before starting Task 1.

---

### Step 4: Work through tasks in plan mode

For each pending task in dependency order:

1. Mark task `in_progress`
2. **Launch a task-specific `code-explorer` sub-agent (haiku, effort: medium)** to read any files this task touches or extends — get the latest method signatures and hook registrations before writing
3. Show the user what you are about to write — file name, class name, methods planned
4. Write the code following ALL rules below
5. Check auto-review output (PHPCS hook fires automatically on every file save)
6. Fix any PHPCS errors before moving to the next task
7. Mark task `completed`

---

### Non-negotiable coding rules

**Naming (read prefix from CLAUDE.md):**
- Classes:    `PREFIX_Class_Name`
- Functions:  `prefix_function_name()`
- Hooks:      `prefix_hook_name`
- Constants:  `PREFIX_CONSTANT_NAME`

**Security — every file, no exceptions:**
- Sanitize ALL inputs:  `sanitize_text_field()`, `sanitize_email()`, `absint()`, etc.
- Escape ALL outputs:   `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses_post()`
- Nonces on ALL forms and AJAX: `wp_nonce_field()` + `check_admin_referer()`
- Capability check on ALL admin actions: `current_user_can()`
- ALL DB queries: `$wpdb->prepare()`
- ABSPATH check at top of every file: `defined( 'ABSPATH' ) || exit;`

**Architecture:**
- Singleton pattern for main plugin class
- Register all hooks in a dedicated Hooks class
- Settings API for all admin options — never custom form handlers
- Never modify WooCommerce core files
- HPOS compatible: use `wc_get_order()` not `get_post()`
- No deprecated WooCommerce hooks
- DocBlocks on every class and public method

**WordPress code style:**
- Tabs for indentation
- Yoda conditions: `if ( 'value' === $variable )`
- Space inside parentheses: `if ( $condition )`
- No short PHP tags
- Single quotes for strings unless interpolation needed

---

### Step 5: After every 3 tasks

Run the full PHPUnit suite:
```bash
./vendor/bin/phpunit --testdox 2>&1
```

If tests fail — fix before continuing.

---

### Step 6: Completion

When all tasks are done:
```
✅ All [X] tasks completed.

Files created / modified:
[list]

Next steps:
1. Test in browser (Local Sites — already live via symlink)
2. Run /wt-test  → generate + run unit tests
3. Run /wt-review → full code audit
4. Run /wt-qa    → all gates must pass before committing
```
