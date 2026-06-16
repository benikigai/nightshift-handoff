# ReviewForge -- Agent Rules

## Dependencies

### API Keys (env vars or `op run --`)

| Key | Used By | Required |
|-----|---------|----------|
| `GEMINI_API_KEY` | `review-gemini.sh` | Yes (for multi-model) |
| `OPENAI_API_KEY` | `review-gpt.sh` | Optional (GPT reviewer) |
| `DISCORD_WEBHOOK_URL` | `notify-discord.sh` | Optional (notifications) |

Keys live in environment variables or 1Password CLI (`op run --`). Never hardcode.

### SpecForge Integration

ReviewForge reads from the target project, never from its own repo:
- `docs/specs/` -- approved spec artifacts (from SpecForge)
- `docs/runs/` -- run reports (from `/yolo` or `/forge`)

These paths exist in the **target project**, not in ReviewForge itself.

### Tools

- `gh` CLI for PR creation
- `curl` for Gemini/GPT API calls and Discord webhooks

## Workflows

### /review Workflow

1. Identify feature branch and diff against base (main/master)
2. Launch blind parallel reviews:
   - Claude subagent reviews independently
   - Gemini API reviews independently (via `review-gemini.sh`)
   - GPT API reviews independently (via `review-gpt.sh`, optional)
3. Collect all findings from all models
4. Cluster similar findings (same category + overlapping files/lines)
5. Classify each cluster:
   - **Consensus** -- all models agree
   - **Majority** -- 2+ models agree
   - **Unique** -- 1 model only
   - **Disputed** -- models contradict
6. Merge clusters: highest severity wins, union evidence
7. Verification pass: attempt to disprove each finding (reduces false positives)
8. Render verdict and write to `docs/reviews/<feature>-review.md`

### /triage Workflow

1. Read run report + logs from `docs/runs/`
2. Classify each failure:
   - `WRONG_APPROACH` -- retry with different strategy
   - `MISSING_CONTEXT` -- inject missing info, retry
   - `TOO_COMPLEX` -- split into sub-tasks, re-spec
   - `BLOCKED_BY_DEPENDENCY` -- restructure dependency graph
   - `SPEC_AMBIGUITY` -- re-spec the task
   - `TEST_TOO_STRICT` -- relax criteria, retry
3. Generate recovery plan
4. Write to `docs/reviews/<feature>-triage.md`

### /pr Workflow

1. Verify branch is pushed and tests pass
2. Build PR body: summary, changes, review chain, AI disclosure
3. `gh pr create` with labels and reviewers
4. Discord notification (if webhook configured)
5. Return PR URL

## Quality Gates

### Severity Gate Rules

| Severity | Agreement | Action |
|----------|-----------|--------|
| CRITICAL | Any 1 model | **BLOCK** -- veto power, merge forbidden |
| MAJOR | 2+ models | **REQUEST CHANGES** -- must address before merge |
| MAJOR | 1 model only | **FLAG** -- human decides |
| MINOR/NIT | Any | **ADVISORY** -- does not block |

### Model Strengths

| Model | Best At |
|-------|---------|
| Claude | Logic bugs, auth flaws, race conditions, edge cases |
| Gemini | Cross-file patterns, architecture coherence (1M context) |
| GPT | Security vulnerabilities, injection, DevOps/infra |

### Verification Pass

After synthesis, each finding goes through a verification step that attempts to disprove it. This reduces false positives. A finding that survives verification is higher confidence.

## Boundaries

- ReviewForge is **read-only** on source code. It writes only to `docs/reviews/`.
- PRs are committed to **feature branches only**, never to main.
- Each reviewer model operates blind -- no model sees another model's output.
- Human is final authority. ReviewForge recommends; humans decide.

## Templates

- `docs/templates/review-template.md` -- structure for review artifacts
- `docs/templates/triage-template.md` -- structure for triage artifacts

Use these templates for all output. Do not invent new formats.

## Forge Family Context

```
/spec -> /yolo or /forge -> /review -> /pr -> merge
```

ReviewForge sits at the end of the pipeline. It receives completed work and decides whether it ships. If it rejects, `/triage` classifies the failure and feeds back into the build loop.

## Checklist (before every /review)

- [ ] Feature branch exists and is pushed
- [ ] Diff is against the correct base branch
- [ ] API keys are available for configured models
- [ ] `docs/reviews/` directory exists in target project
- [ ] Templates are present in `docs/templates/`

## Checklist (before every /pr)

- [ ] Review verdict is APPROVE
- [ ] Branch is pushed to remote
- [ ] Tests pass (if test suite exists)
- [ ] `gh` CLI is authenticated
