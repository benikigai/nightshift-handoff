# ReviewForge — Project Rules

## Purpose

Quality gate between "code exists" and "code ships." Multi-model review, failure triage, and automated PR delivery.

## Skills

- `/review` — Multi-model code review with consensus synthesis
- `/triage` — Classify failed tasks, decide recovery strategy
- `/pr` — Create GitHub PRs with structured summaries and AI disclosure

## Review Philosophy

- **Blind parallel review.** Each model reviews independently. No cross-contamination.
- **Consensus over authority.** Multiple models agreeing > one model's opinion.
- **Severity gates merge.** CRITICAL from any model blocks. MAJOR needs 2+ agreement. MINOR is advisory.
- **Verification step.** After synthesis, a verification pass attempts to disprove each finding. This reduces false positives.
- **Human is final authority.** ReviewForge recommends. Humans decide.

## Integration

- Reads spec artifacts from SpecForge (`docs/specs/`)
- Reads run reports from `/yolo` or `/forge` (`docs/runs/`)
- Writes review artifacts to `docs/reviews/`
- Creates PRs via `gh` CLI
- Notifies via Discord webhook

## Git Discipline

- Never modify source code. ReviewForge is read-only on the codebase.
- Review artifacts are committed to `docs/reviews/`.
- PRs are created on feature branches, never on main.

## API Keys

- `GEMINI_API_KEY` — for Gemini review (review-gemini.sh)
- `OPENAI_API_KEY` — for GPT review (review-gpt.sh, optional)
- `DISCORD_WEBHOOK_URL` — for notifications (notify-discord.sh)
- All keys via environment variables or `op run --` (1Password CLI)
