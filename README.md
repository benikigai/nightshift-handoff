# ReviewForge

Quality gate between "code exists" and "code ships." Multi-model review, failure triage, automated PRs.

Third repo in the Forge family: [SpecForge](https://github.com/benikigai/SpecForge) plans. [AgentForge](https://github.com/benikigai/AgentForge) builds. ReviewForge ships.

---

## The Problem

AI-generated code gets reviewed by the same model that wrote it. That's like grading your own homework. Different models catch different bugs — Claude finds logic errors GPT misses, GPT finds injection risks Claude misses, Gemini spots cross-file patterns both miss.

## The Fix

ReviewForge runs blind parallel reviews across multiple AI models, synthesizes findings through consensus, and creates PRs when code passes.

**`/review`** — Claude, Gemini, and GPT independently review your feature branch. Nobody sees anyone else's output. Findings are clustered, deduplicated, and classified by agreement level. A verification pass disproves false positives. Result: APPROVE, REQUEST CHANGES, or BLOCK.

**`/triage`** — When tasks fail during `/yolo` or `/forge`, triage classifies WHY (wrong approach? missing context? too complex? blocked?) and recommends the right recovery strategy.

**`/pr`** — After review approves, creates a GitHub PR with structured summary, AI disclosure, review scores, test results, and spec references. Sends Discord notification.

## Quick Start

```bash
# 1. Copy into your project
cp -r ReviewForge/.claude your-project/
cp -r ReviewForge/docs/templates your-project/docs/

# 2. Set API keys (for multi-model review)
export GEMINI_API_KEY="..."          # Gemini review
export OPENAI_API_KEY="..."          # GPT review (optional)
export DISCORD_WEBHOOK_URL="..."     # Notifications (optional)

# 3. After building a feature with /yolo or /forge:
cd your-project && claude

> /review feat/my-feature
> /pr
```

## How It Works

### /review Flow

```
Feature branch ready
    → Claude subagent reviews blind
    → Gemini API reviews blind (parallel)
    → GPT API reviews blind (parallel, optional)
    → Cluster similar findings
    → Classify: Consensus / Majority / Unique / Disputed
    → Verification pass (disprove false positives)
    → Verdict: APPROVE / REQUEST CHANGES / BLOCK
    → Write to docs/reviews/
```

### /triage Flow

```
Failed tasks from /yolo or /forge
    → Read run report + logs
    → Classify each failure:
        WRONG_APPROACH → retry with different strategy
        MISSING_CONTEXT → inject info and retry
        TOO_COMPLEX → split into sub-tasks
        BLOCKED → restructure dependencies
        SPEC_AMBIGUITY → re-spec
        TEST_TOO_STRICT → relax criteria
    → Generate recovery plan
    → Write to docs/reviews/<feature>-triage.md
```

### /pr Flow

```
Approved review
    → Verify branch pushed, tests pass
    → Build PR body (summary, changes, review chain, AI disclosure)
    → gh pr create with labels and reviewers
    → Discord notification
    → Return PR URL
```

## Severity Gates

| Severity | Agreement Needed | Action |
|----------|-----------------|--------|
| CRITICAL | Any 1 model | BLOCK — veto power |
| MAJOR | 2+ models agree | REQUEST CHANGES |
| MAJOR | 1 model only | Flag for human decision |
| MINOR/NIT | Any | Advisory — doesn't block |

## What's Inside

```
.claude/
├── skills/
│   ├── review/SKILL.md          # Multi-model blind review + consensus
│   ├── triage/SKILL.md          # Failure classification + recovery
│   └── pr/SKILL.md              # Auto-PR creation
├── agents/
│   └── reviewer-claude.md       # Claude review subagent
├── scripts/
│   ├── review-gemini.sh         # Gemini API review
│   ├── review-gpt.sh            # GPT API review (optional)
│   └── notify-discord.sh        # Discord webhook
└── settings.json
docs/
├── reviews/                     # Review artifacts
└── templates/
    ├── review-template.md
    └── triage-template.md
```

## The Forge Family

| Repo | Role | Skills |
|------|------|--------|
| [SpecForge](https://github.com/benikigai/SpecForge) | Planning brain | `/spec`, `/yolo`, `/forge`, `/karpathy` |
| [AgentForge](https://github.com/benikigai/AgentForge) | Autonomous builder | `ralph-loop.sh` |
| **ReviewForge** | Quality gate + delivery | `/review`, `/triage`, `/pr` |

```
/spec → /yolo or /forge → /review → /pr → merge
```

## License

MIT
