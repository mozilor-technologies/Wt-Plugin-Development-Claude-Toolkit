---
model: claude-haiku-4-5-20251001
---

# /wt-tickets — My Jira ticket dashboard (IS + ISCS)

Show tickets assigned to me across IS (features) and ISCS (support), grouped by project and status.

**Usage:**
- `/wt-tickets` — show only To Do + In Progress (default)
- `/wt-tickets in review` — show only In Review / Code Review tickets
- `/wt-tickets uat` — show only UAT tickets
- `/wt-tickets all` — show all statuses

---

## Instructions

### Step 1: Read Jira credentials

Read from `~/.claude/settings.json`:
- `mcpServers.atlassian.env.JIRA_URL`
- `mcpServers.atlassian.env.JIRA_USERNAME`
- `mcpServers.atlassian.env.JIRA_API_TOKEN`

---

### Step 1b: Determine filter from argument

Check the argument passed to the command (if any):

- No argument → filter = `["To Do", "In Progress", "Selected for Development"]`
- `in review` → filter = `["Code Review", "In Review"]`
- `uat` → filter = `["UAT"]`
- `backlog` → filter = `["Backlog"]`
- `all` → filter = all statuses (no status filter)

---

### Step 2: Fetch tickets for both projects in parallel

Use the `/rest/api/3/search/jql` API (not `/rest/api/3/search` — that API has been removed).
Use the account ID `601a3e94c8c36c0069b16f54` for the assignee filter (not `currentUser()` — it doesn't resolve reliably via API token).

Run two curl calls simultaneously (one per project):

**IS project:**
```bash
curl -s -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/search/jql?jql=project%3D%22IS%22%20AND%20assignee%3D601a3e94c8c36c0069b16f54%20AND%20status%20not%20in%20(Done%2C%22Plugin%20is%20live%2C%20marked%20as%20done%22%2C%22Ready%20to%20release%22)%20ORDER%20BY%20status%20ASC%2C%20priority%20DESC&fields=summary,status,priority&maxResults=50"
```

**ISCS project:**
```bash
curl -s -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/search/jql?jql=project%3DISCS%20AND%20assignee%3D601a3e94c8c36c0069b16f54%20AND%20status%20not%20in%20(Done%2C%22Ready%20For%20Testing%22)%20ORDER%20BY%20status%20ASC%2C%20priority%20DESC&fields=summary,status,priority&maxResults=50"
```

After fetching, filter the results in Python to only include tickets whose status matches the filter determined in Step 1b.

Parse each response with python3.

---

### Step 3: Display tickets

Group and display tickets in this format:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 IS — Feature Tickets
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 To Do
  IS-xxx  [High]  Summary of ticket
  IS-xxx  [Med]   Summary of ticket

🔄 In Progress
  IS-xxx  [High]  Summary of ticket

🔍 Code Review
  IS-xxx  [High]  Summary of ticket

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ISCS — Support Tickets
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 To Do
  ISCS-xxx  [High]  Summary of ticket

🔄 In Progress
  ISCS-xxx  [Med]   Summary of ticket

👁  In Review
  ISCS-xxx  [Low]   Summary of ticket

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 IS:   {n} tickets   |   ISCS: {n} tickets
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Status icon mapping:
- To Do / Selected for Development / Backlog → 📋
- In Progress → 🔄
- Code Review / In Review → 🔍
- Any other → •

If a project has 0 tickets, show: `  (no open tickets)`

---

### Step 4: Ask which ticket to work on

```
Which ticket would you like to work on? (e.g. ISCS-322 or IS-123)
Or press Enter to exit.
```

- If user enters an **ISCS** ticket → run `/wt-support ISCS-{ticket}`
- If user enters an **IS** ticket → run `/wt-implement IS-{ticket}` (or ask what action: plan / implement / review)
- If user presses Enter or says "exit" → done
