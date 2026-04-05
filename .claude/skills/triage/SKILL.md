---
name: triage
description: >
  Failure classification and recovery strategy for tasks that failed during /yolo
  or /forge execution. Reads run reports, classifies failure type, and recommends
  recovery action. Adapted from AgentField's Issue Advisor pattern.
invocation: user
---

# /triage — Failure Classification & Recovery

You are in TRIAGE MODE. A task has failed — either during `/yolo` (manual execution)
or `/forge` (autonomous execution). Your job is to diagnose WHY it failed and recommend
the right recovery strategy.

## Input

`/triage` accepts:
- A run report: `/triage docs/runs/auth-oauth2-run.md`
- A forge JSON: `/triage docs/specs/auth-oauth2-forge.json`
- A task number: `/triage task 3` (finds the relevant run report)
- Nothing (finds the most recent run report with failed/skipped tasks)

## Phase 1: Gather Evidence

1. Read the run report — find failed or skipped tasks
2. Read the spec — understand what was intended
3. Read the forge JSON — check attempt counts and evaluator feedback
4. Read `.ralph-logs/` if forge was used — attempt logs, build errors, evaluator scores
5. Check git log for the feature branch — what commits exist, what was reverted
6. Run the failing test/build command to reproduce the error

## Phase 2: Classify Each Failure

For each failed task, classify into exactly ONE of these categories:

### 1. WRONG_APPROACH
**Signal:** Score not improving across attempts. Same files edited repeatedly. Agent oscillating between similar approaches.
**Example:** Agent tried to implement OAuth with cookies when the app uses JWT tokens.
**Recovery:** RETRY_APPROACH — same acceptance criteria, completely different implementation strategy.

### 2. MISSING_CONTEXT
**Signal:** Import errors, undefined references, API misuse, calling functions that don't exist.
**Example:** Agent didn't know about the existing auth middleware and built a duplicate.
**Recovery:** INJECT_CONTEXT — add the missing information to the task description, then retry.

### 3. TOO_COMPLEX
**Signal:** Partial completion, >200 LOC attempted, multiple unrelated failures, task touches too many files.
**Example:** "Implement full OAuth2 flow" is really 4 separate tasks.
**Recovery:** SPLIT — decompose into smaller sub-tasks and re-spec.

### 4. BLOCKED_BY_DEPENDENCY
**Signal:** Compilation errors referencing missing modules/exports from a prior task. Task N needs Task M's output but Task M failed or was skipped.
**Example:** Task 5 needs the database schema from Task 3, but Task 3 was skipped.
**Recovery:** ESCALATE_TO_REPLAN — the dependency graph needs restructuring. Go back to `/spec`.

### 5. SPEC_AMBIGUITY
**Signal:** Agent oscillating between approaches. Tests passing but review failing. Implementation reasonable but doesn't match intent.
**Example:** Spec says "add authentication" but doesn't specify OAuth vs API keys vs session tokens.
**Recovery:** RE_SPEC — the spec needs clarification. Go back to `/spec` for this task.

### 6. TEST_TOO_STRICT
**Signal:** High evaluator scores (7-8/10) but failing specific verification commands. Implementation looks correct.
**Example:** Test expects exact string match but implementation returns equivalent data in different format.
**Recovery:** RETRY_MODIFIED — relax the acceptance criteria slightly, document the gap as technical debt.

## Phase 3: Generate Recovery Plan

For each failed task, output:

```markdown
### Task [N]: [Title]
**Failure Classification:** [WRONG_APPROACH | MISSING_CONTEXT | TOO_COMPLEX | BLOCKED | AMBIGUOUS | STRICT]

**Evidence:**
- [Specific evidence for this classification]
- [Error messages, scores, attempt history]

**Recovery Action:** [RETRY_APPROACH | INJECT_CONTEXT | SPLIT | ESCALATE | RE_SPEC | RETRY_MODIFIED]

**Recovery Details:**
[Specific instructions for the recovery. What to change, what context to add, how to split, etc.]

**Confidence:** High | Medium | Low
[Why you're confident in this classification]
```

## Phase 4: Recommend Execution Path

After classifying all failures, recommend the overall recovery path:

| If most failures are... | Recommend |
|------------------------|-----------|
| WRONG_APPROACH or MISSING_CONTEXT | `/yolo` the failed tasks with updated context |
| TOO_COMPLEX or BLOCKED | `/spec` to re-decompose, then `/yolo` or `/forge` |
| SPEC_AMBIGUITY | `/spec` to clarify, then re-execute |
| TEST_TOO_STRICT | `/yolo` with relaxed criteria |
| Mixed | Address in priority order: BLOCKED → COMPLEX → APPROACH → CONTEXT → STRICT |

## Phase 5: Persist

1. Write the triage report to `docs/reviews/<feature>-triage.md`
2. If SPLIT was recommended, generate updated task entries
3. If INJECT_CONTEXT, write the missing context to the spec
4. Commit: `triage: <feature> — N failures classified`
5. Present recovery plan to the user for approval

## Reflexion Pattern

For each failure, generate a natural-language self-reflection (from Reflexion, NeurIPS 2023):

> "Task 3 failed because the agent assumed the API returned a list but it returns a paginated object. The error message 'TypeError: object is not iterable' confirms this. Next attempt should check the API documentation and handle pagination."

This reflection gets injected into the retry prompt, preventing the same mistake from recurring.

## IMPORTANT RULES

- **Classify before recommending.** Don't jump to "retry" without understanding why it failed.
- **One classification per task.** Pick the primary cause, not a list of maybes.
- **Evidence-based.** Every classification must cite specific evidence (error messages, scores, logs).
- **Never blame the spec for code bugs.** If the code is wrong, it's WRONG_APPROACH, not SPEC_AMBIGUITY.
- **SPLIT aggressively.** If a task has >6 files or >200 LOC, it should probably be split regardless of failure type.
