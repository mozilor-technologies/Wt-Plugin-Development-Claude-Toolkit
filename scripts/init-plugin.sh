#!/bin/bash

################################################################################
# /wt-init-plugin Implementation Script
#
# Initializes a new WordPress plugin with CLAUDE.md configuration.
# Reads CLAUDE.md.template from ~/.claude/ and fills in user-provided values.
# Usage: bash ~/.claude/scripts/init-plugin.sh
################################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; }

PLUGIN_DIR="$(pwd)"
PLUGIN_DIR_NAME=$(basename "$PLUGIN_DIR")
TEMPLATE="$HOME/.claude/CLAUDE.md.template"

# Check template exists
if [ ! -f "$TEMPLATE" ]; then
  err "CLAUDE.md.template not found at $TEMPLATE"
  echo "Re-run the setup package to restore it."
  exit 1
fi

# Check we're in a WordPress plugin directory
if [ -z "$(find . -maxdepth 1 -name '*.php' -type f)" ]; then
  err "No PHP files found in current directory."
  echo "Make sure you're in a WordPress plugin root directory."
  exit 1
fi

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Initialize Plugin: $PLUGIN_DIR_NAME${NC}"
echo -e "${BLUE}================================${NC}\n"

# Warn if CLAUDE.md already exists
if [ -f "CLAUDE.md" ]; then
  warn "CLAUDE.md already exists in this plugin."
  read -p "Overwrite it? (y/n) " -n 1 -r; echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Keeping existing CLAUDE.md."
    exit 0
  fi
fi

# ── Plugin Config ─────────────────────────────────────────────────────────────
echo -e "${BLUE}Plugin Configuration${NC}\n"

read -p "Plugin name (e.g., WebToffee Product Feed Pro): " PLUGIN_NAME
if [ -z "$PLUGIN_NAME" ]; then
  PLUGIN_NAME=$(echo "$PLUGIN_DIR_NAME" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
  echo "  Using: $PLUGIN_NAME"
fi

read -p "Plugin slug (e.g., product-feed-pro): " PLUGIN_SLUG
if [ -z "$PLUGIN_SLUG" ]; then
  PLUGIN_SLUG=$(echo "$PLUGIN_DIR_NAME" | tr '_' '-')
  echo "  Using: $PLUGIN_SLUG"
fi

read -p "Plugin prefix (e.g., WT_PRODUCT_FEED_PRO_): " PLUGIN_PREFIX
if [ -z "$PLUGIN_PREFIX" ]; then
  err "Plugin prefix is required."; exit 1
fi

read -p "Text domain [${PLUGIN_SLUG}]: " TEXT_DOMAIN
TEXT_DOMAIN="${TEXT_DOMAIN:-$PLUGIN_SLUG}"

read -p "Min PHP version [7.4]: " MIN_PHP
MIN_PHP="${MIN_PHP:-7.4}"

read -p "Min WordPress version [5.8]: " MIN_WP
MIN_WP="${MIN_WP:-5.8}"

read -p "Min WooCommerce version [7.0]: " MIN_WC
MIN_WC="${MIN_WC:-7.0}"

# ── Jira Config ───────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}Jira Configuration${NC}\n"

read -p "Jira feature project key (e.g., IS): " JIRA_FEATURE_KEY
if [ -z "$JIRA_FEATURE_KEY" ]; then
  err "Jira feature project key is required."; exit 1
fi

read -p "Jira support project key (e.g., ISCS): " JIRA_SUPPORT_KEY
if [ -z "$JIRA_SUPPORT_KEY" ]; then
  err "Jira support project key is required."; exit 1
fi

# ── Bitbucket Config ──────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}Bitbucket Configuration${NC}\n"

read -p "Bitbucket workspace URL [https://bitbucket.org/webtoffee]: " BITBUCKET_WORKSPACE
BITBUCKET_WORKSPACE="${BITBUCKET_WORKSPACE:-https://bitbucket.org/webtoffee}"

read -p "Bitbucket repo name [${PLUGIN_SLUG}]: " BITBUCKET_REPO
BITBUCKET_REPO="${BITBUCKET_REPO:-$PLUGIN_SLUG}"

read -p "PR reviewer email: " PR_REVIEWER
if [ -z "$PR_REVIEWER" ]; then
  err "PR reviewer email is required."; exit 1
fi

# ── QA Config ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BLUE}QA Configuration${NC}\n"

read -p "QA tester email (press Enter to skip): " QA_TESTER
QA_TESTER="${QA_TESTER:-N/A}"

# ── Write CLAUDE.md from template ─────────────────────────────────────────────
sed \
  -e "s|{{PLUGIN_NAME}}|${PLUGIN_NAME}|g" \
  -e "s|{{PLUGIN_SLUG}}|${PLUGIN_SLUG}|g" \
  -e "s|{{PLUGIN_PREFIX}}|${PLUGIN_PREFIX}|g" \
  -e "s|{{TEXT_DOMAIN}}|${TEXT_DOMAIN}|g" \
  -e "s|{{MIN_PHP}}|${MIN_PHP}|g" \
  -e "s|{{MIN_WP}}|${MIN_WP}|g" \
  -e "s|{{MIN_WC}}|${MIN_WC}|g" \
  -e "s|{{JIRA_FEATURE_KEY}}|${JIRA_FEATURE_KEY}|g" \
  -e "s|{{JIRA_SUPPORT_KEY}}|${JIRA_SUPPORT_KEY}|g" \
  -e "s|{{BITBUCKET_WORKSPACE}}|${BITBUCKET_WORKSPACE}|g" \
  -e "s|{{BITBUCKET_REPO}}|${BITBUCKET_REPO}|g" \
  -e "s|{{PR_REVIEWER}}|${PR_REVIEWER}|g" \
  -e "s|{{QA_TESTER}}|${QA_TESTER}|g" \
  "$TEMPLATE" > CLAUDE.md

echo ""
ok "CLAUDE.md created successfully"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo "  Plugin:        $PLUGIN_NAME"
echo "  Slug:          $PLUGIN_SLUG"
echo "  Prefix:        $PLUGIN_PREFIX"
echo "  Text domain:   $TEXT_DOMAIN"
echo "  Min PHP/WP/WC: $MIN_PHP / $MIN_WP / $MIN_WC"
echo "  Jira:          $JIRA_FEATURE_KEY (features) / $JIRA_SUPPORT_KEY (support)"
echo "  Bitbucket:     $BITBUCKET_WORKSPACE / $BITBUCKET_REPO"
echo "  PR Reviewer:   $PR_REVIEWER"
echo "  QA Tester:     $QA_TESTER"
echo ""
echo -e "${GREEN}Ready to develop! Start with:${NC}"
echo -e "  ${BLUE}/wt-feature${NC}   — new feature"
echo -e "  ${BLUE}/wt-support${NC}   — support ticket"
