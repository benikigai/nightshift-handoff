# Nightshift Handoff (formerly ReviewForge)

The review stage of Nightshift: multi-model code review, failure triage, and
automated PRs, packaged as Claude Code skills.

> **Status: Reference.** One commit (April 2026); unchanged since. Still invoked by
> the Nightshift supervisor's review step. Proposed: fold into the Nightshift
> supervisor repo and archive this one.

## How it fits

| Stage | Repo | Skills |
| --- | --- | --- |
| Plan | `nightshift-brief` (formerly SpecForge) | `/spec`, `/yolo`, `/forge`, `/karpathy` |
| Build | `nightshift` (formerly AgentForge) | `ralph-loop.sh` |
| **Review** | **`nightshift-handoff`** | `/review`, `/triage`, `/pr` |
| Supervise | Nightshift supervisor (private) | queue, guardrails, GitHub App |

```txt
/spec -> /yolo or /forge -> /review -> /pr -> merge
```

The supervisor calls `/review`, `/triage`, and `/pr` from this repo after each
build and routes on the verdict (APPROVE, REQUEST_CHANGES, BLOCK).

## What it does

- **`/review`**: Claude, Gemini, and (optionally) GPT review a feature branch
  blind and in parallel. Findings are clustered, deduplicated, classified by
  agreement (consensus, majority, unique, disputed), and passed through a
  verification step that tries to disprove false positives. Output is written to
  `docs/reviews/`.
- **`/triage`**: classifies failed tasks (wrong approach, missing context, too
  complex, blocked, spec ambiguity, test too strict) and writes a recovery plan.
- **`/pr`**: after approval, opens a GitHub PR with summary, review chain, test
  results, spec references, and AI disclosure; optionally notifies Discord.

### Severity gates

| Severity | Agreement needed | Action |
| --- | --- | --- |
| CRITICAL | any 1 model | BLOCK |
| MAJOR | 2+ models | REQUEST CHANGES |
| MAJOR | 1 model | flag for a human |
| MINOR / NIT | any | advisory |

## Layout

```txt
.claude/
  skills/review/SKILL.md     multi-model blind review + consensus
  skills/triage/SKILL.md     failure classification + recovery
  skills/pr/SKILL.md         PR creation
  agents/reviewer-claude.md  Claude review subagent
  scripts/review-gemini.sh   Gemini API review
  scripts/review-gpt.sh      GPT API review (optional)
  scripts/notify-discord.sh  Discord webhook notification
  settings.json
docs/templates/              review and triage templates
docs/reviews/                review output (empty in repo)
ARCHITECTURE.md              design notes
CLAUDE.md                    always-on rules
```

## Use

```sh
cp -r nightshift-handoff/.claude your-project/
cp -r nightshift-handoff/docs/templates your-project/docs/
cd your-project && claude
> /review feat/my-feature
> /pr
```

## Config and secrets

Set in your shell or secret manager, never in the repo:

- `GEMINI_API_KEY` (Gemini reviewer)
- `OPENAI_API_KEY` (optional GPT reviewer)
- `DISCORD_WEBHOOK_URL` (optional notifications)
- `gh` must be authenticated for `/pr`.

## Maintenance notes

- Internal links still use the old SpecForge / AgentForge / ReviewForge names;
  GitHub redirects them, but update to the `nightshift-*` names.
- Default reviewer models are from April 2026; review before reuse.

## License

MIT
