#!/usr/bin/env bash
# pre-commit-review.sh
# Runs PHPCS on STAGED PHP files only — standard auto-detected from plugin header (Woo: tag → WooCommerce, else WordPress).
# Only reports errors on lines that were actually added/changed in this commit.
# Exits 1 to BLOCK the commit if new errors are found.

PLUGIN_DIR="$(pwd)"
TOTAL_NEW_ERRORS=0

# Get staged PHP files only
STAGED_PHP=$(git diff --cached --name-only --diff-filter=ACM | grep '\.php$')

if [ -z "$STAGED_PHP" ]; then
  exit 0
fi

echo ""
echo "======================================================"
echo "               PRE-COMMIT CODE REVIEW"
echo "======================================================"
echo ""
echo "Staged PHP files:"
echo "$STAGED_PHP" | sed 's/^/  - /'
echo ""

# Find PHPCS binary
COMPOSER_GLOBAL_BIN="$(composer global config bin-dir --absolute 2>/dev/null)"
if [ -f "$PLUGIN_DIR/vendor/bin/phpcs" ]; then
  PHPCS="$PLUGIN_DIR/vendor/bin/phpcs"
elif command -v phpcs &>/dev/null; then
  PHPCS="phpcs"
elif [ -n "$COMPOSER_GLOBAL_BIN" ] && [ -f "$COMPOSER_GLOBAL_BIN/phpcs" ]; then
  PHPCS="$COMPOSER_GLOBAL_BIN/phpcs"
else
  echo "WARNING: PHPCS not found -- skipping"
  exit 0
fi

# Find PHPCBF binary
PHPCBF=""
if [ -f "$PLUGIN_DIR/vendor/bin/phpcbf" ]; then
  PHPCBF="$PLUGIN_DIR/vendor/bin/phpcbf"
elif [ -n "$COMPOSER_GLOBAL_BIN" ] && [ -f "$COMPOSER_GLOBAL_BIN/phpcbf" ]; then
  PHPCBF="$COMPOSER_GLOBAL_BIN/phpcbf"
fi

# Detect PHPCS standard from plugin header: Woo: tag = WooCommerce Marketplace, otherwise WordPress.org
MAIN_PLUGIN_FILE=$(grep -rl "Plugin Name:" --include="*.php" "$PLUGIN_DIR" | head -1)
if grep -qi "^\s*\*\s*Woo:" "$MAIN_PLUGIN_FILE" 2>/dev/null; then
  DETECTED_STANDARD="WooCommerce"
else
  DETECTED_STANDARD="WordPress"
fi
echo "Detected PHPCS standard: $DETECTED_STANDARD"
echo ""

# Use project .phpcs.xml if it exists, otherwise use detected standard
if [ -f "$PLUGIN_DIR/.phpcs.xml" ] || [ -f "$PLUGIN_DIR/phpcs.xml" ]; then
  PHPCS_ARGS=""
else
  PHPCS_ARGS="--standard=$DETECTED_STANDARD"
fi

# Python3 script to get changed line numbers from git diff output (new-file side only)
GET_CHANGED_LINES_PY='
import sys, re
lines = set()
for line in sys.stdin:
    m = re.match(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@", line)
    if m:
        start = int(m.group(1))
        count = int(m.group(2)) if m.group(2) is not None else 1
        for i in range(start, start + count):
            lines.add(i)
print("\n".join(str(l) for l in sorted(lines)))
'

# Python3 script to parse phpcs JSON and filter to specific line numbers
FILTER_PHPCS_PY='
import json, sys
allowed_lines = set(int(x) for x in sys.argv[1].split(",") if x.strip())
data = json.load(sys.stdin)
errors = 0
for fname, fdata in data.get("files", {}).items():
    file_errors = []
    for msg in fdata.get("messages", []):
        if msg["type"] == "ERROR" and (not allowed_lines or msg["line"] in allowed_lines):
            file_errors.append(f"  Line {msg[\"line\"]}: [{msg[\"source\"]}] {msg[\"message\"]}")
            errors += 1
    if file_errors:
        print(f"\nFILE: {fname}")
        for e in file_errors:
            print(e)
sys.exit(0 if errors == 0 else 1)
'

# ── Run one PHPCS standard, filter to changed lines ─────────────────────────
# Args: label phpcs_args
# Sets global: TOTAL_NEW_ERRORS
run_standard() {
  local label="$1"
  local phpcs_args="$2"
  local standard_errors=0

  echo "  PHPCS -- $label"
  echo "  ------------------------------------------------"

  for staged_file in $STAGED_PHP; do
    # Get changed line numbers for this file (empty = new file = check all)
    if git cat-file -e "HEAD:$staged_file" 2>/dev/null; then
      changed_lines=$(git diff --cached -U0 -- "$staged_file" \
        | python3 -c "$GET_CHANGED_LINES_PY" 2>/dev/null \
        | tr '\n' ',' | sed 's/,$//')
    else
      changed_lines=""  # New file — check all lines
    fi

    # Run phpcs and filter to changed lines only
    phpcs_out=$($PHPCS $phpcs_args --report=json "$staged_file" 2>/dev/null)
    if [ -z "$phpcs_out" ]; then
      continue
    fi

    filtered=$(echo "$phpcs_out" | python3 -c "$FILTER_PHPCS_PY" "${changed_lines}" 2>/dev/null)
    exit_code=$?

    if [ $exit_code -ne 0 ] && [ -n "$filtered" ]; then
      echo "$filtered"
      file_count=$(echo "$filtered" | grep -c "^  Line " || true)
      standard_errors=$((standard_errors + file_count))
    fi
  done

  if [ "$standard_errors" -eq 0 ]; then
    echo "  OK: no new errors in changed lines"
  else
    echo ""
    echo "  FAIL: $standard_errors new error(s) in changed lines"
    if [ -n "$PHPCBF" ]; then
      echo "  Attempting phpcbf auto-fix..."
      $PHPCBF $phpcs_args $STAGED_PHP 2>&1 | tail -3
      echo "  Re-stage files and run again."
    fi
  fi

  TOTAL_NEW_ERRORS=$((TOTAL_NEW_ERRORS + standard_errors))
  echo ""
}

run_standard "$DETECTED_STANDARD" "$PHPCS_ARGS"

echo "======================================================"
if [ "$TOTAL_NEW_ERRORS" -gt 0 ]; then
  echo "  COMMIT BLOCKED -- $TOTAL_NEW_ERRORS new error(s) to fix"
  echo "======================================================"
  echo ""
  exit 1
else
  echo "  ALL CHECKS PASSED -- commit allowed"
  echo "======================================================"
  echo ""
  exit 0
fi
