#!/bin/bash

################################################################################
# Workflow Orchestrator — Master controller for autonomous feature development
#
# Usage: bash ~/.claude/scripts/orchestrator.sh [TICKET]
# Example: bash ~/.claude/scripts/orchestrator.sh IS-456
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PLUGIN_DIR="$(pwd)"
TICKET="${1}"
STATE_FILE="Skills/feature/${TICKET}/.wt-state"

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verify we're in a WordPress plugin
if [ ! -f "*.php" ] && [ -z "$(find . -maxdepth 1 -name '*.php' -type f)" ]; then
    print_error "Not a WordPress plugin directory"
    echo "Make sure you're in a plugin root (where plugin.php is)"
    exit 1
fi

# Verify CLAUDE.md exists
if [ ! -f "CLAUDE.md" ]; then
    print_error "CLAUDE.md not found"
    echo "Run /wt-init-plugin first to initialize this plugin"
    exit 1
fi

print_header "Workflow Orchestrator — Feature: ${TICKET}"

# Load plugin config
PLUGIN_NAME=$(grep "^# Plugin:" CLAUDE.md | sed 's/^# Plugin: //')
JIRA_FEATURE=$(grep "Feature project:" CLAUDE.md | awk '{print $NF}')

print_info "Plugin: ${PLUGIN_NAME}"
print_info "Jira: ${JIRA_FEATURE}"
print_info "Ticket: ${TICKET}"

# Check state file
if [ -f "$STATE_FILE" ]; then
    print_info "Loading previous state..."
    PLANNING=$(grep '"status": "completed"' "$STATE_FILE" | grep planning | wc -l)
    IMPL=$(grep '"status": "completed"' "$STATE_FILE" | grep implementation | wc -l)
    TESTING=$(grep '"status": "completed"' "$STATE_FILE" | grep testing | wc -l)
    COMMIT=$(grep '"status": "completed"' "$STATE_FILE" | grep commit | wc -l)

    echo ""
    [ $PLANNING -gt 0 ] && print_success "Planning: COMPLETED" || echo "⏳ Planning: pending"
    [ $IMPL -gt 0 ] && print_success "Implementation: COMPLETED" || echo "⏳ Implementation: pending"
    [ $TESTING -gt 0 ] && print_success "Testing: COMPLETED" || echo "⏳ Testing: pending"
    [ $COMMIT -gt 0 ] && print_success "Commit: COMPLETED" || echo "⏳ Commit: pending"
fi

# Show menu
echo -e "\n${BLUE}What phase would you like to work on?${NC}\n"
echo "1) 📋 Planning          (read PRD → generate plan)"
echo "2) 🔨 Implementation    (build code from plan)"
echo "3) 🧪 Testing           (run tests → review → QA)"
echo "4) 📤 Commit            (commit to Bitbucket)"
echo "5) 🎉 Release           (version bump → zip → tag)"
echo "6) 📊 Show Status       (display current state)"
echo "0) ❌ Exit"
echo ""

read -p "Enter phase number (0-6): " PHASE

case $PHASE in
    1)
        print_header "Spawning Planning Agent"
        print_info "Agent: Reading PRD from any source"
        print_info "Task: Generate implementation plan"
        print_info "Output: PRD.md + plan.md"
        echo ""
        print_info "This will start a new agent session..."
        echo "The Planning Agent will:"
        echo "  1. Ask for PRD source (Confluence/Jira/External/Prompt)"
        echo "  2. Generate PRD.md with requirements"
        echo "  3. Create plan.md with implementation details"
        echo "  4. Ask for your approval"
        echo ""
        read -p "Ready to start? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Planning Agent starting..."
            # In actual implementation, spawn Agent here
        fi
        ;;
    2)
        print_header "Spawning Implementation Agent"
        print_info "Agent: Building code from plan"
        print_info "Checking: plan.md exists?"

        if [ ! -f "Skills/feature/${TICKET}/plan.md" ]; then
            print_error "plan.md not found"
            echo "Run Planning phase first (option 1)"
            exit 1
        fi

        print_success "plan.md found"
        echo ""
        print_info "The Implementation Agent will:"
        echo "  1. Read plan.md"
        echo "  2. Generate PHP code"
        echo "  3. Create/modify files"
        echo "  4. Make git commits"
        echo "  5. Return ready for testing"
        echo ""
        read -p "Ready to start? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Implementation Agent starting..."
            # In actual implementation, spawn Agent here
        fi
        ;;
    3)
        print_header "Spawning Testing Agent"
        print_info "Agent: Testing, reviewing, and QA"
        echo ""
        print_info "The Testing Agent will:"
        echo "  1. Generate unit tests"
        echo "  2. Run PHPUnit"
        echo "  3. PHPCS code review"
        echo "  4. Run QA 6-phase gate"
        echo "  5. Report pass/fail"
        echo ""
        read -p "Ready to start? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Testing Agent starting..."
            # In actual implementation, spawn Agent here
        fi
        ;;
    4)
        print_header "Spawning Commit Agent"
        print_info "Agent: Commit and create PR"

        if [ ! -f "Skills/feature/${TICKET}/.wt-state" ]; then
            print_error "Testing not complete"
            echo "Run Testing phase first (option 3)"
            exit 1
        fi

        echo ""
        print_info "The Commit Agent will:"
        echo "  1. Review git diff"
        echo "  2. Get your approval"
        echo "  3. Create feature branch"
        echo "  4. Commit with formatted message"
        echo "  5. Create PR on Bitbucket"
        echo "  6. Assign reviewers"
        echo ""
        read -p "Ready to start? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Commit Agent starting..."
            # In actual implementation, spawn Agent here
        fi
        ;;
    5)
        print_header "Spawning Release Agent"
        print_info "Agent: Release and distribution"
        echo ""
        print_info "The Release Agent will:"
        echo "  1. Check: is PR merged?"
        echo "  2. Bump version number"
        echo "  3. Create git tag"
        echo "  4. Generate release zip"
        echo "  5. Update changelog"
        echo ""
        read -p "Ready to start? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Release Agent starting..."
            # In actual implementation, spawn Agent here
        fi
        ;;
    6)
        print_header "Workflow Status"
        if [ -f "$STATE_FILE" ]; then
            cat "$STATE_FILE"
        else
            echo "No state file yet. Start with Planning phase (option 1)."
        fi
        ;;
    0)
        echo "Goodbye! 👋"
        exit 0
        ;;
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

echo ""
print_success "Ready!"
