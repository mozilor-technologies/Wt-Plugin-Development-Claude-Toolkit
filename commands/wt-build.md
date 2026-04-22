---
model: claude-sonnet-4-6
---

# /wt-build — Full feature pipeline from PRD to QA handoff

You are acting as a Senior WordPress/WooCommerce engineer running the complete feature delivery pipeline.

Run every phase in order. Do NOT skip any phase.
**Only pause at the checkpoints marked PAUSE — auto-proceed through everything else.**

---

## Phase 1: Feature — PAUSE

Invoke the **wt-feature** skill.

- Ask the user for: Confluence PRD link, Jira ticket number, short feature name
- Wait for answers, then run the full wt-feature flow
- Once `PRD.md` and `figma-notes.md` are saved → auto-proceed to Phase 2

---

## Phase 2: Plan — PAUSE

Invoke the **wt-plan** skill.

- Run the full wt-plan flow (read .context/ + parallel research sub-agents + generate plan.md)
- Show the plan to the user and ask:
  ```
  Does this plan look right? (yes / change something)
  ```
- Wait for approval. If changes requested → update and show again.
- Once approved → invoke **context-save-plan** → create the feature branch → auto-proceed to Phase 3

---

## Phase 3: Design Review — PAUSE

Invoke the **wt-design-review** skill.

- Push `plan.md` to the feature branch on Bitbucket
- Create a "PLAN REVIEW" PR (`plan/{ticket}` → `feature/{ticket}`) and assign the reviewer
- Wait: ask the user to notify the reviewer and check back when reviewed
- If reviewer adds comments → update plan.md → push → repeat
- Once the plan PR is approved and `.plan-approved` is saved → auto-proceed to Phase 4

**⚠️ Phase 4 (Implement) is blocked until this phase is complete.**

---

## Phase 4: Implement — PAUSE

Invoke the **wt-implement** skill.

- Loads .context/ + context-load-plan at start (session continuity)
- Tracks iteration count (max 5 before human check-in)
- Run the full wt-implement flow (sub-agents + code all tasks)
- Once all tasks are marked completed, ask the user:
  ```
  Please test the feature in your browser (Local Sites).
  Type "done" when you are ready to continue.
  ```
- Wait for "done" → auto-proceed to Phase 5

---

## Phase 5: Test — auto

Invoke the **wt-test** skill.

- Run the full wt-test flow (audit + generate missing tests + run suite + coverage)
- If tests fail → fix and re-run until green
- Once all tests pass and coverage ≥ 70% → auto-proceed to Phase 6

---

## Phase 6: Security Review — auto

Invoke the **wt-security** skill.

- Run the full wt-security flow (parallel sub-agents: input/output, auth, injection, dependencies)
- If blockers found → fix all, re-run until PASS
- Once security audit PASS → auto-proceed to Phase 7

---

## Phase 7: Observability Review — auto

Invoke the **wt-observability** skill.

- Run the full wt-observability flow (logging coverage + error surface audit)
- If blockers found → fix all, re-run until PASS
- Once observability audit PASS → auto-proceed to Phase 8

---

## Phase 8: Code Review — auto

Invoke the **wt-review** skill.

- Run the full wt-review flow (parallel sub-agents: PHPCS + security + WC compat + performance)
- If issues found → fix all blockers, re-run until PASS
- Once review is PASS → auto-proceed to Phase 9

---

## Phase 9: QA — auto

Invoke the **wt-qa** skill.

- Run the full wt-qa flow (parallel sub-agents: PHPCS + PHPUnit + WC compat + security + performance)
- If any phase fails → fix blockers, re-run until all phases PASS
- Once QA report shows READY TO RELEASE → auto-proceed to Phase 10

---

## Phase 10: Commit — PAUSE

Invoke the **wt-commit** skill.

- Run the full wt-commit flow
- Pause for: diff review, commit message approval, push confirmation
- Create PR on Bitbucket and transition Jira ticket to Code Review
- After PR is created → remind user to run `/wt-qa-ticket` once PR is reviewed and approved

---

## Final summary

Once complete, show:

```
🚀 /wt-build complete

Phase 1  — Feature (PRD + Figma)              : ✅ Done
Phase 2  — Plan (approved + saved to .context): ✅ Done
Phase 3  — Design Review (plan approved)      : ✅ Done
Phase 4  — Implement ([X] tasks)              : ✅ Done
Phase 5  — Tests ([X] passing, Y% coverage)   : ✅ Done
Phase 6  — Security (0 blockers)              : ✅ Done
Phase 7  — Observability (0 blockers)         : ✅ Done
Phase 8  — Code Review (0 errors)             : ✅ Done
Phase 9  — QA (all phases pass)               : ✅ Done
Phase 10 — Commit + PR                        : ✅ Done

PR: [Bitbucket PR URL]
Jira: [ticket] → Code Review

Next: When PR is reviewed and approved → run /wt-qa-ticket to hand off to QA.
```
