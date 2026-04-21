---
model: claude-opus-4-6
---

# /wt-design-review — Push plan for architecture review before implementation

You are acting as a Senior WordPress/WooCommerce engineering lead managing a plan review gate.

**Implementation is blocked until this PR is approved.**

## Branch Strategy

```
master
  └── feature/IS-123-name       ← feature branch (implementation happens here)
        └── plan/IS-123-name    ← plan-only branch (PR source)
```

- PR is always: `plan/{ticket}-{name}` → `feature/{ticket}-{name}`
- Only `plan.md` and `PRD.md` are on the plan branch — no code
- On approval → merge plan branch into feature branch → delete plan branch
- Implementation then proceeds on the feature branch as normal

---

## Instructions

---

### Step 0: Score complexity — Simple or Full review?

Before anything else, read `plan.md` and score the change complexity.

**Score 1 point for each that applies:**
- More than 1 file changed
- New DB table or schema change
- New hooks or filters introduced
- New admin page or menu item
- JavaScript changes required
- External API integration

**Routing:**
- **Score 0–1 → Simple** → inline approval only, skip Bitbucket PR entirely
- **Score 2+ → Full review** → proceed with plan branch + Bitbucket PR (Steps 1–10)

**Simple route (score 0–1):**

Show:
```
📊 Complexity: Simple (score: {N}/6)
   This is a low-complexity change — no Bitbucket plan PR needed.

Plan summary:
{2-3 line summary of what will be changed}

Approve plan to proceed? (yes / no)
```

- **yes** →
  1. Write `Tasks/feature/{ticket}-{name}/.plan-approved`:
     ```
     approved_by: {user — inline approval}
     approved_at: {today's date}
     route: inline (simple change — no PR required)
     ```
  2. Transition Jira to In Progress (fetch valid transition IDs first — do not hardcode)
  3. Show: `✅ Plan approved (inline). Implementation is unblocked.`
  4. **STOP** — do not proceed to Steps 1–10.

- **no** → stop, do not proceed.

---

### Step 1: Locate the plan

Read the current branch name:
```bash
git branch --show-current
```

You must be on the **feature branch** (`feature/IS-*` or `fix/ISCS-*`) when running this command.

Extract the ticket number and name:
- `feature/IS-123-tiktok-shop-feed` → ticket = `IS-123`, name = `tiktok-shop-feed`
- `fix/ISCS-456-price-bug`          → ticket = `ISCS-456`, name = `price-bug`

Derive the plan branch name:
- `plan/IS-123-tiktok-shop-feed`
- `plan/ISCS-456-price-bug`

Find `plan.md` at:
```
Tasks/feature/{ticket}-{name}/plan.md
```

If no plan.md exists → STOP:
```
⚠️  No plan.md found for this ticket.
Run /wt-plan first to generate the implementation plan.
```

Check if `.plan-approved` already exists:
```
Tasks/feature/{ticket}-{name}/.plan-approved
```

If it exists → show:
```
✅ Plan already approved. You can run /wt-implement.
```
And stop.

---

### Step 2: Ensure the feature branch is pushed

```bash
git push -u origin feature/{ticket}-{name} 2>&1
```

---

### Step 3: Create and switch to the plan branch

Check if the plan branch already exists locally or remotely:
```bash
git branch --list "plan/{ticket}-{name}"
git ls-remote --heads origin "plan/{ticket}-{name}"
```

If it does NOT exist → create it from the feature branch:
```bash
git checkout -b plan/{ticket}-{name}
```

If it already exists locally → switch to it:
```bash
git checkout plan/{ticket}-{name}
```

If it exists only on remote → check it out:
```bash
git checkout -b plan/{ticket}-{name} origin/plan/{ticket}-{name}
```

---

### Step 4: Commit plan files to the plan branch

Stage only the plan and PRD files:
```bash
git add Tasks/feature/{ticket}-{name}/plan.md
git add Tasks/feature/{ticket}-{name}/PRD.md 2>/dev/null || true
git status
```

If files are already committed and unmodified → skip commit.

If there are changes:
```bash
git commit -m "{ticket}: docs: add implementation plan for review"
```

Push the plan branch:
```bash
git push -u origin plan/{ticket}-{name}
```

Switch back to the feature branch:
```bash
git checkout feature/{ticket}-{name}
```

---

### Step 5: Check for existing plan review PR

Read credentials from `.claude/settings.json → mcpServers.atlassian.env`:
- `BITBUCKET_USERNAME`, `BITBUCKET_API_TOKEN`, `BITBUCKET_WORKSPACE`
- Repo name from `CLAUDE.md`

Check if a plan review PR already exists for this plan branch:
```bash
curl -s \
  -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests?q=source.branch.name=\"plan/{ticket}-{name}\"&state=OPEN" \
  | python3 -c "
import sys, json
prs = json.load(sys.stdin).get('values', [])
print(prs[0]['id'] if prs else 'none')
"
```

If a plan review PR already exists → skip Step 6, go to Step 7 with that PR ID.

---

### Step 6: Create the plan review PR

Source branch: `plan/{ticket}-{name}`
Destination branch: `feature/{ticket}-{name}`

Read plan.md content (first 3000 chars) for the PR description.

```bash
curl -s -X POST \
  -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "PLAN REVIEW: {ticket}: {feature name}",
    "description": "## Plan Review Request\n\nThis PR contains the implementation plan for **{ticket}**.\nReview and approve before implementation begins.\n\n---\n\n{plan.md content truncated to 3000 chars}\n\n---\n\n⚠️ **Implementation on `feature/{ticket}-{name}` is blocked until this plan is approved.**\n\n**Branch flow:**\n`plan/{ticket}-{name}` → `feature/{ticket}-{name}`\n\nOn approval: merge this PR → then run `/wt-implement` on the feature branch.",
    "source": { "branch": { "name": "plan/{ticket}-{name}" } },
    "destination": { "branch": { "name": "feature/{ticket}-{name}" } },
    "close_source_branch": true
  }' \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests"
```

Extract and save the PR ID and URL from the response.

---

### Step 7: Assign reviewer

**Read PR reviewer from `CLAUDE.md`:**
```bash
grep "PR Reviewers:" CLAUDE.md | sed 's/.*PR Reviewers: //'
```

Show the reviewer to the user and ask:
```
Plan Reviewer: {email from CLAUDE.md}
Use this reviewer? (yes / change)
```
- **yes** → use the email from CLAUDE.md
- **change** → ask: `Enter reviewer email:` and use that instead

**Look up reviewer's Bitbucket account UUID:**

First check memory file `~/.claude/projects/.../memory/reference_bitbucket_uuids.md` for a cached UUID matching the reviewer's name or email. Use it directly — **do not call the members API if the UUID is already cached**.

If not found in memory → fall back to API:
```bash
curl -s -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  "https://api.bitbucket.org/2.0/workspaces/$WORKSPACE/members" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
email = '{REVIEWER_EMAIL}'
for m in data.get('values', []):
    u = m.get('user', {})
    if email.lower() in str(u).lower():
        print(u.get('uuid', ''))
        print(u.get('display_name', ''))
        break
"
```
Then save the found UUID to the memory file for future use.

If UUID found → add reviewer to PR. If not found → ask the user:
```
⚠️  Could not find Bitbucket UUID for "{reviewer_email}".
Enter the reviewer's Bitbucket email or UUID (or type "skip" to create PR without reviewer):
```
- If user provides a new email → re-run the UUID lookup with that email. Repeat until found or "skip".
- If user provides a UUID directly → use it immediately.
- If "skip" → create PR without reviewer and warn: `⚠️ PR created without reviewer — please assign manually on Bitbucket.`

Add the reviewer to the PR:
```bash
curl -s -X PUT \
  -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "PLAN REVIEW: {ticket}: {feature name}",
    "reviewers": [{"uuid": "{REVIEWER_UUID}"}]
  }' \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/{pr_id}"
```

Show confirmation:
```
✅ Plan review PR created:  {PR URL}
✅ Source → Destination:    plan/{ticket}-{name} → feature/{ticket}-{name}
✅ Reviewer assigned:       {display_name}

Waiting for plan approval before implementation can begin.
The reviewer will add comments or approve on Bitbucket.

When you are ready to check review status → run /wt-design-review again.
```

---

### Step 8: Check review status (on re-run)

When `/wt-design-review` is run again and a plan review PR already exists:

**Check PR approval status:**
```bash
curl -s \
  -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/{pr_id}" \
  | python3 -c "
import sys, json
pr = json.load(sys.stdin)
participants = pr.get('participants', [])
approved = [p['user']['display_name'] for p in participants if p.get('approved')]
state = pr.get('state')
print('STATE:', state)
print('APPROVED_BY:', approved)
"
```

**Check for open comments:**
```bash
curl -s \
  -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/{pr_id}/comments" \
  | python3 -c "
import sys, json
comments = json.load(sys.stdin).get('values', [])
open_comments = [c for c in comments if not c.get('deleted') and c.get('content', {}).get('raw')]
for c in open_comments:
    print(f\"  [{c['id']}] {c['author']['display_name']}: {c['content']['raw'][:200]}\")
print(f'OPEN_COMMENTS: {len(open_comments)}')
"
```

---

### Step 9: Handle comments

If there are open comments, show them all:
```
📝 Open review comments on your plan:

[Comment 1 — reviewer name]
  "comment text"

[Comment 2 — reviewer name]
  "comment text"

Please update plan.md to address these comments.
Tell me what changes to make, or edit plan.md manually.
```

After plan.md is updated, switch to the plan branch, commit, and push:
```bash
git checkout plan/{ticket}-{name}
git add Tasks/feature/{ticket}-{name}/plan.md
git commit -m "{ticket}: docs: update plan based on review feedback"
git push origin plan/{ticket}-{name}
git checkout feature/{ticket}-{name}
```

Then sync the updated plan to `.context/plans/` so future sessions use the revised version:
Invoke the **context-save-plan** skill to overwrite the saved plan with the updated `plan.md`.

Show:
```
✅ Updated plan pushed to plan/{ticket}-{name}.
✅ .context/plans/ updated with revised plan.
The reviewer will be notified of the new commits.
Run /wt-design-review again to check for further comments or approval.
```

---

### Step 10: Handle approval

If the PR has at least one approval:

**0. Validate the approver is the designated plan reviewer:**

Read `Plan Reviewer` from `CLAUDE.md`. Compare against the list of approvers from the PR participants.

- If the designated plan reviewer is in the approved list → proceed normally.
- If the approval came from someone **other than** the designated reviewer:
  ```
  ⚠️  Plan approved by {approver_name} — but the designated plan reviewer is {plan_reviewer_email}.

  The plan was intended to be reviewed by {plan_reviewer_email}.
  Approvals from undesignated reviewers may indicate the plan was not properly reviewed.

  Do you want to proceed anyway? (yes / no)
  ```
  - **yes** → proceed with merge, note the actual approver in `.plan-approved`
  - **no** → stop, leave PR open, show:
    ```
    Waiting for approval from {plan_reviewer_email}.
    Run /wt-design-review again once they have reviewed.
    ```

**1. Merge the plan branch into the feature branch via Bitbucket API:**
```bash
curl -s -X POST \
  -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "{ticket}: docs: merge approved plan into feature branch",
    "close_source_branch": true
  }' \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/{pr_id}/merge"
```

**2. Pull the merge locally:**
```bash
git checkout feature/{ticket}-{name}
git pull origin feature/{ticket}-{name}
```

**3. Save the approval status:**

Write `Tasks/feature/{ticket}-{name}/.plan-approved`:
```
approved_by: {reviewer display_name}
approved_at: {ISO timestamp}
pr_url: {PR URL}
pr_id: {PR ID}
plan_branch: plan/{ticket}-{name}
feature_branch: feature/{ticket}-{name}
```

**4. Show:**
```
✅ Plan approved by {reviewer name}
✅ plan/{ticket}-{name} merged into feature/{ticket}-{name}
✅ .plan-approved saved

You are now on: feature/{ticket}-{name}
Implementation is unblocked.

Run /wt-implement to start building.
```

**5. Transition Jira ticket to In Progress (transition id: 21):**
```bash
curl -s -X POST \
  -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"transition": {"id": "21"}}' \
  "$JIRA_URL/rest/api/3/issue/{ticket}/transitions"
```

---

### Notes
- Always run this command while on the feature branch — it creates/manages the plan branch itself
- The plan branch (`plan/*`) contains only `plan.md` and `PRD.md` — never code
- `close_source_branch: true` auto-deletes the plan branch after merge
- If the plan branch was deleted remotely but `.plan-approved` doesn't exist yet → re-create the plan branch and re-raise the PR
- PR title must start with "PLAN REVIEW:" so other skills can identify it
- `/wt-implement` checks for `.plan-approved` — do not create this file manually
