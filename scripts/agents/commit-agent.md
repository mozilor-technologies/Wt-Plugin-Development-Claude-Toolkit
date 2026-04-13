# Commit Agent Specification

## Purpose
Autonomous agent for commit and PR creation phase.

Reviews changes, gets user approval, and commits to Bitbucket with proper PR workflow.

## Task
1. Load plugin CLAUDE.md (Bitbucket repo, reviewers, Jira keys)
2. Check: Did all testing gates pass? (verify .wt-state)
   - If not: BLOCK, ask to run testing phase first
3. Load feature details from Tasks/feature/{TICKET}/
   - Feature name
   - Jira ticket
   - Branch naming rules (feature/IS-{ticket}-{description})
4. Create feature branch (if not already created):
   ```bash
   git checkout -b feature/IS-{ticket}-{description}
   ```
5. Show git diff (all changes from main):
   - Ask: "Review these changes. Ready to commit? (y/n)"
   - If no: Suggest what to change, ask to re-run /wt-implement
   - If yes: Proceed
6. Create commit with formatted message:
   ```
   IS-{ticket}: {feature description}

   - Specific implementation detail 1
   - Specific implementation detail 2
   - Specific implementation detail 3

   Fixes: #{JIRA_TICKET}
   ```
7. Run /wt-commit:
   - Performs pre-commit review (PHPCS gate)
   - Creates pull request on Bitbucket
   - Assigns to PR reviewers from CLAUDE.md
   - Adds Jira ticket link
   - Sets PR reviewers
8. Return PR URL:
   - "PR #123 created"
   - "Waiting for Rovo code review"
   - "Reviewers: {reviewer1}, {reviewer2}"
9. Save state: phase="commit", status="completed", pr_url="https://..."

## Outputs
- Feature branch created
- Git commits made
- PR created on Bitbucket
- PR reviewers assigned
- Jira ticket linked

## Success Criteria
✅ Branch created from main
✅ Commit message formatted correctly
✅ PR created on Bitbucket
✅ Reviewers assigned
✅ Rovo review triggered
✅ Jira ticket linked to PR

## Failure Handling
❌ Pre-commit gate fails → Show PHPCS errors, ask to fix
❌ Branch already exists → Ask: reuse or create new
❌ PR creation fails → Check Bitbucket token, retry
❌ Reviewers not found → Ask for manual reviewer assignment

## Important Rules
- ✅ Show full diff before asking for approval
- ✅ Use Jira ticket in branch name
- ✅ Format commit message properly (Jira template)
- ✅ Assign to correct reviewers (from CLAUDE.md)
- ✅ Link to Jira ticket
- ❌ DO NOT commit without user approval
- ❌ DO NOT skip pre-commit review
- ❌ DO NOT force push

## Bitbucket Integration
- Create PR with:
  - Title: "IS-{ticket}: {feature name}"
  - Description: Feature summary + link to Jira
  - Reviewers: from CLAUDE.md (PR Reviewers field)
  - Branch: feature/IS-{ticket}-{description}
  - Target: main
- Trigger Rovo code review (via Atlassian API)

## Tools Needed
- Git (create branch, commit, push)
- Atlassian MCP (create PR, assign reviewers)
- Bitbucket API (PR operations)

## Agent Type
Use general-purpose agent with tools: git, Atlassian MCP, bash
