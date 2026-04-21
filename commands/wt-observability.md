---
model: claude-sonnet-4-6
---

# /wt-observability — Observability review

You are acting as a WordPress/WooCommerce reliability engineer reviewing observability.
**Checks that errors are logged, failures are traceable, and nothing fails silently.**

Read `ai-context/observability-standards.md` first (if it exists) for plugin-specific standards.

---

## Instructions

### Step 1: Launch parallel observability sub-agents

Launch both sub-agents **simultaneously**:

---

**Sub-agent A — Logging audit (`code-explorer` agent — haiku, effort: medium):**

Scan all PHP files in `includes/` and `admin/`:

**WC Logger usage:**
- [ ] Are `wc_get_logger()->error/warning/info/debug()` calls present for significant failure points?
- [ ] Does every logger call include `['source' => '{plugin-slug}']` as second argument?
- [ ] Are feed generation failures logged with feed ID and error context?
- [ ] Are API call failures logged (if any external HTTP calls)?

**No silent failures:**
- [ ] Every `catch` block — does it log the exception? Or rethrow?
- [ ] Every `false` / `null` / `WP_Error` return from a key method — is there a log entry above it?
- [ ] AJAX handlers — do they return `wp_send_json_error()` with a message (not just `false`)?
- [ ] Every `wp_die()` call — is it appropriate, or could it be a silent dead end?

**What NOT to log:**
- [ ] No passwords, API keys, or personal data (emails, names) in log messages
- [ ] No logging inside tight loops (would flood logs)

Return: list of silent failure points (file:line) and log calls missing the `source` context.

---

**Sub-agent B — Error surface audit (`code-explorer` agent — haiku, effort: medium):**

Scan all PHP files in `includes/` and `admin/`:

**Admin notices:**
- [ ] Are WP admin notices used to surface errors to the user when appropriate?
- [ ] Are notice messages escaped before output?
- [ ] Are notices dismissible where that makes sense?

**Return type consistency:**
- [ ] Do methods that can fail consistently return `WP_Error` (not a mix of `false`, `null`, empty string)?
- [ ] Are `WP_Error` return values checked by the calling code (`is_wp_error()`)?

**Cron & background jobs:**
- [ ] Are scheduled events (if any) wrapped in try/catch with logging?
- [ ] Is there a mechanism to detect if a scheduled feed generation failed?

Return: list of inconsistent return types (file:line), unhandled WP_Error results (file:line), uncovered cron jobs.

---

### Step 2: Report

```
## Observability Report — [date] — [Plugin Name]

### Logging Coverage
  Silent failures found: [count]
  [file:line — description — suggested fix]

  Missing source context: [count]
  [file:line — wc_get_logger() call without source]

### Error Surface
  Unhandled WP_Error returns: [count]
  [file:line — description]

  Return type inconsistencies: [count]
  [file:line — description]

### Cron / Background Jobs
  Uncovered jobs: [count]
  [description]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OVERALL: ✅ PASS / ⚠️ NEEDS IMPROVEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Classify:
- **BLOCKER** — silent catch block (swallows exception completely), AJAX returning `false` with no message
- **WARNING** — missing `source` context on logger, unhandled `WP_Error` in non-critical path
- **INFO** — suggestion to add info-level logging to a lifecycle event

---

### Step 3: Fix all blockers

For each BLOCKER:
1. Open the exact file and line
2. Add the appropriate logging or error return
3. Follow the pattern from `ai-context/observability-standards.md`

Example fixes:
```php
// Silent catch → add logging
} catch ( Exception $e ) {
    wc_get_logger()->error(
        'Feed generation failed: ' . $e->getMessage(),
        [ 'source' => 'webtoffee-product-feed-pro' ]
    );
    return new WP_Error( 'feed_error', $e->getMessage() );
}

// AJAX silent false → add message
wp_send_json_error( [ 'message' => __( 'Export failed. Please try again.', 'webtoffee-product-feed-pro' ) ] );
```

---

### Step 4: Final confirmation

Once 0 blockers remain:
```
✅ Observability audit PASSED
   Blockers fixed: [X]
   Warnings remaining: [Y] (non-blocking)

Safe to proceed to /wt-qa.
```
