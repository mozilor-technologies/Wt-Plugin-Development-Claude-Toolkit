#!/usr/bin/env bash
# Session-start hook: loads .context/ files into Claude's context window
# Fires at the start of each Claude Code session for projects that have .context/

CONTEXT_DIR="$(pwd)/.context"

if [ ! -d "$CONTEXT_DIR" ]; then
  exit 0
fi

echo "=== Project Context Loaded ==="
echo ""

for file in "$CONTEXT_DIR"/*.md; do
  [ -f "$file" ] || continue
  filename=$(basename "$file")
  echo "--- $filename ---"
  cat "$file"
  echo ""
done

echo "=== End of Project Context ==="
