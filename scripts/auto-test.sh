#!/usr/bin/env bash
# auto-test.sh — Triggered automatically when Claude stops a session
# Runs PHPUnit and shows a summary

PLUGIN_DIR="$(pwd)"

if [ -f "$PLUGIN_DIR/vendor/bin/phpunit" ]; then
  PHPUNIT="$PLUGIN_DIR/vendor/bin/phpunit"
elif command -v phpunit &>/dev/null; then
  PHPUNIT="phpunit"
else
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  AUTO TEST: PHPUnit not found"
  echo "  Run: composer require --dev phpunit/phpunit"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
fi

# Only run if tests/ directory exists
if [ ! -d "$PLUGIN_DIR/tests" ]; then
  exit 0
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  AUTO TEST: PHPUnit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$PLUGIN_DIR"
OUTPUT=$($PHPUNIT --colors=never 2>&1)
EXIT=$?

# Show last 20 lines (summary)
echo "$OUTPUT" | tail -20

if [ $EXIT -eq 0 ]; then
  echo ""
  echo "  ✅ ALL TESTS PASS"
else
  echo ""
  echo "  ❌ TESTS FAILED — run /test to investigate and fix"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
