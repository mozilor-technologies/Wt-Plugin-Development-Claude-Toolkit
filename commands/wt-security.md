---
model: claude-opus-4-6
---

# /wt-security — Dedicated security audit

You are acting as a WordPress/WooCommerce application security engineer.
**This is a standalone security gate. Commit is blocked until this passes.**

Invoke the **wp-plugin-development** skill before starting.

---

## Instructions

### Step 1: Launch parallel security sub-agents

Launch all four sub-agents **simultaneously**:

---

**Sub-agent A — Input handling audit (`security-auditor` agent — sonnet, effort: medium):**

Scan all PHP files in `includes/` and `admin/` for:
- [ ] Every `$_GET`, `$_POST`, `$_REQUEST`, `$_COOKIE`, `$_SERVER` usage
- For each: is it sanitized with `sanitize_text_field()`, `sanitize_email()`, `absint()`, `intval()`, `wp_unslash()` etc. before use?
- [ ] `get_option()` / `get_post_meta()` values used in output — are they escaped?
- [ ] Any use of `$wpdb->query()` or raw SQL without `$wpdb->prepare()`

Return: list of file:line references where input is unsanitized or output is unescaped.

---

**Sub-agent B — Auth & capability audit (`security-auditor` agent — sonnet, effort: medium):**

Scan all PHP files in `includes/` and `admin/` for:
- [ ] Every AJAX handler (`wp_ajax_*`, `wp_ajax_nopriv_*`) — does it call `check_ajax_referer()` AND `current_user_can()`?
- [ ] Every admin form handler — does it call `check_admin_referer()` AND `current_user_can()`?
- [ ] Every REST API endpoint — does it have a `permission_callback` that checks capabilities?
- [ ] Any file reads/writes — are they gated by `current_user_can()`?
- [ ] All nonce verifications using `wp_verify_nonce()` or `check_admin_referer()` — are they present where needed?

Return: list of handlers missing nonce check or capability check, with file:line.

---

**Sub-agent C — Injection & secrets audit (`security-auditor` agent — sonnet, effort: medium):**

Scan all PHP files for:
- [ ] `eval()` usage — flag every occurrence
- [ ] `base64_decode()` on dynamic input — flag every occurrence
- [ ] `system()`, `exec()`, `shell_exec()`, `passthru()`, `popen()` — flag every occurrence
- [ ] Hard-coded credentials, API keys, passwords in source files
- [ ] `unserialize()` on user-controlled data
- [ ] `include` / `require` with variable paths not validated against an allowlist
- [ ] ABSPATH check at top of every PHP file: `defined( 'ABSPATH' ) || exit;`

Return: every flagged line with file:line and reason.

---

**Sub-agent D — Dependency & exposure audit (`security-auditor` agent — sonnet, effort: medium):**

```bash
# Check composer.json for known-vulnerable packages (outdated versions)
cat composer.json 2>/dev/null || echo "no composer.json"

# Check for files that should not be publicly accessible
find . -name "*.log" -o -name "*.sql" -o -name "*.bak" -o -name ".env" 2>/dev/null | grep -v vendor | grep -v node_modules

# Check for direct PHP file access protection
grep -rn "ABSPATH" includes/ admin/ --include="*.php" | grep -c "exit" || echo "0"
```

Return: vulnerable dependencies (if any), exposed files (if any), ABSPATH exit count vs PHP file count.

---

### Step 2: Report findings

Classify every finding as:
- **BLOCKER** — must fix before commit (injection risk, missing nonce, missing capability check, unescaped output with user data)
- **WARNING** — should fix (missing ABSPATH check, outdated dep with no known exploit)
- **INFO** — note for awareness (e.g. a TODO comment mentioning auth)

```
## Security Audit Report — [date] — [Plugin Name]

### Input/Output
  BLOCKERS: [count]
  [file:line — description]

### Auth & Capabilities
  BLOCKERS: [count]
  [file:line — description]

### Injection & Secrets
  BLOCKERS: [count]
  [file:line — description]

### Dependencies & Exposure
  WARNINGS: [count]
  [description]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OVERALL: ✅ PASS / ❌ FAIL — [X] blockers, [Y] warnings
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Step 3: Fix all blockers

For each BLOCKER:
1. Open the file at the exact line
2. Apply the correct fix (sanitize, escape, add nonce check, add capability check)
3. Re-run the relevant sub-agent check to confirm the fix
4. Do not move to the next blocker until the current one is confirmed fixed

After all fixes:
```bash
MAIN_PLUGIN_FILE=$(grep -rl "Plugin Name:" --include="*.php" . | head -1)
if grep -qi "^\s*\*\s*Woo:" "$MAIN_PLUGIN_FILE" 2>/dev/null; then
  PHPCS_STANDARD="WooCommerce"
else
  PHPCS_STANDARD="WordPress"
fi
./vendor/bin/phpcs --standard=$PHPCS_STANDARD includes/ admin/ --report=summary 2>&1
```
Ensure no new PHPCS errors were introduced by the fixes.

---

### Step 4: Final confirmation

Once 0 blockers remain:
```
✅ Security audit PASSED
   Blockers fixed: [X]
   Warnings remaining: [Y] (non-blocking)

Safe to proceed to /wt-observability or /wt-qa.
```
