---
model: claude-haiku-4-5-20251001
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

# /wt-init-plugin

Initialize a new plugin with CLAUDE.md configuration.

Use this when you're setting up a new WordPress plugin for the first time, or adding an existing plugin to your development workflow.

**Usage:**
```bash
cd /path/to/wordpress/plugin
/wt-init-plugin
```

---

## What This Command Does

1. Validates that you're in a WordPress plugin directory
2. Asks for plugin configuration details interactively:
   - Plugin slug (machine-readable name)
   - Plugin prefix (for code, constants, etc.)
   - Jira project key (for feature vs support tickets)
   - Bitbucket repository
   - Min WordPress & WooCommerce versions
   - PR reviewer email
   - QA tester email
3. Creates/updates `CLAUDE.md` with your answers
4. Confirms setup is complete

After this, all `/wt-*` commands work in this plugin directory.

---

## Interactive Prompts

The command will ask:

```
Plugin Slug (e.g., product-feed-xyz):
  → Used in file names, Jira tickets, branch names

Plugin Code Prefix (e.g., WTPFX_):
  → Used for constants, function prefixes, text domains

Jira Project Key for Features (e.g., IS):
  → Feature tickets come from here

Jira Project Key for Support (e.g., ISCS):
  → Bug/support tickets come from here (optional)

Bitbucket Repository (e.g., webtoffee/product-feed-xyz):
  → Where code is committed

Min WordPress Version (e.g., 6.0):
  → Your plugin's minimum WordPress requirement

Min WooCommerce Version (e.g., 8.0):
  → Your plugin's minimum WooCommerce requirement

PR Reviewer Email (your-email@mozilor.com):
  → Who reviews pull requests

QA Tester Email (optional):
  → Who tests before release
```

---

## Example: Setting Up a New Plugin

```bash
# Clone a new plugin
git clone https://bitbucket.org/webtoffee/product-feed-xyz.git \
  ~/Local\ Sites/my-site/app/public/wp-content/plugins/product-feed-xyz

# Navigate to it
cd ~/Local\ Sites/my-site/app/public/wp-content/plugins/product-feed-xyz

# Open Claude Code
claude

# Initialize it
/wt-init-plugin

# Answer the prompts → CLAUDE.md is created
# Now start your first feature:
/wt-feature
```

---

## Step: Create /.context/ context files

After `CLAUDE.md` is created, generate a `/.context/` directory in the repository root with four AI-readable context files. These are read automatically by `/wt-plan` and `/wt-implement` to give Claude accurate, plugin-specific context before generating plans or writing code.

Create each file using the plugin config the user provided:

**`.context/architecture.md`**
```markdown
# Architecture: {Plugin Name}

## Plugin Type
WordPress + WooCommerce plugin. Prefix: {PREFIX}_. Text domain: {slug}.

## Main Entry Point
{main-plugin-file}.php → bootstraps the plugin. Singleton main class.

## Folder Structure
- includes/           — All PHP classes (PSR-4 autoloaded or manually required)
- admin/              — Admin-only classes, templates, assets
- admin/modules/      — Per-channel/feature modules (each is a self-contained subfolder)
- assets/             — JS, CSS, images
- templates/          — Frontend templates (if any)
- tests/              — PHPUnit tests (unit + integration)

## Class Naming Convention
{PREFIX}_Class_Name → file: includes/class-{prefix}-class-name.php
Channel modules: admin/modules/{channel}/{channel}.php

## Hook Registration
All hooks registered in a dedicated Hooks class (includes/class-{prefix}-hooks.php or similar).
Never register hooks in constructors of non-singleton classes.

## Data Flow
WooCommerce products → feed module → column mapping → export/CSV generation

## WooCommerce Compatibility
- HPOS enabled: use wc_get_order() not get_post() for orders
- Min WC: {min_wc}
- No deprecated WC hooks
```

**`.context/coding-standards.md`**
```markdown
# Coding Standards: {Plugin Name}

## PHPCS Standard Detection

Before running PHPCS, check the main plugin file header using these two signals (in order):

1. Check for a `Woo:` tag:
```bash
grep -i "^\s*\*\s*Woo:" {main-plugin-file}.php
```

2. If no `Woo:` tag, check the `Plugin URI`:
```bash
grep -i "^\s*\*\s*Plugin URI:" {main-plugin-file}.php
```

| Result | Plugin Type | Standard to Apply |
|--------|------------|-------------------|
| `Woo:` tag found | WooCommerce Marketplace | WooCommerce standard only — 0 errors |
| `Woo:` tag absent + `Plugin URI` contains `woocommerce.com/products` | WooCommerce Marketplace | WooCommerce standard only — 0 errors |
| `Woo:` tag absent + `Plugin URI` does NOT contain `woocommerce.com/products` | WordPress.org plugin | WordPress standard only — 0 errors |

Never run both standards on the same plugin — apply only the one that matches.

## PHP Style
- Tabs for indentation (not spaces)
- Yoda conditions: if ( 'value' === $variable )
- Space inside parentheses: if ( $condition )
- No short PHP tags
- Single quotes for strings unless interpolation needed

## Security (non-negotiable, every file)
- Sanitize ALL inputs: sanitize_text_field(), sanitize_email(), absint(), etc.
- Escape ALL outputs: esc_html(), esc_attr(), esc_url(), wp_kses_post()
- Nonces on ALL forms and AJAX: wp_nonce_field() + check_admin_referer()
- Capability check on ALL admin actions: current_user_can()
- ALL DB queries: $wpdb->prepare()
- ABSPATH check at top of every file: defined( 'ABSPATH' ) || exit;

## Architecture Rules
- Singleton pattern for main plugin class
- Register all hooks in a dedicated Hooks class
- Settings API for all admin options — never custom form handlers
- Never modify WooCommerce core files
- DocBlocks on every class and public method

## Prefix
All classes, functions, hooks, constants must be prefixed with: {PREFIX}
```

**`.context/testing-standards.md`**
```markdown
# Testing Standards: {Plugin Name}

## Stack
- PHPUnit ^9.5
- Brain Monkey ^2.6 (WordPress function mocking)
- Mockery ^1.5 (object mocking)
- Bootstrap: tests/bootstrap.php (stubs WP/WC functions and classes)

## Test Location
- Unit tests: tests/unit/test-{class-slug}.php
- Integration tests: tests/integration/ (if applicable)

## Naming Convention
- Class: Test_{ClassName} extends WP_UnitTestCase
- File: tests/unit/test-{class-slug}.php
- Method: test_{method_name}_{scenario}()

## Coverage Requirements
- Every public method has at least one test
- Happy path tested
- Edge cases: empty input, null, invalid types
- WooCommerce specific: out of stock, variable products, missing data
- Target: ≥ 70% line coverage

## WooCommerce Mocking
- WC_Helper_Product::create_simple_product()
- WC_Helper_Product::create_variation_product()
- WC_Helper_Order::create_order()

## Run Tests
./vendor/bin/phpunit --testdox 2>&1
./vendor/bin/phpunit --coverage-text 2>&1
```

**`.context/observability-standards.md`**
```markdown
# Observability Standards: {Plugin Name}

## Logging
- Use WooCommerce logger: wc_get_logger()->error/warning/info/debug()
- Log context: always pass ['source' => '{plugin-slug}'] as second argument
- Log on: feed generation errors, export failures, API call failures
- Never log sensitive data (passwords, API keys, personal data)
- Log level guide:
  - error   → something failed and the user is affected
  - warning → something unexpected but recoverable
  - info    → significant lifecycle events (feed generated, module loaded)
  - debug   → verbose output for developer troubleshooting only

## Error Handling
- Never silently swallow exceptions — always log or rethrow
- Return WP_Error objects from methods that can fail (not false/null)
- Admin notices: use add_settings_error() or custom notice hooks for user-facing errors
- No bare try/catch without logging

## No Silent Failures
- Every catch block must call wc_get_logger()->error() with context
- Every false return from an important method should be accompanied by a log entry
- AJAX handlers: always return wp_send_json_error() with a message on failure

## Monitoring
- Feed generation time should be observable via WC logs
- Failed exports should log the feed ID, product count, and error message
```

After creating these four files, invoke the **context-init** skill to initialise the `.context/` folder. This enables plan persistence and commit-to-plan traceability across sessions (part of the AI Engineering Playbook workflow).

Show:
```
✅ /.context/ created with 4 context files:
   .context/architecture.md
   .context/coding-standards.md
   .context/testing-standards.md
   .context/observability-standards.md

✅ .context/ initialised (plan persistence + commit tracing)

These files are read automatically by /wt-plan and /wt-implement.
Edit them any time to update Claude's understanding of this plugin.
```

---

## What Gets Created

A `CLAUDE.md` file in your repository root with:

```markdown
# Plugin: Product Feed XYZ

## Plugin Config
- Plugin slug: product-feed-xyz
- Plugin prefix: WTPFX_
- Min WP: 6.0 | Min WC: 8.0
- Text domain: product-feed-xyz

## Jira
- Feature project: IS
- Support project: ISCS

## Bitbucket
- Workspace: https://bitbucket.org/webtoffee
- Repo: product-feed-xyz
- PR Reviewers: your-email@mozilor.com

## QA Tester
- Email: qa-email@mozilor.com (optional)

## Branch Naming
- Feature: feature/IS-{ticket}-{description}
- Support: fix/ISCS-{ticket}-{description}

## Workflow Commands
All `/wt-*` commands now work in this plugin:
- /wt-feature — Start a new feature
- /wt-plan — Generate implementation plan
- /wt-implement — Build the feature
- /wt-test — Generate and run tests
- /wt-review — Full code review
- /wt-qa — QA pipeline
- /wt-commit — Commit to Bitbucket
- /wt-fix-review — Fix PR comments
- /wt-release — Create a release
```

---

## One-Time vs. One-Per-Plugin

- **One-Time Setup:** `setup.sh` (configures ~/.claude/ globally)
- **One-Per-Plugin:** `/wt-init-plugin` (creates CLAUDE.md for each new plugin)

You never need to re-run `setup.sh`. For every new plugin:
1. Clone it
2. Run `/wt-init-plugin`
3. Start developing with `/wt-feature`

---

## Already Have a CLAUDE.md?

If the plugin already has `CLAUDE.md`, the command will:
- Show you the existing config
- Ask if you want to update it
- Keep your current settings by default

---

## Next Steps After Init

1. ✅ Plugin initialized with `/wt-init-plugin`
2. 📋 Read the PRD or Jira ticket for your feature
3. 🚀 Start with `/wt-feature`

That's it. The rest is automated.

---

## Troubleshooting

**"Not a WordPress plugin directory"**
- Make sure you're in the repository root (where plugin.php is)
- Check that the directory has WordPress plugin files

**"CLAUDE.md already exists"**
- The command will ask if you want to update it
- Choose "no" to keep existing config
- Choose "yes" to update with new values

**"I made a mistake in CLAUDE.md"**
- Edit it manually (it's just Markdown)
- Or delete it and run `/wt-init-plugin` again

---

## Need More Help?

- **First plugin setup**: `cat ~/.claude/ONBOARDING_SUMMARY.md`
- **Full workflow**: `cat ~/.claude/WORKFLOW_TEAM_REVIEW.md`
- **Troubleshooting**: `cat ~/.claude/DEVELOPER_SETUP.md`
