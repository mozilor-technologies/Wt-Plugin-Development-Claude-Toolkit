---
model: claude-sonnet-4-6
---

# /wt-fix-review — Read PR comments, fix clear ones, reply to vague ones

You are acting as a Senior WordPress/WooCommerce developer responding to code review feedback.

## Instructions

---

### Step 1: Get the PR

Ask if not already known:
```
Which PR should I review comments for?
Paste the Bitbucket PR URL or PR number.
```

---

### Step 2: Read all open comments

Use Atlassian MCP to fetch all **unresolved** comments from the Bitbucket PR.

List them:
```
Found [X] unresolved comments:

Comment 1 (by reviewer, file:line): "[comment text]"
Comment 2 (by reviewer, file:line): "[comment text]"
...
```

---

### Step 3: Classify each comment

For each comment, determine if it is **CLEAR** or **VAGUE**:

**CLEAR** — specific, actionable, you know exactly what to change:
- References a specific file and line
- Describes a concrete problem: "missing nonce", "use esc_html()", "this runs inside a loop"
- Has an obvious fix

**VAGUE** — unclear, no specific action can be determined:
- "This doesn't look right"
- "Can you improve this?"
- "Refactor this part"
- "This seems off"
- No file/line reference
- No description of what the actual problem is

---

### Step 4: Process CLEAR comments — fix them

For each CLEAR comment:

1. Open the exact file and line referenced
2. Invoke **wp-plugin-development** skill to apply the correct fix pattern
3. Apply the fix following WordPress + WooCommerce coding standards
4. PHPCS check after fix (auto-review hook fires on save)
5. Fix any PHPCS errors introduced by the change

---

### Step 5: Process VAGUE comments — reply asking for clarity

For each VAGUE comment, do NOT touch any code.

Use Atlassian MCP to post a reply on that comment in Bitbucket:

```
Hi [reviewer name],

Could you help clarify this comment so I can address it correctly?

Specifically:
- Which line or block of code are you referring to?
- What behaviour or issue are you seeing?
- What should it do differently?

Thanks
```

Leave the comment **unresolved** — it stays open until the reviewer responds.

---

### Step 6: Show summary to user

Before committing anything, display:

```
## /wt-fix-review Summary

✅ FIXED (X comments):
  Comment 1 — "Missing nonce verification" → fixed in class-wtpf-tiktok-feed.php line 87
  Comment 2 — "Use esc_html() instead of echo" → fixed in class-wtpf-admin.php line 34

⏳ WAITING FOR CLARITY (Y comments):
  Comment 3 — "This doesn't look right" → replied asking for specifics
  Comment 4 — "Can you improve this?" → replied asking for specifics

Files changed:
  includes/feeds/class-wtpf-tiktok-feed.php
  includes/admin/class-wtpf-admin.php

Commit these fixes? (yes / cancel)
```

Wait for explicit **yes** before committing.

---

### Step 7: Commit the fixes

If user says yes:

Build commit message:
```
IS-123: fix: address PR review comments

- Added nonce verification to feed save action (Comment 1)
- Replaced echo with esc_html() in admin template (Comment 2)

Jira: IS-123
Reviewed-by: Claude (PHPCS ✅)
```

Show message → user approves → commit → push.

---

### Step 8: Mark resolved comments on Bitbucket

Use Atlassian MCP to:
- Mark each FIXED comment as **resolved** on Bitbucket
- Post a reply on each resolved comment:
  ```
  Fixed in commit [hash] — [one line description of fix]
  ```

Leave VAGUE comments **open** — they are already waiting for reviewer response.

---

### Step 9: Final summary

```
✅ [X] comments fixed and resolved on Bitbucket
⏳ [Y] comments waiting for reviewer clarification

Once the reviewer clarifies the remaining comments,
run /wt-fix-review again to process them.
```

---

### Notes
- Never fix a vague comment by guessing — always ask for clarity first
- Never commit without user approval
- Run PHPCS after every fix — do not accumulate unfixed violations
- If a fix introduces a new PHPCS error — fix that too before committing
