---
model: claude-sonnet-4-6
---

# /wt-qa — Full QA pipeline

You are acting as a QA lead for a WordPress/WooCommerce plugin release.

## Instructions

Run the complete QA pipeline end-to-end. Do NOT skip any phase.
**Commit is blocked until all phases pass.**

---

### Launch parallel QA sub-agents

Launch the following sub-agents **simultaneously** using the Agent tool:

**Sub-agent A — Phase 1: PHPCS (`qa-runner` agent — sonnet, effort: high):**

Detect plugin type first, then run diff-aware PHPCS — only changed PHP files, only changed lines:
```bash
# Detect plugin type: Woo: header = WooCommerce Marketplace, otherwise WordPress.org
MAIN_PLUGIN_FILE=$(grep -rl "Plugin Name:" --include="*.php" . | head -1)
if grep -qi "^\s*\*\s*Woo:" "$MAIN_PLUGIN_FILE" 2>/dev/null; then
  PHPCS_STANDARD="WooCommerce"
else
  PHPCS_STANDARD="WordPress"
fi
echo "Detected PHPCS standard: $PHPCS_STANDARD"

CHANGED=$(git diff --name-only origin/master...HEAD -- '*.php' | tr '\n' ' ')
if [ -z "$CHANGED" ]; then echo "No PHP files changed — PHPCS skipped."; exit 0; fi
git diff -U0 origin/master...HEAD -- $CHANGED > /tmp/wt_diff.patch

./vendor/bin/phpcs --standard=$PHPCS_STANDARD $CHANGED --report=csv 2>/dev/null > /tmp/phpcs_out.csv
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
    print(f"{std} PHPCS: 0 issues. ✅")
EOF

# Auto-fix changed files if needed, then re-check
./vendor/bin/phpcbf --standard=$PHPCS_STANDARD $CHANGED 2>&1 | tail -5
```
- Return: detected standard, issue counts on changed lines only; list of remaining issues after auto-fix

**Sub-agent B — Phase 2: Unit Tests (`qa-runner` agent — sonnet, effort: high):**
```bash
./vendor/bin/phpunit --testdox --colors=always 2>&1
./vendor/bin/phpunit --coverage-text --colors=never 2>&1 | tail -20
```
- Return: pass/fail counts, coverage percentage, any failing test names

**Sub-agent C — Phase 4: WooCommerce Compatibility (`qa-runner` agent — sonnet, effort: high):**
```bash
# Deprecated hooks / functions
grep -rn "get_woocommerce_currency\|WC_Order::get_formatted\|woocommerce_add_notice\|WC_Order->id" includes/

# HPOS compatibility
grep -rn "get_post_meta.*_order\|update_post_meta.*_order\|WP_Query.*shop_order" includes/

# Plugin headers
grep "Requires at least\|Requires PHP\|WC requires at least" *.php
```
- Return: deprecated functions found (if any), HPOS status, plugin header values

Wait for all three sub-agents to complete, then continue with Phase 3 and Phase 5.

---

### Phase 3: Security Checklist

Verify in code (scan `includes/` manually):
- [ ] All `$_GET`, `$_POST`, `$_REQUEST` sanitized with `sanitize_*()`
- [ ] All DB queries use `$wpdb->prepare()`
- [ ] All nonces verified on write operations
- [ ] All output escaped with `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses_post()`
- [ ] Capability checks on all admin actions with `current_user_can()`
- [ ] File operations use `WP_Filesystem` API
- [ ] ABSPATH check at top of every PHP file

FAIL = block. Fix security issues before continuing.

---

### Phase 5: Performance

Invoke **wp-performance** skill then check:
- [ ] No queries inside loops (N+1 problem)
- [ ] Transients used for expensive operations
- [ ] Assets enqueued only on relevant pages — not globally
- [ ] No heavy operations on `init` or `plugins_loaded`

---

### Final QA Report

```
## QA Report — [date] — [Plugin Name] v[version]

Phase 1 — PHPCS [detected standard]     : PASS / FAIL
Phase 2 — PHPUnit (X/Y passing, Z% coverage) : PASS / FAIL
Phase 3 — Security Checklist              : PASS / FAIL
Phase 4 — WC Compatibility                : PASS / FAIL
Phase 5 — Performance                     : PASS / FAIL

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OVERALL: ✅ READY TO RELEASE / ❌ NEEDS FIXES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Blocker issues (must fix before commit):
[list]

Non-blocker issues (fix in next version):
[list]
```

Only output `READY TO RELEASE` when every phase is PASS.
