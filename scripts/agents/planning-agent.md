# Planning Agent Specification

## Purpose
Autonomous agent for feature planning phase.

Reads PRD from any source (Confluence, Jira, external document, or user prompt) and generates implementation plan.

## Task
1. Load plugin CLAUDE.md from current directory
2. Ask user for PRD source:
   - a) Confluence link
   - b) Jira ticket (FEATURE project)
   - c) External document link
   - d) Describe the feature (user prompt)
3. If Confluence/Jira/external: Fetch and read the document
4. Ask clarifying questions about requirements
5. Create folder: Skills/feature/{JIRA_TICKET}-{feature-name}/
6. Write PRD.md with requirements
7. Generate comprehensive implementation plan
8. Write plan.md with:
   - Architecture changes
   - Files to create/modify
   - Database schema (if needed)
   - Hooks/filters to implement
   - Security considerations
   - WooCommerce compatibility notes
9. Ask for plan approval
10. Save state: phase="planning", status="completed"

## Outputs
- Skills/feature/{TICKET}/PRD.md
- Skills/feature/{TICKET}/plan.md
- Skills/feature/{TICKET}/.wt-state (planning: completed)

## Success Criteria
✅ PRD clearly documents requirements
✅ Plan includes specific files to modify
✅ Plan specifies WordPress/WooCommerce hooks
✅ User has approved the plan
✅ Files ready for implementation

## Failure Handling
❌ PRD source unavailable → Ask for manual description
❌ User rejects plan → Offer to revise specific sections
❌ Unclear requirements → Ask follow-up questions

## Tools Needed
- Atlassian MCP (Jira, Confluence)
- File system access (create Skills/feature/{TICKET}/)
- User interaction (approval)

## Agent Type
Use general-purpose agent with tools: Read, WebFetch, grep, bash for git/file operations
