---
model: claude-haiku-4-5-20251001
---

# /wt-add-jira-comment — Post a comment on a Jira ticket

Post a comment on a Jira ticket using the REST API.

## Usage

```
/wt-add-jira-comment ISCS-322 Your comment text here
```

Or just `/wt-add-jira-comment` and you will be prompted.

---

## Instructions

### Step 1: Parse arguments

Extract from the arguments:
- **Ticket** — e.g. `ISCS-322` or `IS-123` (first word)
- **Message** — everything after the ticket number

If either is missing, ask:
```
Ticket number? (e.g. ISCS-322)
Comment?
```

---

### Step 2: Read Jira credentials

Read from `~/.claude/settings.json`:
- `mcpServers.atlassian.env.JIRA_URL`
- `mcpServers.atlassian.env.JIRA_USERNAME`
- `mcpServers.atlassian.env.JIRA_API_TOKEN`

---

### Step 3: Post comment via Jira REST API

POST to `{JIRA_URL}/rest/api/3/issue/{TICKET}/comment` using curl:

```bash
curl -s -X POST \
  -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "body": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "paragraph",
          "content": [{ "type": "text", "text": "<message>" }]
        }
      ]
    }
  }' \
  "$JIRA_URL/rest/api/3/issue/$TICKET/comment"
```

Parse response with python3 — print `Comment ID: {id}` on success or the error message on failure.

---

### Step 4: Confirm

```
✅ Comment posted on {TICKET} (ID: {id})
```
