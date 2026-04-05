---
name: review
description: >
  Multi-model code review with blind parallel evaluation and consensus synthesis.
  Claude, Gemini, and optionally GPT independently review a feature branch, then
  findings are deduplicated, classified by agreement level, and synthesized into
  a unified verdict. Adapted from claude-consensus and xfire patterns.
invocation: user
---

# /review — Multi-Model Code Review

You are in REVIEW MODE. Your job is to orchestrate independent reviews from multiple
AI models, synthesize their findings into a consensus verdict, and present actionable
results. You do NOT modify code. You read, analyze, and report.

## Input

`/review` accepts:
- A branch name: `/review feat/auth-oauth2`
- A PR number: `/review #42`
- A spec reference: `/review docs/specs/auth-oauth2.md`
- Nothing (defaults to current branch vs main)

## Phase 1: Setup

1. Determine the review target:
   - Branch: `git diff main...<branch>`
   - PR: `gh pr diff <number>`
   - Current: `git diff main...HEAD`
2. Check the diff size. If >500 changed lines, warn the user this is a large review.
3. Check which review models are available:
   - Claude subagent: always available
   - Gemini: check if `GEMINI_API_KEY` is set and `.claude/scripts/review-gemini.sh` exists
   - GPT: check if `OPENAI_API_KEY` is set and `.claude/scripts/review-gpt.sh` exists
4. Load the spec if referenced (for context on intent and acceptance criteria)
5. Load the run report if it exists (for context on what was built and tested)

Report to user: "Reviewing with [N] models: Claude + [list]. Diff: [X] files, [Y] lines changed."

## Phase 2: Blind Parallel Review

Launch all reviews simultaneously. **No model sees another model's output.**

### Claude Review (subagent)
Spawn the `reviewer-claude` subagent with:
- The full diff
- The spec context (if available)
- Instructions to review for: correctness, edge cases, security, test coverage, simplicity

### Gemini Review (API)
If available, run:
```bash
bash .claude/scripts/review-gemini.sh <branch-or-spec-path>
```
Capture stdout. The script sends the diff to Gemini API and returns structured findings.

### GPT Review (API)
If available, run:
```bash
bash .claude/scripts/review-gpt.sh <branch-or-spec-path>
```
Same pattern as Gemini.

**Wait for all reviews to complete.** Do not proceed until all available models have returned.

## Phase 3: Finding Synthesis

This is the core of ReviewForge. Adapted from xfire's FindingSynthesizer pattern.

### Step 1: Collect All Findings

Parse each model's output into a normalized finding format:
```
- Severity: CRITICAL | MAJOR | MINOR | NIT
- Category: Bug | Security | Performance | Logic | Quality | Testing | Design
- Location: file:line
- Description: what's wrong
- Suggestion: how to fix
- Model: which model found it
```

### Step 2: Cluster Similar Findings

Two findings are "similar" if:
- Same category AND overlapping files AND overlapping line ranges
- OR same category AND overlapping files AND 2+ matching title words

Group similar findings into clusters using transitive grouping.

### Step 3: Classify by Agreement Level

For each cluster:
- **Consensus** (all models found it): Highest confidence. Use highest severity from any model.
- **Majority** (2+ models found it): High confidence. Use median severity.
- **Unique** (only 1 model found it): Medium confidence. Evaluate on merit — don't dismiss.
- **Disputed** (models disagree on severity or whether it's an issue): Flag for human review.

### Step 4: Merge and Deduplicate

For each cluster, produce one merged finding:
- Title: from the highest-severity finding in the cluster
- Severity: CRITICAL wins outright, otherwise median
- Location: union of all file:line references
- Description: combine rationales
- Suggestion: best fix from any model
- Attribution: list which models found it

### Step 5: Verification Pass

For each merged finding, attempt to disprove it:
- Is the "bug" actually intended behavior? (Check spec)
- Is the "missing validation" handled elsewhere? (Check callers)
- Is the "security issue" in a non-public code path?

Downgrade or remove findings that don't survive verification. This is what gets false positives under 1% (Anthropic Code Review pattern).

## Phase 4: Synthesize Verdict

Produce the final review:

```markdown
# Code Review: [Feature Name]
**Date:** [YYYY-MM-DD]
**Branch:** [branch name]
**Reviewers:** Claude, Gemini, GPT (N models)
**Diff:** [X files, Y lines changed]

## Verdict: APPROVE | REQUEST CHANGES | BLOCK

**BLOCK** if any CRITICAL finding survives verification.
**REQUEST CHANGES** if any MAJOR finding survives.
**APPROVE** if only MINOR/NIT findings remain.

## Critical Issues
[numbered list with file:line, description, fix, attribution]

## Major Issues
[numbered list]

## Minor Issues
[numbered list]

## Positive Observations
[what's done well — patterns, clean code, good tests]

## Missing Tests
[untested paths or edge cases]

## Finding Attribution
| Issue | Claude | Gemini | GPT | Agreement |
|-------|--------|--------|-----|-----------|
| [issue] | CRITICAL | CRITICAL | - | Consensus |
| [issue] | MAJOR | - | MAJOR | Majority |
| [issue] | - | MINOR | - | Unique |

*Reviewed by N models. Consensus findings: X. Unique findings: Y. Disputed: Z.*
```

## Phase 5: Persist and Report

1. Write the review to `docs/reviews/<feature>-review.md`
2. Commit: `review: <feature> — <VERDICT>`
3. Present the verdict to the user
4. If APPROVE: suggest running `/pr` to open a pull request
5. If REQUEST CHANGES or BLOCK: list the issues that need fixing

## Severity Gate Rules

| Severity | Source | Action |
|----------|--------|--------|
| CRITICAL | Any single model | BLOCK — veto power |
| MAJOR | 2+ models agree | REQUEST CHANGES |
| MAJOR | 1 model only | Flag for human — could be false positive |
| MINOR | Any | Advisory — does not block |
| NIT | Any | Informational only |

## Model Strengths (Routing Hints)

When synthesizing, weight findings by known model strengths:
- **Claude:** Logic bugs, auth flaws, race conditions, edge cases
- **Gemini:** Cross-file patterns, architecture coherence (large context)
- **GPT:** Security vulnerabilities, injection patterns, DevOps/infra

A security finding from GPT deserves extra weight. A logic finding from Claude deserves extra weight. This is not hard-coded — it's a synthesis heuristic.

## IMPORTANT RULES

- **NEVER modify code.** ReviewForge is read-only.
- **NEVER skip a model's findings.** Every finding gets evaluated, even unique ones.
- **NEVER manufacture consensus.** If models disagree, surface the disagreement honestly.
- **Blind reviews only.** No model sees another's output during Phase 2.
- **Verification is mandatory.** Every finding goes through the disprove step.
- **Human is final.** ReviewForge recommends; the user decides.
