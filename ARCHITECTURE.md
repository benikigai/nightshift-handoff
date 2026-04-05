# ReviewForge Architecture

## Purpose

Quality gate between "code exists" and "code ships." Third repo in the Forge family.

```
SpecForge (/spec, /yolo, /karpathy)  →  AgentForge (ralph-loop)  →  ReviewForge (/review, /triage, /pr)
         planning                          building                      shipping
```

## Review Pipeline

```
/review
    ├── Claude subagent (blind)     ─┐
    ├── Gemini API (blind)          ─┼── Finding Synthesis ── Verification ── Verdict
    └── GPT API (blind, optional)   ─┘
                                         │
                                    APPROVE → /pr → GitHub PR → Discord notification
                                    REJECT  → /triage → Recovery plan → Re-execute
```

## Finding Synthesis (adapted from xfire)

1. Collect all findings from all models
2. Cluster similar findings (same category + overlapping files/lines)
3. Classify: Consensus (all models) | Majority (2+) | Unique (1) | Disputed
4. Merge clusters: highest severity wins, union evidence
5. Verification pass: attempt to disprove each finding
6. Final verdict: CRITICAL from any → BLOCK, MAJOR 2+ → CHANGES, else → APPROVE

## Severity Gate Rules

| Severity | Agreement | Action |
|----------|-----------|--------|
| CRITICAL | Any 1 model | BLOCK (veto power) |
| MAJOR | 2+ models | REQUEST CHANGES |
| MAJOR | 1 model only | Flag for human |
| MINOR/NIT | Any | Advisory |

## Model Strengths

| Model | Best At |
|-------|---------|
| Claude | Logic bugs, auth flaws, race conditions, edge cases |
| Gemini | Cross-file patterns, architecture coherence (1M context) |
| GPT | Security vulnerabilities, injection, DevOps/infra |

## Triage Classification (adapted from AgentField)

| Classification | Recovery Action |
|---------------|----------------|
| WRONG_APPROACH | Retry with different strategy |
| MISSING_CONTEXT | Inject missing info, retry |
| TOO_COMPLEX | Split into sub-tasks, re-spec |
| BLOCKED_BY_DEPENDENCY | Restructure dependency graph |
| SPEC_AMBIGUITY | Re-spec the task |
| TEST_TOO_STRICT | Relax criteria, retry |
