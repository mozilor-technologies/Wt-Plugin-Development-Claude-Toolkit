# Implementation Agent Specification

## Purpose
Autonomous agent for feature implementation phase.

Builds PHP code, hooks, filters, and database schema based on approved implementation plan.

## Task
1. Load plugin CLAUDE.md (config, prefix, text domain)
2. Load plan.md from Skills/feature/{TICKET}/
3. Ask for approval to proceed (verify plan is still correct)
4. For each task in plan.md:
   - Ask clarifying questions if needed
   - Generate PHP code following WordPress/WooCommerce standards:
     - Use plugin prefix for all functions, classes, constants
     - Add proper nonces for form submissions
     - Sanitize inputs, escape outputs
     - Use hooks and filters (don't modify core)
     - Add docblocks with @param, @return
     - Follow PHPCS WordPress standard
   - Create/modify files in plugin root
   - Commit each file (git add + commit per logical chunk)
5. After all tasks:
   - Run `git status` to show what was created/modified
   - Return: "Implementation complete. Ready for testing."
6. Save state: phase="implementation", status="completed"

## Outputs
- Modified/created PHP files in plugin directory
- Committed changes to git
- Clear summary of what was built

## Success Criteria
✅ Code follows PHPCS WordPress standard
✅ All functions use plugin prefix
✅ Proper security (nonces, sanitization, escaping)
✅ Uses hooks/filters (no core modifications)
✅ Git commits made for each logical section
✅ Code ready for unit testing

## Failure Handling
❌ Unclear requirement → Ask for clarification before coding
❌ Plan conflicts with existing code → Merge strategies discussed
❌ Missing dependency → Document and ask how to proceed

## Important Rules
- ✅ USE PLAN MODE when suggesting architecture
- ✅ Ask before creating major functions/classes
- ✅ Make git commits per logical change (not one giant commit)
- ✅ Add docblocks to all functions
- ✅ Follow WordPress coding standards strictly
- ❌ DO NOT skip error handling
- ❌ DO NOT use global $wpdb directly without prepare()
- ❌ DO NOT create functions without checking if they exist

## Tools Needed
- File system (create/edit PHP files)
- Git (commit changes)
- PHPCS (for verification)

## Agent Type
Use general-purpose agent with EnterPlanMode for major decisions
