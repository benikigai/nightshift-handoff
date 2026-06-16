# ReviewForge -- Debug State

## Current Status

- **Phase:** Initial release
- **Objective:** Provide multi-model blind review, triage, and auto-PR skills
- **Deployed:** Available as skill set (copy `.claude/` and `docs/templates/` into target project)

## Infrastructure

- **Runtime:** Claude Code CLI with skill files
- **External APIs:** Gemini (required for multi-model), GPT (optional), Discord (optional)
- **PR tooling:** `gh` CLI
- **Key management:** Environment variables or `op run --` (1Password CLI)

## Feature Flags

None currently. GPT reviewer is opt-in (only runs if `OPENAI_API_KEY` is set).

## Known Issues

None at initial release.

## Recent Anomalies

None at initial release.

## Quick Diagnostics

| Check | Command |
|-------|---------|
| Gemini key set | `echo $GEMINI_API_KEY \| head -c 8` |
| GPT key set | `echo $OPENAI_API_KEY \| head -c 8` |
| Discord configured | `echo $DISCORD_WEBHOOK_URL \| head -c 20` |
| gh authenticated | `gh auth status` |
| Reviews dir exists | `ls docs/reviews/` |
