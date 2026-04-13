---
description: Master pipeline orchestrator for feature development. Invoked when user says "build IS-{n}", "start IS-{n}", or "implement IS-{n}". Runs complexity assessment first, then executes only the agents needed.
model: claude-sonnet-4-6
---

# Skill: wt-orchestrator

You are the master pipeline controller for feature development. You coordinate agents, enforce gates, manage state, and run only what's needed based on complexity.

## Trigger phrases
- "build IS-{n}"
- "start IS-{n}"
- "implement IS-{n}"
- "start feature IS-{n}"

## Step 0: Verify repo root

```bash
git rev-parse --show-toplevel && pwd
```

Both lines must match. If not → stop:
```
⚠️  You are not at the repository root.
Please run: cd $(git rev-parse --show-toplevel)
Then try again.
```

## Step 0B: Parse ticket + load state

Extract ticket from user message (e.g. `IS-534`).

State file: `Tasks/feature/{ticket}-*/.orchestrator-state.json`

If state file exists → read `current_phase` and `completed_phases`.

Show current status and ask:
```
🎯 {ticket} — Phase: {current_phase}
   Completed: {completed_phases}

Resume from '{current_phase}'? (yes / restart)
```

If no state → start fresh from `assess`.

Jump to the appropriate step based on `current_phase`.

---

## Step 1: Assess complexity

> Skip if `assess` in completed_phases.

Invoke agent: **task-assessor**
```
Input: ticket = {ticket}
```

Show result:
```
📊 Complexity: {Simple|Medium|Complex} (score: {N}/6)
   Pipeline:   {recipe_label}
   Agents:     {list}

Proceed? (yes / override-complexity / cancel)
```

- **yes** → use the recipe
- **override-complexity** → ask: Simple / Medium / Complex → update recipe
- **cancel** → stop

Save to state: `current_phase = "research"`, `complexity`, `pipeline`, `feature_name`

---

## Step 2: Research

> Skip if `research` in completed_phases.

Show: `🔍 Research — launching agents in parallel...`

Launch agents from `pipeline.research_agents` **simultaneously in background**:

- If `prd-fetcher` in list → invoke **prd-fetcher** agent (background)
  - Input: `ticket`, `feature_folder = Tasks/feature/{ticket}-{feature_name}`
- If `design-reader` in list → ask user: "Is there a Figma link? (paste or skip)"
  - If provided → invoke **design-reader** agent (background)
- If `code-explorer` in list → invoke **code-explorer** agent (background)
  - Input: `ticket`, `feature_summary`

Wait for all to complete.

Update state: add `research` to completed_phases, `current_phase = "branch-setup"`

Show:
```
✅ Research complete
   PRD saved:      Tasks/feature/{ticket}-{feature_name}/PRD.md
   Figma notes:    saved / skipped
   Codebase scan:  {N} relevant files found
```

---

## Step 2B: Branch setup

> Skip if `branch-setup` in completed_phases.

Ask:
```
Which release version is this targeting? (e.g. 1.2.5)
```

```bash
git fetch origin
git branch -r | grep "origin/release/{version}"
```

If release branch exists:
```bash
git checkout release/{version} 2>/dev/null || git checkout -b release/{version} origin/release/{version}
git pull origin release/{version}
```

If not:
```bash
git checkout master && git pull origin master
git checkout -b release/{version}
git push -u origin release/{version}
```

Create feature branch:
```bash
git checkout -b feature/{ticket}-{feature_name}
```

Save `.release-version` file: `Tasks/feature/{ticket}-{feature_name}/.release-version`

Update state: add `branch-setup`, `current_phase = "plan"`, save `release_version`

---

## Step 3: Plan generation

> Skip if `plan` in completed_phases. Skip entirely if `pipeline.plan_agent = false`.

Show: `📋 Plan — invoking feature-planner (Opus)...`

Invoke agent: **feature-planner**
```
Input:
  ticket = {ticket}
  feature_folder = Tasks/feature/{ticket}-{feature_name}
  code_explorer_output = {output from code-explorer}
  complexity = {complexity}
```

Show plan summary returned by agent, then:
```
📋 Plan saved: Tasks/feature/{ticket}-{feature_name}/plan.md

Review the plan: cat "Tasks/feature/{ticket}-{feature_name}/plan.md"

Approve? (yes / revise / cancel)
```

- **yes** → proceed
- **revise** → ask what to change, re-invoke feature-planner with feedback
- **cancel** → stop

Update state: add `plan`, `current_phase = "plan-pr"`

---

## Step 4: Plan PR

> Skip if `plan-pr` in completed_phases. Skip if `pipeline.plan_pr = false`.

Show: `🔀 Plan PR — creating review PR on Bitbucket...`

Invoke agent: **pr-manager**
```
Input: mode = create-plan-pr, ticket, feature_name
```

Save `pr_id` and `pr_url` to state.
Update state: add `plan-pr`, `current_phase = "pr-approval"`

Show:
```
✅ Plan PR created: {pr_url}
   Reviewer notified.

⏳ Monitoring for approval in the background.
   You can close Claude — I will resume when the plan is approved.

   Or stay and I will check every 5 minutes.
```

Set up background approval polling (CronCreate, every 5 min):
```
Check plan PR approval for {ticket}:
Invoke pr-manager agent with mode=poll-approval, pr_id={pr_id}, ticket={ticket}, feature_name={feature_name}
If approved=true → invoke pr-manager with mode=merge-plan-pr → write .plan-approved → update state to implement → invoke code-builder agent in background
```

**STOP** — wait for approval.

---

## Step 4B: Resume after approval (current_phase = pr-approval)

When user returns or cron detects approval:

Invoke **pr-manager**: `mode = poll-approval, pr_id = {pr_id}`

If not yet approved → show: `⏳ Still waiting for approval. PR: {pr_url}`

If approved:
- Invoke **pr-manager**: `mode = merge-plan-pr`
- Write `Tasks/feature/{ticket}-{feature_name}/.plan-approved`
- Transition Jira to In Progress (transition id: 21)
- Update state: add `pr-approval`, `current_phase = "implement"`
- Proceed to Step 5

---

## Step 5: Implementation

> Skip if `implement` in completed_phases.

Show: `⚙️  Implementing — code-builder running in background...`

Invoke agent: **code-builder** (background)
```
Input: ticket, feature_folder, phpcs_path = vendor/bin/phpcs
```

Wait for `.implement-done` marker file to appear.

Update state: add `implement`, `current_phase = "verify"`

---

## Step 6: Verification

> Skip if `verify` in completed_phases.

Show: `🧪 Verification — launching qa-runner + security-auditor in parallel...`

Launch simultaneously in background:
- Invoke **qa-runner** agent
- If `pipeline.security_agent = true` → invoke **security-auditor** agent

Wait for `.verify-done` and `.security-done` (if applicable) to appear.

Read results from marker files.

Show combined QA summary:
```
🧪 QA Gate Results:
   PHPCS [detected standard]: ✅ / ❌
   Security audit:     ✅ / ❌
   Unit tests:         ✅ {N} passed
   Observability:      ✅ / ❌
   Acceptance criteria:✅ / ❌
```

If any FAIL → show issues, ask: `Fix these issues? (yes / skip / cancel)`
- **yes** → invoke code-builder to fix, re-run verification
- **skip** → proceed with warning
- **cancel** → stop

Update state: add `verify`, `current_phase = "ready-to-commit"`

---

## Step 7: Commit

> Skip if `commit` in completed_phases.

Show: `🚀 Ready to commit.`

Ask:
```
1. Commit type: feat | fix | refactor | test | docs | chore | style | perf
2. Short summary (imperative mood, max 60 chars)
3. Any extra context for the body? (optional)
```

Build commit message:
```
{ticket}: {type}: {summary}

- {bullet points from implementation}

Jira: {ticket}
Reviewed-by: Claude (PHPCS ✅ Tests ✅ Security ✅ Rovo ✅)
```

Show message → ask: `Commit with this message? (yes / edit / cancel)`

On yes:
```bash
git add {changed_files}
git commit -m "..."
```

Invoke **pr-manager**: `mode = create-code-pr, release_version = {version}`

Transition Jira to Code Review (transition id: 31).

Update state: add `commit`, `current_phase = "done"`

---

## Final summary

```
╔══════════════════════════════════════════════════════╗
║  PIPELINE COMPLETE — {ticket}                        ║
╠══════════════════════════════════════════════════════╣
║  Complexity:  {Simple|Medium|Complex}                ║
║  ✅ Research  ✅ Plan  ✅ Design Review               ║
║  ✅ Implement ✅ Tests ✅ Security ✅ QA               ║
║  ✅ PR: {pr_url}                                     ║
║  ✅ {ticket} → Code Review                           ║
╚══════════════════════════════════════════════════════╝

Next: wait for PR review → run /wt-fix-review if needed
      after merge → say "QA ticket for {ticket}"
```
