---
model: claude-sonnet-4-6
---

# /wt-review — Full automated code review

You are acting as a Senior WordPress/WooCommerce security and quality engineer.

## Instructions

Run a full code review on all PHP files in `includes/` and report results.
Invoke the **wp-plugin-development** and **wp-performance** skills before starting.

---

### Step 1: Launch parallel review sub-agents

Launch the following sub-agents **simultaneously** using the Agent tool:

**Sub-agent A — PHPCS (`qa-runner` agent — sonnet, effort: high):**

First detect the plugin type, then run only the matching standard (diff-aware):
```bash
# Detect plugin type: Woo: header = WooCommerce Marketplace, otherwise WordPress.org
MAIN_PLUGIN_FILE=$(grep -rl "Plugin Name:" --include="*.php" . | head -1)
if grep -qi "^\s*\*\s*Woo:" "$MAIN_PLUGIN_FILE" 2>/dev/null; then
  PHPCS_STANDARD="WooCommerce"
else
  PHPCS_STANDARD="WordPress"
fi
echo "Detected PHPCS standard: $PHPCS_STANDARD"

# Get changed PHP files vs master
CHANGED=$(git diff --name-only origin/master...HEAD -- '*.php' | tr '\n' ' ')
if [ -z "$CHANGED" ]; then echo "No PHP files changed — PHPCS skipped."; exit 0; fi

# Save diff for line filtering
git diff -U0 origin/master...HEAD -- $CHANGED > /tmp/wt_diff.patch

# Run PHPCS on changed files only, CSV output
./vendor/bin/phpcs --standard=$PHPCS_STANDARD $CHANGED --report=csv 2>/dev/null > /tmp/phpcs_out.csv

# Filter to changed lines only
python3 - <<EOF
import csv, re, os
std = "$PHPCS_STANDARD"
changed = {}
cur = None
with open('/tmp/wt_diff.patch') as f:
    for line in f:
        m = re.match(r'^\+\+\+ b/(.+)$', line)
        if m: cur = m.group(1); changed[cur] = set()
        m = re.match(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@', line)
        if m and cur:
            s, n = int(m.group(1)), int(m.group(2)) if m.group(2) else 1
            changed[cur].update(range(s, s + max(n, 1)))
issues = []
try:
    with open('/tmp/phpcs_out.csv') as f:
        for row in csv.DictReader(f):
            fp, ln = row.get('File',''), int(row.get('Line',0))
            for k in changed:
                if fp.endswith(k) or k.endswith(fp):
                    if ln in changed[k]: issues.append(row); break
except: pass
if issues:
    print(f"{std} PHPCS: {len(issues)} issue(s) on changed lines:")
    for e in issues: print(f"  {e['File']}:{e['Line']} [{e['Type']}] {e['Message']}")
else:
    print(f"{std} PHPCS: 0 issues on changed lines. ✅")
EOF
```
- Return: detected standard, violations on changed lines only, with file:line

**Sub-agent C — Security audit (`security-auditor` agent — sonnet, effort: medium):**
Scan all PHP files in `includes/` and check:
- [ ] No unescaped output — every `echo` uses `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses_post()`
- [ ] No unsanitized input — every `$_POST`, `$_GET`, `$_REQUEST` uses `sanitize_*()`
- [ ] Nonce checks on all form handlers and AJAX — `check_admin_referer()` or `check_ajax_referer()`
- [ ] Capability checks on all admin actions — `current_user_can()`
- [ ] No raw SQL — all queries use `$wpdb->prepare()`
- [ ] No `eval()` or `base64_decode()` usage
- [ ] No direct file includes without path validation
- [ ] ABSPATH check at top of every file
- Return: list of issues with file:line

**Sub-agent D — WooCommerce compatibility (`qa-runner` agent — sonnet, effort: high):**
```bash
# Check for deprecated WC functions
grep -rn "get_woocommerce_currency\|WC_Order::get_formatted\|woocommerce_add_notice\|WC_Order->id" includes/ 2>&1

# Check HPOS compatibility
grep -rn "get_post_meta.*_order\|update_post_meta.*_order\|WP_Query.*shop_order" includes/ 2>&1

# Check plugin headers
grep "Requires at least\|Requires PHP\|WC requires at least" *.php
```
- Return: deprecated functions found, HPOS status, plugin header values

Wait for all four sub-agents to complete before continuing.

---

### Step 2: Auto-fix PHPCS issues

If issues were found, auto-fix only the changed PHP files using the detected standard:
```bash
MAIN_PLUGIN_FILE=$(grep -rl "Plugin Name:" --include="*.php" . | head -1)
if grep -qi "^\s*\*\s*Woo:" "$MAIN_PLUGIN_FILE" 2>/dev/null; then
  PHPCS_STANDARD="WooCommerce"
else
  PHPCS_STANDARD="WordPress"
fi
CHANGED=$(git diff --name-only origin/master...HEAD -- '*.php' | tr '\n' ' ')
./vendor/bin/phpcbf --standard=$PHPCS_STANDARD $CHANGED 2>&1
```

Re-run the diff-aware PHPCS check from Step 1 to confirm remaining issues.

---

### Step 3: Performance audit

Invoke **wp-performance** skill then check:
- [ ] No `get_posts()` or `WP_Query` inside loops (N+1 queries)
- [ ] Expensive operations cached with `get_transient()` / `set_transient()`
- [ ] Assets enqueued only on relevant admin pages
- [ ] No heavy operations on `init` or `plugins_loaded`
- [ ] `wp_cache_get()` / `wp_cache_set()` used for repeated queries

---

### Step 4: Report

```
## Code Review Report — [date] — [Plugin Name]

### PHPCS [detected standard]:  X errors, Y warnings
### Security:         X issues found
### WC Compatibility: X concerns
### Performance:      X issues found

### Overall: PASS / NEEDS FIXES

### Issues requiring manual fix:
[file:line — description]

### Auto-fixed:
[list of files auto-fixed by phpcbf]
```

Fix all auto-fixable issues. List every manual fix required with exact file:line.
Do not mark PASS until all errors are zero.
