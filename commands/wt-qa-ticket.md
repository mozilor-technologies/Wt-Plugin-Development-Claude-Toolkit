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

Read credentials from `~/.claude/settings.json → mcpServers.atlassian.env`:
- `JIRA_URL`, `JIRA_USERNAME`, `JIRA_API_TOKEN`
- `BITBUCKET_WORKSPACE`, `BITBUCKET_API_TOKEN`, `BITBUCKET_USERNAME`

Read `CLAUDE.md` for:
- `QA Tester` email
- Plugin slug and repo name

Read the approved plan from `.context/plans/` (via **context-load-plan**) or fall back to `Tasks/feature/{ticket}-{name}/plan.md` for the feature description and task list.

---

### Step 2: Ask for the PR details

If not already known, ask:
```
Which PR is ready for QA?
Paste the Bitbucket PR URL or PR number:
```

Fetch the PR title and description using Bitbucket API:
```bash
curl -s \
  -u "$BITBUCKET_USER:$BITBUCKET_TOKEN" \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pullrequests/{pr_id}" \
  | python3 -c "
import sys, json
pr = json.load(sys.stdin)
print('TITLE:', pr['title'])
print('BRANCH:', pr['source']['branch']['name'])
"
```

---

### Step 3: Create QA Jira ticket

Create a sub-task (or linked task) on the parent Jira ticket for QA testing:

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
            "type": "paragraph",
            "content": [{ "type": "text", "text": "PR: {PR URL}" }]
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
PR: {PR URL}

Please test on staging before this is merged to master.
```

---

### Step 6: Confirm

```
✅ QA ticket created:  {QA_TICKET} — {QA ticket summary}
✅ Assigned to:        {QA_TESTER_EMAIL}
✅ Linked to:          {FEATURE_TICKET}
✅ {FEATURE_TICKET} →  QA Testing

The QA tester has been notified.
When QA passes → merge the PR and run /wt-release.
```
