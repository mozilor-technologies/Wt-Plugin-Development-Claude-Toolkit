---
model: claude-sonnet-4-6
---

# /wt-support — Triage and resolve a support ticket (ISCS)

You are acting as a senior developer handling a WooCommerce plugin support ticket.
**Never post to Jira or make code changes without explicit user approval.**

---

## Usage

```
/wt-support ISCS-{ticket}
```

---

## Jira Transition IDs (ISCS project)

| ID  | Status                  |
|-----|-------------------------|
| 11  | In Progress             |
| 31  | In Review               |
| 51  | Done                    |
| 71  | TODO                    |
| 91  | Ready For Testing       |
| 101 | Testing in progress     |

**Auto-transition rules (applied after solution is posted/committed):**
- Code snippet shared → transition to **In Review** (ID: 31)
- Plugin code change → transition to **In Review** (ID: 31)

---

### Step 1: Parse arguments

Extract the ticket number from the arguments (e.g. `ISCS-322`).
If missing, ask:
```
Which support ticket? (e.g. ISCS-322)
```

---

### Step 2: Fetch the Jira ticket

Read credentials from `~/.claude/settings.json`:
- `mcpServers.atlassian.env.JIRA_URL`
- `mcpServers.atlassian.env.JIRA_USERNAME`
- `mcpServers.atlassian.env.JIRA_API_TOKEN`

Fetch the ticket:

```bash
curl -s -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/$TICKET?fields=summary,description,comment,status,priority,timetracking,timeestimate,timespent"
```

Parse and display:
```
🎫 ISCS-xxx: {summary}
Status:    {status}
Priority:  {priority}

Description:
{description}

Latest comments:
{last 2-3 comments if any}
```

---

### Step 3: Analyze — Plugin change or code snippet?

Read the ticket carefully and decide:

**Route A — Plugin change required** when:
- The fix requires editing plugin source files
- It is a confirmed bug in the plugin code
- A new option, filter, or hook needs to be added to the plugin

**Route B — Code snippet sufficient** when:
- The requirement can be met with a custom snippet the user adds to their theme/child theme or a custom plugin
- It involves a `add_filter` / `add_action` customization outside our plugin
- It is a "how do I achieve X" question answerable with a code example
- The fix is site-specific and not a general plugin bug

Present your analysis clearly:

```
📋 Analysis: {one paragraph explaining what the ticket is asking}

🔀 Recommended route: [Plugin change / Code snippet]
Reason: {why}
```

Ask for confirmation:
```
Proceed with [Plugin change / Code snippet]? (yes / change route)
```

Wait for user confirmation before continuing.

---

### Step 4A — Plugin change route

Follow the standard fix workflow:

1. Create branch `fix/ISCS-{ticket}-{short-description}` if not already on it
2. Implement the fix
3. Run `/wt-commit` to stage, review, and commit
4. Run `/wt-qa` if needed

After commit is pushed, proceed to **Step 5 (time logging)** then **Step 6 (transition)**.

---

### Step 4B — Code snippet route

**Step 4B-1: Prepare the snippet**

Write a clean, well-commented code snippet that solves the ticket requirement.

Rules:
- Use WordPress/WooCommerce coding standards
- Add a comment block at the top:
  ```php
  /**
   * [Short description of what this does]
   * Add this code to your child theme's functions.php or a custom plugin.
   *
   * @ticket ISCS-{ticket}
   */
  ```
- Keep it minimal — only what is needed
- Test logic mentally against the ticket requirements

Display the snippet to the user:

```
Here is the code snippet I'll post on ISCS-{ticket}:

--- SNIPPET START ---
{snippet}
--- SNIPPET END ---

Post this as a Jira comment? (yes / edit / cancel)
```

**Never post to Jira without explicit "yes" from the user.**

---

**Step 4B-2: User approves**

- **yes** → proceed to Step 4B-3
- **edit** → ask what to change, revise, show again, repeat
- **cancel** → abort, do not post anything

---

**Step 4B-3: Post the snippet as a Jira comment**

Format the comment body in Atlassian Document Format (ADF):

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
          "content": [{ "type": "text", "text": "Hi, please add the following code snippet to your child theme'\''s functions.php or a custom plugin to achieve this:" }]
        },
        {
          "type": "codeBlock",
          "attrs": { "language": "php" },
          "content": [{ "type": "text", "text": "<SNIPPET>" }]
        },
        {
          "type": "paragraph",
          "content": [{ "type": "text", "text": "Let us know if you need any further assistance." }]
        }
      ]
    }
  }' \
  "$JIRA_URL/rest/api/3/issue/$TICKET/comment"
```

Parse response with python3 — on success proceed to Step 5. On failure, show the error and ask the user how to proceed.

---

### Step 5: Finalize — log time + transition (parallel)

Ask the user (single message):

```
⏱  Time logging for ISCS-{ticket}

Estimated time to solve? (e.g. 1h, 30m, 2h 30m)
Actual time spent?       (e.g. 45m, 1h 15m)
```

Wait for user input. Convert to seconds for the API (1h = 3600, 1m = 60).

Once you have both values, fire all three Jira operations **in parallel** using background processes:

```bash
# 1. Set original estimate
curl -s -X PUT \
  -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"fields": {"timetracking": {"originalEstimate": "<estimate>", "remainingEstimate": "0"}}}' \
  "$JIRA_URL/rest/api/3/issue/$TICKET" > /tmp/jira_estimate.json &

# 2. Log work done
curl -s -X POST \
  -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"timeSpent": "<time_spent>", "comment": {"type": "doc", "version": 1, "content": [{"type": "paragraph", "content": [{"type": "text", "text": "Time logged for support resolution."}]}]}}' \
  "$JIRA_URL/rest/api/3/issue/$TICKET/worklog" > /tmp/jira_worklog.json &

# 3. Transition to In Review
curl -s -X POST \
  -u "$JIRA_USER:$JIRA_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"transition": {"id": "31"}}' \
  "$JIRA_URL/rest/api/3/issue/$TICKET/transitions" > /tmp/jira_transition.json &

wait  # wait for all three to complete

# Check results
python3 -c "
import json
for label, path in [('Estimate', '/tmp/jira_estimate.json'), ('Worklog', '/tmp/jira_worklog.json'), ('Transition', '/tmp/jira_transition.json')]:
    try:
        data = json.load(open(path))
        if 'errorMessages' in data and data['errorMessages']:
            print(f'  ❌ {label}: {data[\"errorMessages\"]}')
        elif 'errors' in data and data['errors']:
            print(f'  ❌ {label}: {data[\"errors\"]}')
        else:
            print(f'  ✅ {label}: OK')
    except:
        print(f'  ✅ {label}: OK')
"
```

Confirm: `✅ Time logged — Estimate: {estimate}, Spent: {spent} | Status → In Review`

---

### Final summary

**Plugin change route:**
```
✅ Route:      Plugin change
✅ Branch:     fix/ISCS-{ticket}-{description}
✅ Committed & pushed
✅ Time logged: Estimate {x}, Spent {y}
✅ Status:     → In Review
```

**Code snippet route:**
```
✅ Route:      Code snippet
✅ Comment:    Posted on ISCS-{ticket}
✅ Time logged: Estimate {x}, Spent {y}
✅ Status:     → In Review
```
