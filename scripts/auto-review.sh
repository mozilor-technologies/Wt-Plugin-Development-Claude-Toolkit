#!/usr/bin/env bash
# auto-review.sh — Triggered automatically after every PHP file edit
# Runs PHPCS on the saved file — standard auto-detected from plugin header (Woo: tag → WooCommerce, else WordPress)
# Usage: auto-review.sh [file_path]

FILE="$1"
PLUGIN_DIR="$(pwd)"

# Only act on PHP files
if [[ "$FILE" != *.php ]]; then
  exit 0
fi

# Only act on files inside includes/ or root *.php
if [[ "$FILE" != *includes/* && "$FILE" != *$PLUGIN_DIR/*.php ]]; then
  exit 0
fi

# Find PHPCS binary — check plugin dir first, then global
if [ -f "$PLUGIN_DIR/vendor/bin/phpcs" ]; then
  PHPCS="$PLUGIN_DIR/vendor/bin/phpcs"
elif command -v phpcs &>/dev/null; then
  PHPCS="phpcs"
else
  PHPCS=""
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  AUTO REVIEW: $(basename $FILE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ERRORS=0

if [ -z "$PHPCS" ]; then
  echo "  ⚠️  PHPCS not found — run: composer require --dev squizlabs/php_codesniffer wp-coding-standards/wpcs"
  exit 0
fi

# ── Detect PHPCS standard from plugin header ──────
MAIN_PLUGIN_FILE=$(grep -rl "Plugin Name:" --include="*.php" "$PLUGIN_DIR" | head -1)
if grep -qi "^\s*\*\s*Woo:" "$MAIN_PLUGIN_FILE" 2>/dev/null; then
  PHPCS_STANDARD="WooCommerce"
else
  PHPCS_STANDARD="WordPress"
fi
echo "  Detected standard: $PHPCS_STANDARD"

# ── PHPCS (detected standard) ─────────────────────
echo ""
echo "▶ PHPCS ($PHPCS_STANDARD standard)..."
PHPCS_OUT=$($PHPCS --standard=$PHPCS_STANDARD "$FILE" --report=summary 2>&1)
PHPCS_EXIT=$?
if [ $PHPCS_EXIT -ne 0 ]; then
  echo "  ❌ PHPCS $PHPCS_STANDARD violations:"
  $PHPCS --standard=$PHPCS_STANDARD "$FILE" --report=full 2>&1 | grep -E "ERROR|WARNING|FOUND" | head -20
  ERRORS=$((ERRORS + 1))
else
  echo "  ✅ PHPCS $PHPCS_STANDARD: no violations"
fi

# ── Summary ──────────────────────────────────────
echo ""
if [ $ERRORS -eq 0 ]; then
  echo "  ✅ REVIEW PASSED — $(basename $FILE)"
else
  echo "  ❌ REVIEW FAILED — $ERRORS standard(s) reported issues. Fix before continuing."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
