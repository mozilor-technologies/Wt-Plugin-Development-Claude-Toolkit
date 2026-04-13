# WebToffee Plugin Development Claude Toolkit

A local Claude Code toolkit for developing WebToffee WordPress/WooCommerce plugins. Provides AI-powered slash commands, custom agents, skills, and automation hooks — all scoped to each plugin locally (nothing installed globally).

---

## Table of Contents

- [What This Toolkit Does](#what-this-toolkit-does)
- [Prerequisites](#prerequisites)
- [Developer Setup](#developer-setup)
- [Plugin Setup](#plugin-setup)
- [Credentials Configuration](#credentials-configuration)
- [Folder Structure](#folder-structure)
- [Complete Workflow](#complete-workflow)
  - [New Feature](#new-feature-workflow)
  - [Support Ticket (Bug Fix)](#support-ticket-workflow)
  - [Release](#release-workflow)
- [Slash Commands Reference](#slash-commands-reference)
- [Agents Reference](#agents-reference)
- [Skills Reference](#skills-reference)
- [Automation Hooks](#automation-hooks)
- [Branch Strategy](#branch-strategy)
- [Updating the Toolkit](#updating-the-toolkit)

---

## What This Toolkit Does

This toolkit gives every developer on the team the same AI-powered development workflow inside Claude Code:

- **Slash commands** — `/wt-feature`, `/wt-plan`, `/wt-implement`, `/wt-qa`, `/wt-commit`, and more
- **Custom agents** — specialized AI sub-agents for planning, building, reviewing, and QA
- **Skills** — WordPress/WooCommerce domain knowledge loaded into every session
- **Automation hooks** — PHPCS runs after every PHP file save; PHPUnit runs when Claude stops; pre-commit blocks bad code
- **Session continuity** — plan files and context survive session resets

Everything lives in the plugin's `.claude/` folder on the developer's machine. Nothing is committed to the plugin repo.

---

## Prerequisites

Install these once on your machine before setup:

| Tool | Install | Why |
|---|---|---|
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | The AI CLI |
| **uvx** | `pip install uv` | Runs the Atlassian MCP server |
| **npx** | Included with Node.js | Runs the Figma MCP server |
| **Git** | `brew install git` | Source control |
| **PHP + Composer** | `brew install php` | For PHPCS/PHPUnit |
| **SSH key** | `ssh-keygen -t ed25519` | Bitbucket access |

Add your SSH public key to Bitbucket:
`bitbucket.org → Personal settings → SSH keys`

---

## Developer Setup

Run this **once** on a new machine:

```bash
# 1. Clone the toolkit
git clone git@bitbucket.org:webtoffee/wt-plugin-development-claude-toolkit.git ~/wt-plugin-development-claude-toolkit

# 2. Go to the plugin you want to work on
cd /path/to/your-plugin

# 3. Run the installer
~/wt-plugin-development-claude-toolkit/install.sh
```

The installer will:
- Create `.claude/agents/`, `.claude/skills/`, `.claude/scripts/`, `.claude/commands/` in the plugin folder
- Copy `settings.json.example` → `.claude/settings.json`
- Add `.claude/` to `.gitignore` (so your local toolkit is never committed)

---

## Plugin Setup

After running the installer, configure your credentials:

```bash
nano .claude/settings.json
```

Replace all placeholder values (see [Credentials Configuration](#credentials-configuration) below).

Then update the hook script paths — replace `/absolute/path/to/plugin/` with your actual plugin path everywhere in `settings.json`:

```bash
# Find your plugin path
pwd
```

Finally, initialize the plugin for the wt-* workflow:

```bash
# Open Claude Code inside the plugin
claude

# Run the init command
/wt-init-plugin
```

This creates `CLAUDE.md` (plugin config) and `ai-context/` files used by all wt-* commands.

---

## Credentials Configuration

Edit `.claude/settings.json` and fill in:

### Atlassian (Jira + Confluence)
1. Go to: `https://id.atlassian.com → Security → API tokens`
2. Create a new token
3. Fill in:
   ```json
   "CONFLUENCE_USERNAME": "your-email@mozilor.com",
   "CONFLUENCE_API_TOKEN": "your-token",
   "JIRA_USERNAME": "your-email@mozilor.com",
   "JIRA_API_TOKEN": "your-token"
   ```

### Bitbucket
1. Go to: `bitbucket.org → Personal settings → App passwords`
2. Create with permissions: Repositories (read/write), Pull requests (read/write)
3. Fill in:
   ```json
   "BITBUCKET_USERNAME": "your-email@mozilor.com",
   "BITBUCKET_API_TOKEN": "your-app-password"
   ```

### Figma
1. Go to: `figma.com → Account → Personal access tokens`
2. Create a token
3. Fill in:
   ```json
   "FIGMA_ACCESS_TOKEN": "your-token"
   ```

### Hook Paths
Update all four hook command paths to use your actual plugin directory:

```json
"command": "bash \"/Users/yourname/path/to/plugin/.claude/scripts/auto-review.sh\" ..."
```

---

## Folder Structure

After setup, each plugin has this structure:

```
your-plugin/
├── CLAUDE.md                    ← plugin config (committed to repo)
├── ai-context/                  ← AI context files (committed to repo)
│   ├── architecture.md
│   ├── coding-standards.md
│   ├── testing-standards.md
│   └── observability-standards.md
├── .claude/                     ← LOCAL ONLY — gitignored
│   ├── settings.json            ← your credentials + hooks
│   ├── settings.json.example    ← template (no credentials)
│   ├── commands/                ← 19 wt-* slash commands
│   ├── agents/                  ← 9 custom AI agents
│   ├── skills/                  ← 18 wp-* + context skills
│   └── scripts/                 ← automation bash scripts
├── Skills/
│   └── feature/
│       └── IS-123-feature-name/
│           ├── PRD.md
│           ├── figma-notes.md
│           └── plan.md
├── .context/
│   └── plans/                   ← session-persistent plan files
└── webtoffee-product-feed/      ← actual plugin code
```

---

## Complete Workflow

### New Feature Workflow

```
Jira ticket created
       ↓
/wt-feature      ← reads PRD from Confluence + Figma design
       ↓
/wt-plan         ← generates implementation plan
       ↓
/wt-design-review ← pushes plan to Bitbucket for approval
       ↓         (reviewer approves on Bitbucket)
/wt-implement    ← builds the feature, task by task
       ↓
Browser test     ← test in Local Sites
       ↓
/wt-test         ← generates + runs PHPUnit tests
       ↓
/wt-security     ← security audit
       ↓
/wt-review       ← full code review (PHPCS + WC compat + performance)
       ↓
/wt-qa           ← 5-phase QA gate (must all pass)
       ↓
/wt-commit       ← commit + push to Bitbucket, creates PR
       ↓
/wt-fix-review   ← fix any PR review comments
       ↓
PR approved + merged
       ↓
/wt-qa-ticket    ← creates QA handoff ticket for tester
```

Or run the entire pipeline automatically:
```bash
/wt-build IS-123
```

---

### Support Ticket Workflow

```
Support ticket reported (ISCS-456)
       ↓
/wt-support ISCS-456   ← triage, root cause, fix plan
       ↓
/wt-implement          ← implement the fix
       ↓
/wt-test               ← run tests
       ↓
/wt-review             ← code review
       ↓
/wt-qa                 ← QA gate
       ↓
/wt-commit             ← commit + PR
       ↓
/wt-qa-ticket          ← QA handoff
```

---

### Release Workflow

```
All features merged to release branch
       ↓
/wt-release            ← bumps version, updates changelog, builds zip
```

---

## Slash Commands Reference

Run any command inside Claude Code by typing `/command-name`.

### Pipeline Commands

| Command | What It Does |
|---|---|
| `/wt-build` | Full automated pipeline from PRD to PR (use for any feature) |
| `/wt-orchestrator` | Smart pipeline — scores complexity and runs only needed agents |

### Feature Development

| Command | What It Does |
|---|---|
| `/wt-feature` | Reads Confluence PRD + Figma design, creates `Skills/feature/IS-{n}/` folder with `PRD.md` and `figma-notes.md` |
| `/wt-plan` | Generates `plan.md` from PRD + codebase research. Uses Opus for architectural thinking |
| `/wt-design-review` | Pushes plan to Bitbucket for review. Simple changes (score 0–1) get inline approval. Complex changes get a plan review PR |
| `/wt-implement` | Builds the feature task by task following plan.md. Runs PHPCS after every file |
| `/wt-commit` | Stages changes, writes commit message, pushes to Bitbucket, creates PR |
| `/wt-fix-review` | Reads PR review comments, fixes clear ones automatically, asks about vague ones |

### Quality Gates

| Command | What It Does |
|---|---|
| `/wt-test` | Audits existing tests, generates missing PHPUnit tests, runs full suite |
| `/wt-security` | Security audit — sanitization, escaping, nonces, capabilities, SQL injection |
| `/wt-observability` | Checks logging coverage and error handling |
| `/wt-review` | Full code review — PHPCS, security, WC compatibility, performance |
| `/wt-qa` | 5-phase QA gate — PHPCS + PHPUnit + security + WC compat + performance. **All must pass before commit** |

### Support & Release

| Command | What It Does |
|---|---|
| `/wt-support` | Triage and resolve a support ticket (ISCS-{n}) |
| `/wt-release` | Version bump → changelog → build zip → tag |
| `/wt-qa-ticket` | Creates a QA handoff ticket in Jira and notifies the tester |

### Utilities

| Command | What It Does |
|---|---|
| `/wt-init-plugin` | Initialize a new plugin — creates `CLAUDE.md` and `ai-context/` files |
| `/wt-tickets` | Shows your Jira dashboard (IS + ISCS tickets assigned to you) |
| `/wt-add-jira-comment` | Post a comment on any Jira ticket |

---

## Agents Reference

Agents are specialized AI sub-processes launched automatically by the pipeline commands. You never call them directly.

| Agent | Model | Effort | What It Does |
|---|---|---|---|
| `task-assessor` | Haiku | low | Reads Jira ticket, scores complexity (0–6), returns pipeline recipe (Simple / Medium / Complex) |
| `prd-fetcher` | Haiku | low | Fetches PRD from Confluence and ticket details from Jira |
| `design-reader` | Haiku | low | Reads Figma design files — screens, components, field names, UI flows |
| `pr-manager` | Haiku | low | Creates and polls Bitbucket PRs, assigns reviewers, handles plan review flow |
| `code-explorer` | Haiku | medium | Scans codebase — class map, hook inventory, existing patterns to follow |
| `security-auditor` | Sonnet | medium | Audits code for security issues — injection, escaping, nonces, capabilities |
| `code-builder` | Sonnet | high | Implements feature tasks from plan.md. Runs PHPCS after every file. Max 5 iterations |
| `qa-runner` | Sonnet | high | Runs full QA pipeline — PHPCS + PHPUnit + WC compat + security + performance |
| `feature-planner` | **Opus** | high | Generates detailed implementation plan from PRD + codebase scan. Deep architectural thinking |

**Complexity → Agent selection:**

| Complexity | Score | Agents Used |
|---|---|---|
| Simple | 0–1 | prd-fetcher only, no plan PR |
| Medium | 2–3 | prd-fetcher + code-explorer, plan PR required |
| Complex | 4–6 | prd-fetcher + design-reader + code-explorer, full plan review |

---

## Skills Reference

Skills are domain knowledge libraries loaded into Claude's context on demand. They are invoked automatically by the pipeline commands.

| Skill | When Used | What It Provides |
|---|---|---|
| `wp-plugin-development` | wt-implement, wt-plan | Plugin architecture, hooks, security patterns, Settings API, release packaging |
| `wp-performance` | wt-review, wt-qa | Query optimization, caching, N+1 detection, asset loading |
| `wp-rest-api` | When plan has REST endpoints | REST controller patterns, auth, schema validation |
| `wp-block-development` | When plan has Gutenberg blocks | block.json, attributes, dynamic rendering, deprecations |
| `wpds` | When plan has admin UI | WordPress Design System components and tokens |
| `wp-interactivity-api` | When plan has JS interactions | data-wp-* directives, store/state/actions |
| `wp-wpcli-and-ops` | When plan has WP-CLI | WP-CLI commands, db operations, automation |
| `wp-performance` | Performance review phase | Profiling, query monitor, object caching |
| `wp-phpstan` | Static analysis | PHPStan config, baselines, WP typing |
| `wp-playground` | Local testing | Disposable WP instances, blueprints |
| `wordpress-router` | Session start | Classifies the repo type and routes to correct workflow |
| `wp-block-themes` | Block theme work | theme.json, templates, patterns, Site Editor |
| `wp-abilities-api` | Abilities API work | wp_register_ability, REST exposure |
| `wp-project-triage` | Repo inspection | Structured JSON report of repo state |
| `context-save-plan` | After plan approval | Saves plan to `.context/plans/` for session persistence |
| `context-load-plan` | Session start | Restores active plan from `.context/plans/` |
| `context-init` | Plugin init | Sets up `.context/` folder and git hooks |
| `context-find-plan` | Debugging | Traces a git commit hash back to its originating plan |

---

## Automation Hooks

Hooks run automatically — no manual trigger needed.

### SessionStart → `context-session-start.sh`
Fires at the start of every Claude Code session. Loads all `.context/*.md` files (architecture, coding standards, glossary, etc.) into Claude's context window automatically.

### PostToolUse (Edit/Write) → `auto-review.sh`
Fires after every PHP file is saved. Runs PHPCS on the saved file only. Auto-detects the standard:
- Plugin has `Woo:` in header → **WooCommerce** standard
- Otherwise → **WordPress** standard

Violations are shown inline so you fix them immediately, not at commit time.

### PreToolUse (Bash/git commit) → `pre-commit-review.sh`
Fires before every `git commit`. Runs PHPCS on **staged PHP files only**, filtered to **changed lines only**. Blocks the commit if new errors are found on changed lines. Auto-fixable issues are fixed by phpcbf automatically.

### Stop → `auto-test.sh`
Fires when Claude finishes a session. Runs PHPUnit and shows a pass/fail summary. Reminds you if tests are failing before you close the session.

---

## Branch Strategy

```
master  (never commit directly)
  └── release/2.3.8          ← cut from master for each release
        ├── feature/IS-123-channel-filter
        ├── feature/IS-456-new-feed-format
        └── fix/ISCS-789-price-bug
```

| Branch | Pattern | Created From |
|---|---|---|
| Release | `release/{version}` | master |
| Feature | `feature/IS-{n}-{description}` | release branch |
| Bug fix | `fix/ISCS-{n}-{description}` | release branch |

PRs always target the **release branch**, never master.

---

## Updating the Toolkit

When the toolkit is updated (new commands, agents, etc.), each developer re-runs the installer in their plugin:

```bash
cd /path/to/plugin
~/wt-plugin-development-claude-toolkit/install.sh
```

The installer overwrites agents, skills, scripts, and commands. Your `settings.json` (credentials) is never touched.

To update the toolkit itself (for toolkit maintainers):

```bash
cd ~/wt-plugin-development-claude-toolkit

# Make your changes to agents/, skills/, commands/, scripts/

git add -A
git commit -m "feat: describe what changed"
git push origin master
```

---

## Quick Reference Card

```
New feature?          /wt-feature → /wt-plan → /wt-design-review → /wt-implement
Or just:              /wt-build IS-{n}

Bug fix?              /wt-support ISCS-{n}

Before committing:    /wt-qa  (all phases must pass)

Committing:           /wt-commit

After PR approved:    /wt-qa-ticket

Release?              /wt-release

Check your tickets:   /wt-tickets
```

---

## Troubleshooting

**MCP not connecting (Jira/Confluence/Bitbucket not working)**
- Check `uvx` is installed: `uvx --version`
- Verify credentials in `.claude/settings.json`
- Restart Claude Code

**PHPCS not running after file save**
- Check hook paths in `settings.json` match your plugin's absolute path
- Verify `vendor/bin/phpcs` exists: `ls vendor/bin/phpcs`
- Run `composer install` if vendor is missing

**Agents not found**
- Re-run `~/wt-plugin-development-claude-toolkit/install.sh`
- Verify `.claude/agents/` exists in your plugin folder

**Plan not loading between sessions**
- Run `/context-load-plan` at the start of your session
- Check `.context/plans/.current` exists

**Pre-commit hook blocking commit**
- Fix PHPCS errors shown in the output
- Run `vendor/bin/phpcbf --standard=WordPress path/to/file.php` to auto-fix
