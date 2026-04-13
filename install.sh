#!/bin/bash

################################################################################
# WebToffee Claude Toolkit — Plugin Installer
#
# Run this from inside any plugin directory:
#   ~/claude-toolkit/install.sh
################################################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TOOLKIT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PLUGIN_DIR="$(pwd)"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE} WebToffee Claude Toolkit — Install${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Installing into: $PLUGIN_DIR"
echo ""

# Check we're inside a git repo
if ! git rev-parse --show-toplevel &>/dev/null; then
  echo -e "${YELLOW}⚠️  Not inside a git repo. Continue anyway? (y/n)${NC}"
  read -n 1 -r; echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

# Create .claude structure
mkdir -p "$PLUGIN_DIR/.claude/agents" \
         "$PLUGIN_DIR/.claude/skills" \
         "$PLUGIN_DIR/.claude/scripts" \
         "$PLUGIN_DIR/.claude/commands"

# Copy toolkit files
cp -r "$TOOLKIT_DIR/agents/." "$PLUGIN_DIR/.claude/agents/"
cp -r "$TOOLKIT_DIR/skills/." "$PLUGIN_DIR/.claude/skills/"
cp -r "$TOOLKIT_DIR/scripts/." "$PLUGIN_DIR/.claude/scripts/"
cp -r "$TOOLKIT_DIR/commands/." "$PLUGIN_DIR/.claude/commands/"
chmod +x "$PLUGIN_DIR/.claude/scripts/"*.sh 2>/dev/null || true

echo -e "${GREEN}✅ agents   — $(ls "$PLUGIN_DIR/.claude/agents" | wc -l | tr -d ' ') files${NC}"
echo -e "${GREEN}✅ skills   — $(ls "$PLUGIN_DIR/.claude/skills" | wc -l | tr -d ' ') files${NC}"
echo -e "${GREEN}✅ scripts  — $(ls "$PLUGIN_DIR/.claude/scripts" | wc -l | tr -d ' ') files${NC}"
echo -e "${GREEN}✅ commands — $(ls "$PLUGIN_DIR/.claude/commands" | wc -l | tr -d ' ') files${NC}"

# Copy settings.json.example if not already there
if [ ! -f "$PLUGIN_DIR/.claude/settings.json.example" ]; then
  cp "$TOOLKIT_DIR/settings.json.example" "$PLUGIN_DIR/.claude/"
  echo -e "${GREEN}✅ settings.json.example copied${NC}"
fi

# Create settings.json from example if not already there
if [ ! -f "$PLUGIN_DIR/.claude/settings.json" ]; then
  cp "$TOOLKIT_DIR/settings.json.example" "$PLUGIN_DIR/.claude/settings.json"
  echo -e "${YELLOW}⚠️  settings.json created from example — fill in your credentials${NC}"
else
  echo -e "${GREEN}✅ settings.json already exists — skipped${NC}"
fi

# Add .claude/ to .gitignore (keep toolkit files local, not committed)
GITIGNORE="$PLUGIN_DIR/.gitignore"
if ! grep -q "^\.claude/$" "$GITIGNORE" 2>/dev/null; then
  echo ".claude/" >> "$GITIGNORE"
  echo -e "${GREEN}✅ .claude/ added to .gitignore${NC}"
else
  echo -e "${GREEN}✅ .claude/ already in .gitignore${NC}"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} Done! Next steps:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Fill in your credentials:"
echo "   nano .claude/settings.json"
echo ""
echo "   Replace placeholders with:"
echo "   - Atlassian API token → https://id.atlassian.com → Security → API tokens"
echo "   - Bitbucket app password → bitbucket.org → Personal settings → App passwords"
echo "   - Figma token → figma.com → Account → Personal access tokens"
echo ""
echo "2. Update hook paths in settings.json:"
echo "   Replace /absolute/path/to/plugin/ with:"
echo "   $PLUGIN_DIR"
echo ""
echo "3. Open Claude Code:"
echo "   claude"
echo ""
