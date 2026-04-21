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

### Step 1: Verify branch

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

---

### Step 2: Show what will be committed

Launch a sub-agent (general-purpose, model: claude-haiku-4-5-20251001) to run the following in parallel and return results:
```bash
git status
git diff --staged
git diff
```

Display all results to the user.
If nothing is staged, show `git status` and ask which files to stage.
**Wait for the user to confirm they have reviewed the diff before continuing.**

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

- Post a comment on the Jira ticket with the PR link using Atlassian MCP:
  ```
  PR created and ready for review:
  🔗 {PR URL}
  Branch: {source branch} → {destination branch}
  ```

- Transition Jira ticket → **Code Review** (transition id: `31`) after PR is created

Show the PR URL to the user.

> **QA ticket is NOT created here.** It is created separately after the PR is reviewed and merged.
> Run `/wt-qa-ticket` once the PR review is complete.

---

### Final summary

```
✅ Committed:  IS-123: feat: add TikTok Shop feed format
✅ Pushed:     origin/feature/IS-123-...
✅ PR created: https://bitbucket.org/webtoffee/[repo]/pull-requests/[id]
✅ IS-123 →    Jira comment posted with PR link
✅ IS-123 →    Code Review
```

---

### Notes
- Never use `git commit --no-verify`
- Never force push unless user explicitly confirms
- Always on correct feature/fix branch before committing
