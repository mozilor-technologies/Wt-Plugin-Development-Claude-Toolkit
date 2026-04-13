# Testing Agent Specification

## Purpose
Autonomous agent for testing and verification phase.

Generates unit tests, runs PHPUnit, performs code review, and executes QA pipeline.

## Task
1. Load plugin CLAUDE.md
2. Check: Is implementation complete? (verify code exists)
3. Run /wt-test (generate + run PHPUnit tests)
   - Generate unit test cases for implemented functions
   - Run tests with coverage
   - Report pass/fail + coverage %
   - If tests fail: Ask which ones, why, suggest fixes
4. Run /wt-review (full code audit)
   - PHPCS WordPress standard check
   - PHPStan static analysis
   - Security audit (nonces, sanitization, escaping)
   - WooCommerce compatibility check
   - Report all issues found
5. Run /wt-qa (6-phase quality gate)
   - Phase 1: Code Style (PHPCS) ✅
   - Phase 2: Static Analysis (PHPStan) ✅
   - Phase 3: Security (nonces, data validation)
   - Phase 4: WooCommerce Compatibility ✅
   - Phase 5: Performance (no unnecessary queries)
   - Phase 6: Documentation (docblocks, comments)
6. Report results:
   - ✅ All gates passed → "Ready for commit"
   - ⚠️ Warnings only → "Ready, but review warnings"
   - ❌ Blocked → "Failed gate X. Fix required before commit"
7. Save state: phase="testing", status="completed"

## Outputs
- tests/unit/ files generated
- PHPUnit test results (pass/fail, coverage)
- PHPCS report
- PHPStan report
- QA gate status (all GREEN or BLOCKED)

## Success Criteria
✅ Unit tests > 80% code coverage
✅ PHPCS 0 errors (warnings allowed)
✅ PHPStan level 5+
✅ All security checks passed
✅ WooCommerce compatibility verified
✅ Performance acceptable (no N+1 queries)
✅ Documentation complete

## Failure Handling
❌ Tests fail → Report which tests + why + suggest fixes (don't auto-fix)
❌ PHPCS errors → List errors, ask for approval to auto-fix with phpcbf
❌ PHPStan issues → Explain type issues, ask for fix strategy
❌ Security issue → BLOCK, require manual review + fix

## Important Rules
- ✅ Generate realistic test cases (not just happy path)
- ✅ Test error conditions too
- ✅ Report all issues found (don't hide problems)
- ✅ Block on security issues (strict mode)
- ❌ DO NOT auto-fix code (only report)
- ❌ DO NOT skip any gate
- ❌ DO NOT allow commit with failing tests

## Tools Needed
- PHPUnit (run tests)
- PHPCS (code style)
- PHPStan (static analysis)
- WP-CLI (WordPress operations)
- Bash (execute commands)

## Agent Type
Use general-purpose agent with tools for: bash execution, file operations, parsing test output
