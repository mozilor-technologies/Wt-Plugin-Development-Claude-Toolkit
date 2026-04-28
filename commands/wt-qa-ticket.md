---
model: claude-haiku-4-5-20251001
---

# /wt-qa-ticket — Create QA handoff ticket and notify tester

You are acting as a release coordinator handing off a feature to the QA team.

Run this **after** a PR has been reviewed and is ready for QA testing.
Do NOT run this before the PR is merged or approved.

---

## Instructions

---

### Step 1: Get context

Read the current branch to extract the ticket:
```bash
git branch --show-current
```

Read credentials from `.claude/settings.json → mcpServers.atlassian.env`:
- `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`
- `BITBUCKET_WORKSPACE`, `BITBUCKET_API_TOKEN`, `BITBUCKET_USERNAME`

Read `CLAUDE.md` for:
- `QA Tester` email
- Plugin slug and repo name

Read the approved plan from `.context/plans/` (via **context-load-plan**) or fall back to `Tasks/feature/{ticket}-{name}/plan.md` for the feature description and task list.

---

### Step 2: Collect all PR details

**Load PR state from `.code-pr-state.json`:**
```bash
TICKET=$(git branch --show-current | grep -oE '[A-Z]+-[0-9]+')
cat Tasks/feature/${TICKET}-*/.code-pr-state.json 2>/dev/null
```

- If the file has a top-level `prs` array → this is a **multi-repo ticket**. Collect all PR entries.
- If the file has a single top-level `pr_id` (legacy single-repo format) → treat as one PR.
- If the file is missing → ask the user:
  ```
  Which PR(s) are ready for QA?
  Paste Bitbucket PR URL(s), one per line. Press Enter twice when done.
  ```

Fetch each PR's title and branch using Bitbucket API:
```bash
curl -s \
  -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/{repo_slug}/pullrequests/{pr_id}" \
  | python3 -c "
import sys, json
pr = json.load(sys.stdin)
print('TITLE:', pr['title'])
print('BRANCH:', pr['source']['branch']['name'])
"
```

Build a **PR summary list** used in the QA ticket body:
```
- [Core PR — product-feed-xyz|{pr_url}]
- [Addon PR — wt-addon-subscriptions|{pr_url}]   ← omit if single-repo
```

---

### Step 3: Create QA Jira ticket

Create a sub-task (or linked task) on the parent Jira ticket for QA testing.

The description body must include **all PRs** from the PR summary list built in Step 2, so the QA tester sees the complete change surface across core and addon repos.

```bash
curl -s -X POST \
  -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": { "key": "{JIRA_PROJECT}" },
      "summary": "QA: {feature name} — test on staging",
      "description": {
        "type": "doc",
        "version": 1,
        "content": [
          {
            "type": "heading", "attrs": { "level": 3 },
            "content": [{ "type": "text", "text": "Pull Requests" }]
          },
          {
            "type": "bulletList",
            "content": [
              {
                "type": "listItem",
                "content": [{ "type": "paragraph", "content": [
                  { "type": "text", "text": "Core PR (product-feed-xyz): " },
                  { "type": "text", "text": "{pr_url_core}", "marks": [{ "type": "link", "attrs": { "href": "{pr_url_core}" } }] }
                ]}]
              }
              /* repeat one listItem per addon PR if multi-repo */
            ]
          },
          {
            "type": "paragraph",
            "content": [{ "type": "text", "text": "Feature: {ticket} — {feature name}" }]
          },
          {
            "type": "heading", "attrs": { "level": 3 },
            "content": [{ "type": "text", "text": "Test Checklist" }]
          },
          {
            "type": "bulletList",
            "content": [
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Feature works as per PRD" }] }] },
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "No regressions on existing feed types" }] }] },
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Tested on clean WooCommerce store (simple + variable products)" }] }] },
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Tested with WooCommerce HPOS enabled" }] }] },
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "Core plugin and addon plugin active simultaneously — no conflicts" }] }] },
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "No JS console errors" }] }] },
              { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "No PHP errors in debug log" }] }] }
            ]
          }
        ]
      },
      "issuetype": { "name": "Task" },
      "assignee": { "emailAddress": "{QA_TESTER_EMAIL}" },
      "labels": ["qa-testing"],
      "priority": { "name": "Medium" }
    }
  }' \
  "$JIRA_URL/rest/api/3/issue"
```

Extract the new QA ticket key from the response (e.g. `IS-534`).

Link the QA ticket to the feature ticket:
```bash
curl -s -X POST \
  -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": { "name": "relates to" },
    "inwardIssue": { "key": "{FEATURE_TICKET}" },
    "outwardIssue": { "key": "{QA_TICKET}" }
  }' \
  "$JIRA_URL/rest/api/3/issueLink"
```

---

### Step 4: Transition feature ticket to QA Testing

```bash
curl -s -X POST \
  -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"transition": {"id": "41"}}' \
  "$JIRA_URL/rest/api/3/issue/{FEATURE_TICKET}/transitions"
```

> Transition ID 41 = "QA Testing". If this fails, ask the user for the correct transition ID for their board.

---

### Step 5: Post comment on feature ticket

Use `/wt-add-jira-comment` to post:
```
QA handoff complete.

QA ticket created: {QA_TICKET} — assigned to {QA_TESTER_EMAIL}

PRs under test:
  Core:  {pr_url_core}
  Addon: {pr_url_addon}   ← omit if single-repo

Please test on staging with both plugins active before merging to master.
```

---

### Step 6: Confirm

```
✅ QA ticket created:  {QA_TICKET} — {QA ticket summary}
✅ Assigned to:        {QA_TESTER_EMAIL}
✅ Linked to:          {FEATURE_TICKET}
✅ {FEATURE_TICKET} →  QA Testing

PRs included in QA ticket:
  product-feed-xyz        → {pr_url_core}
  wt-addon-subscriptions  → {pr_url_addon}   ← omitted if single-repo

The QA tester has been notified.
When QA passes → merge all PRs and run /wt-release.
```
