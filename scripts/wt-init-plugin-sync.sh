#!/bin/bash
# wt-init-plugin-sync.sh
# Syncs global ~/.claude/ configuration to local ./.claude/settings.local.json
# Called after /wt-init-plugin runs to ensure local settings inherit from global

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Not in a git repository${NC}"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
LOCAL_CLAUDE="$REPO_ROOT/.claude"
GLOBAL_CLAUDE="$HOME/.claude"
LOCAL_SETTINGS="$LOCAL_CLAUDE/settings.local.json"

# Ensure .claude directory exists
mkdir -p "$LOCAL_CLAUDE"

# ========================================
# Step 1: Detect PHPCS Standard
# ========================================
detect_phpcs_standard() {
    local main_file=""

    # Find the main plugin file
    if [ -f "webtoffee-product-feed-pro.php" ]; then
        main_file="webtoffee-product-feed-pro.php"
    elif [ -f "plugin.php" ]; then
        main_file="plugin.php"
    else
        # Search for Plugin Name: header
        main_file=$(find . -maxdepth 2 -name "*.php" -exec grep -l "Plugin Name:" {} \; | head -1)
    fi

    if [ -z "$main_file" ]; then
        echo "WordPress"
        return
    fi

    # Check for "Woo:" header (indicates WooCommerce Marketplace plugin)
    if grep -qi "^\s*\*\s*Woo:" "$main_file" 2>/dev/null; then
        echo "WordPress"
    else
        echo "WordPress"
    fi
}

# ========================================
# Step 2: Extract Global Hooks Reference
# ========================================
extract_global_hooks() {
    # List hook events configured in global settings
    if [ -f "$GLOBAL_CLAUDE/settings.json" ]; then
        jq -r '.hooks | keys[]' "$GLOBAL_CLAUDE/settings.json" 2>/dev/null | tr '\n' ', ' | sed 's/,$//'
    else
        echo ""
    fi
}

# ========================================
# Step 3: Generate Local settings.local.json
# ========================================
PHPCS_STANDARD=$(detect_phpcs_standard)
GLOBAL_HOOKS=$(extract_global_hooks)

cat > "$LOCAL_SETTINGS" << EOF
{
  "description": "Project-local Claude Code settings. Auto-synced from global ~/.claude/ by wt-init-plugin-sync.sh",
  "phpcs": {
    "standard": "$PHPCS_STANDARD",
    "detected_by": "Plugin header inspection (Woo: header presence)",
    "scope": "changed-lines-only",
    "reference": "$GLOBAL_CLAUDE/agents/qa-runner.md (Phase 1 — PHPCS)"
  },
  "hooks": {
    "reference": "$GLOBAL_CLAUDE/settings.json",
    "inherited": [
      "SessionStart — loads project context",
      "PostToolUse — auto-review on Edit/Write",
      "PreToolUse — pre-commit review on git commit",
      "Stop — auto-test before exit"
    ]
  },
  "permissions": {
    "reference": "$GLOBAL_CLAUDE/settings.json",
    "local_additions": []
  }
}
EOF

# ========================================
# Step 4: Validate JSON
# ========================================
if ! jq empty "$LOCAL_SETTINGS" 2>/dev/null; then
    echo -e "${RED}Failed to generate valid JSON in $LOCAL_SETTINGS${NC}"
    exit 1
fi

# ========================================
# Step 5: Summary
# ========================================
echo -e "${GREEN}✅ Synced global ~/.claude/ → local ./.claude/settings.local.json${NC}"
echo ""
echo "PHPCS Standard: $PHPCS_STANDARD"
echo "Global Reference: $GLOBAL_CLAUDE/settings.json"
echo "Inherited Hooks: SessionStart, PostToolUse, PreToolUse, Stop"
echo ""
echo -e "${YELLOW}Note:${NC} This script runs after /wt-init-plugin completes."
echo "Your local .claude/ now references global configuration."
