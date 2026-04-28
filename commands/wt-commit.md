---
model: claude-haiku-4-5-20251001
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

# /wt-commit — Review, approve, and commit to Bitbucket

You are acting as a senior developer preparing a production-quality git commit.
**Never commit without explicit user approval. Never skip any step.**

---

### Step 1: Verify branch and load repo map

```bash
git branch --show-current
```

- If on `main` or `master` or `release/*` → **STOP**:
  ```
  ⚠️  You are on {branch}. Do not commit directly to master or release branches.
  Expected: feature/IS-{ticket}-{description} or fix/ISCS-{ticket}-{description}
  Please switch to the correct branch first, then run /wt-commit again.
  ```
- If on correct feature/fix branch → continue

**Determine the PR destination (release branch):**

Read the target release version from the feature folder:
```bash
TICKET=$(git branch --show-current | grep -oE '[A-Z]+-[0-9]+')
cat Tasks/feature/${TICKET}-*/.release-version 2>/dev/null || cat Tasks/feature/${TICKET}*/.release-version 2>/dev/null
```

- If `.release-version` file found → destination branch = `release/{version}`
- If not found → ask the user:
  ```
  Which release branch should this PR target? (e.g. 1.2.5)
  ```
  Then use `release/{version}` as destination.

> ⚠️ PR destination is always a `release/x.x.x` branch — never `master`.

**Load the repo map (multi-plugin support):**
```bash
cat Tasks/feature/${TICKET}-*/.repo-list.json 2>/dev/null
```

- If the file exists and has addon entries → this commit will create PRs in **multiple repos**. Keep the repo map in memory.
- If absent or empty addons → single-repo commit; proceed as normal.

**For multi-plugin tickets, Steps 2–9 run once for each repo in the repo map (primary first, then each addon in order).** The branch name is identical across all repos. The commit message is identical. The PR destination (`release/{version}`) is identical.

---

### Step 2: Show what will be committed

For each repo in scope, launch a sub-agent (general-purpose, haiku) to run:
```bash
cd {repo_path} && git status && git diff --staged && git diff
```

Display results grouped by repo slug. If nothing is staged in a repo, show its `git status` and ask which files to stage (or whether to skip that repo).

**Wait for the user to confirm they have reviewed all diffs before continuing.**

---

### Step 3: Pre-commit PHPCS gate

```bash
bash ~/.claude/scripts/pre-commit-review.sh
```

- If it **fails** → show errors, fix them (`phpcbf` for auto-fixable), re-stage, re-run
- Do **not** proceed until exit code is 0

---

### Step 4: Rovo code review

Use Atlassian MCP to trigger a Rovo code review on the staged changes.

- If Rovo finds issues → show them to the user, fix, re-stage, return to Step 3
- If Rovo passes → continue

---

### Step 5: Build commit message

Read current branch name to extract Jira ticket:
- `feature/IS-123-tiktok-shop-feed` → ticket is `IS-123`
- `fix/ISCS-456-price-bug` → ticket is `ISCS-456`

Use Atlassian MCP to fetch the Jira ticket title for context.

Ask the user (single message):
```
1. Commit type: feat | fix | refactor | test | docs | chore | style | perf
2. Short summary (imperative mood, max 60 chars)
   e.g. "add TikTok Shop feed format"
3. Any extra context for the body? (optional — press Enter to skip)
```

Build the commit message:
```
IS-123: feat: add TikTok Shop feed format

- Introduced WTPF_TikTok_Feed class with required column mapping
- Registers TikTok Shop as selectable format in feed settings
- Handles variable products with one CSV row per variation

Jira: IS-123
Reviewed-by: Claude (PHPCS ✅ Rovo ✅)
```

**Rules:**
- Subject: `TICKET: type: summary` — max 72 chars, imperative mood, no period
- Body: explains *why*, not *what* — wrapped at 72 chars
- One logical change per commit

| Type | When to use |
|------|-------------|
| `feat` | New feature or WooCommerce hook |
| `fix` | Bug fix |
| `refactor` | Code restructure, no behavior change |
| `test` | Add/update unit tests |
| `docs` | Comments, README, inline docs |
| `chore` | composer.json, config, build scripts |
| `style` | PHPCS fixes only |
| `perf` | Performance improvement |

---

### Step 6: Show message and ask for approval

```
Ready to commit with this message? (yes / edit / cancel)
```

- **yes** → proceed
- **edit** → user revises, show again
- **cancel** → abort, leave staged

---

### Step 7: Commit

Ensure `node_modules` and `vendor` are in `.gitignore` before committing:

```bash
grep -qxF 'node_modules' .gitignore 2>/dev/null || echo 'node_modules' >> .gitignore
grep -qxF 'vendor' .gitignore 2>/dev/null || echo 'vendor' >> .gitignore
git add .gitignore
```

```bash
git commit -m "$(cat <<'EOF'
IS-123: feat: add TikTok Shop feed format

- Introduced WTPF_TikTok_Feed class with required column mapping
- Registers TikTok Shop as selectable format in feed settings
- Handles variable products with one CSV row per variation

Jira: IS-123
Reviewed-by: Claude (PHPCS ✅ Rovo ✅)
EOF
)"
```

Show `git log --oneline -3` to confirm.

---

### Step 8: Push to Bitbucket

```
Push to Bitbucket?
  Branch: [current branch]
  Remote: origin → [remote URL]
(yes / no)
```

If yes: `git push origin [branch]`

---

### Step 9: Auto-create Bitbucket Pull Request

Read credentials from `.claude/settings.json → mcpServers.atlassian.env`:
- `BITBUCKET_URL`, `BITBUCKET_USERNAME`, `BITBUCKET_API_TOKEN`, `BITBUCKET_WORKSPACE`

**Authentication:** Basic auth — `username:token` (Repository Access Token, NOT Atlassian API token).

**Read PR reviewer from `CLAUDE.md`:**
```bash
grep "PR Reviewers:" CLAUDE.md | sed 's/.*PR Reviewers: //'
```

Show the reviewer to the user and ask:
```
PR Reviewer: {email from CLAUDE.md}
Use this reviewer? (yes / change)
```
- **yes** → use the email from CLAUDE.md
- **change** → ask: `Enter reviewer email:` and use that instead

**Look up reviewer's Bitbucket account UUID:**
```bash
curl -s -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  "https://api.bitbucket.org/2.0/workspaces/$WORKSPACE/members" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
email = '{REVIEWER_EMAIL}'
for m in data.get('values', []):
    u = m.get('user', {})
    if u.get('account_id') or email.lower() in str(u).lower():
        print(u.get('uuid', ''))
        break
"
```

If UUID is found, include reviewer in PR payload. If not found, create PR without reviewer and warn the user.

```bash
BITBUCKET_USER="<BITBUCKET_USERNAME from settings.json>"
BITBUCKET_TOKEN="<BITBUCKET_API_TOKEN from settings.json>"
WORKSPACE="<BITBUCKET_WORKSPACE>"
REPO="<Repo from CLAUDE.md>"

curl -s -X POST \
  -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "IS-123: feat: add TikTok Shop feed format",
    "description": "## Summary\n- ...\n\n## Jira\nIS-123: https://mozilor.atlassian.net/browse/IS-123\n\n## Test Plan\n- [ ] Feature works as per PRD\n- [ ] No regressions on existing functionality\n- [ ] Tested in Local Sites\n- [ ] Unit tests passing\n\n🤖 Reviewed by Claude (PHPCS ✅ Rovo ✅)",
    "source": { "branch": { "name": "feature/IS-123-..." } },
    "destination": { "branch": { "name": "release/{version}" } },
    "reviewers": [{ "uuid": "{REVIEWER_UUID}" }],
    "close_source_branch": false
  }' \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests"
```

Extract PR URL from response: `d['links']['html']['href']`

- **If token is rejected** → inform user to generate a Repository Access Token at:
  Bitbucket → Repository Settings → Access tokens (Read + Write on Repositories & Pull requests)
  Then update `BITBUCKET_API_TOKEN` in `.claude/settings.json`

- Post a comment on the Jira ticket with the PR and commit link using Atlassian MCP.
  Use Jira wiki markup anchor tags so URLs are hidden behind labels:
  ```
  PR created and ready for review:
  [View Pull Request|{PR URL}]
  [View Commit|https://bitbucket.org/{workspace}/{repo}/commits/{commit_hash}]
  Branch: {source branch} → {destination branch}
  ```

- Transition Jira ticket → **Code Review** (transition id: `31`) after PR is created

**Save code PR state for background monitoring.**

For single-repo tickets, write `Tasks/feature/{ticket}-*/.code-pr-state.json`:
```json
{
  "pr_id": 456,
  "pr_url": "https://bitbucket.org/{workspace}/{repo}/pull-requests/456",
  "ticket": "IS-123",
  "feature_name": "tiktok-shop-feed",
  "release_version": "1.2.5"
}
```

For multi-repo tickets, write `Tasks/feature/{ticket}-*/.code-pr-state.json` with all PRs:
```json
{
  "ticket": "IS-123",
  "feature_name": "tiktok-shop-feed",
  "release_version": "1.2.5",
  "prs": [
    {
      "repo_slug": "product-feed-xyz",
      "pr_id": 456,
      "pr_url": "https://bitbucket.org/webtoffee/product-feed-xyz/pull-requests/456"
    },
    {
      "repo_slug": "wt-addon-subscriptions",
      "pr_id": 78,
      "pr_url": "https://bitbucket.org/webtoffee/wt-addon-subscriptions/pull-requests/78"
    }
  ]
}
```

**Post a single Jira comment listing all PRs** (using Atlassian MCP):
```
PRs created and ready for review:

[Core PR — product-feed-xyz|{pr_url_1}]
[Addon PR — wt-addon-subscriptions|{pr_url_2}]   ← omit if single-repo

Branch: feature/IS-123-... → release/1.2.5
```

**Set up background approval polling (CronCreate, every 5 min):**
```
Check code PR approval for {ticket}:
Invoke pr-manager agent with mode=poll-code-pr-merge, pr_state_file=Tasks/feature/{ticket}-*/.code-pr-state.json
  - Poll ALL pr_ids in the prs array
  - ALL PRs must be approved before merge proceeds (multi-repo: all or nothing)
  - If all PRs approved → merge each in order (primary first), then invoke /wt-qa-ticket → cancel cron
  - If any PR DECLINED → notify user, cancel cron
  - If any PR still OPEN → continue polling
```

Show the PR URLs to the user, then:

```
✅ Committed:  IS-123: feat: add TikTok Shop feed format

PRs created:
  [product-feed-xyz]        https://bitbucket.org/webtoffee/product-feed-xyz/pull-requests/456
  [wt-addon-subscriptions]  https://bitbucket.org/webtoffee/wt-addon-subscriptions/pull-requests/78

✅ IS-123 →    Jira comment posted with all PR links
✅ IS-123 →    Code Review

⏳ Monitoring all PRs for reviewer approval in the background.
   All PRs must be approved before any is merged.
   You can close Claude — the PRs will be merged automatically once all are approved,
   then QA handoff fires immediately.
```

---

### Final summary

```
✅ Committed:  IS-123: feat: add TikTok Shop feed format
✅ Pushed:     origin/feature/IS-123-... (all repos)
✅ PRs created:
     product-feed-xyz        → pull-requests/456
     wt-addon-subscriptions  → pull-requests/78   ← omitted if single-repo
✅ IS-123 →    Jira comment posted with all PR links
✅ IS-123 →    Code Review
⏳ Watching all PRs for reviewer approval → auto-merge → QA handoff
```

---

### Notes
- Never use `git commit --no-verify`
- Never force push unless user explicitly confirms
- Always on correct feature/fix branch before committing
