#!/bin/bash
# =============================================================================
# review-gpt.sh — Blind GPT Code Review via OpenAI API
# =============================================================================
# Optional reviewer. Sends git diff to GPT for independent review.
# GPT is particularly strong at security/injection findings.
#
# Usage:
#   bash .claude/scripts/review-gpt.sh                    # review current branch vs main
#   bash .claude/scripts/review-gpt.sh docs/specs/auth.md # include spec context
#
# Requires: OPENAI_API_KEY environment variable
# =============================================================================

set -euo pipefail

GPT_MODEL="${GPT_MODEL:-gpt-4o}"
API_KEY="${OPENAI_API_KEY:-}"

if [ -z "$API_KEY" ]; then
    echo "[REVIEW SKIPPED] No OPENAI_API_KEY set."
    exit 0
fi

# --- Capture the diff ---
DIFF=$(git diff main...HEAD 2>/dev/null || git diff HEAD 2>/dev/null || echo "")

if [ -z "$DIFF" ]; then
    echo "[REVIEW SKIPPED] No changes to review."
    exit 0
fi

DIFF_TRUNCATED=$(echo "$DIFF" | head -c 50000)
if [ ${#DIFF} -gt 50000 ]; then
    DIFF_TRUNCATED="${DIFF_TRUNCATED}

... [TRUNCATED — diff exceeds 50KB]"
fi

# --- Optional spec context ---
SPEC_FILE="${1:-}"
SPEC_CONTEXT=""
if [ -n "$SPEC_FILE" ] && [ -f "$SPEC_FILE" ]; then
    SPEC_CONTEXT="

SPEC (the approved plan this code implements):
$(head -c 5000 "$SPEC_FILE")"
fi

# --- Build prompt ---
SYSTEM_PROMPT="You are a security-focused code reviewer. You are especially strong at finding injection vulnerabilities, authentication gaps, secrets in code, and OWASP Top 10 issues. Also review for correctness and logic errors."

USER_PROMPT="Review this diff thoroughly.

For each issue found, provide:
1. **Severity**: CRITICAL / MAJOR / MINOR / NIT
2. **Category**: Bug, Security, Performance, Logic, Quality, Testing
3. **Location**: File path and line number(s)
4. **Description**: What the issue is and why it matters
5. **Suggestion**: How to fix it

Also provide:
- **Overall verdict**: PASS or FAIL
- **Positive observations**: What's done well
- **Missing tests**: Untested paths or edge cases
${SPEC_CONTEXT}

DIFF:
${DIFF_TRUNCATED}"

# --- Call OpenAI API ---
RESPONSE=$(curl -s --max-time 90 -X POST \
    "https://api.openai.com/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${API_KEY}" \
    -d "$(python3 -c "
import json, sys
system = sys.argv[1]
user = sys.stdin.read()
print(json.dumps({
    'model': '$GPT_MODEL',
    'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user}
    ],
    'temperature': 0.2,
    'max_tokens': 4096
}))
" "$SYSTEM_PROMPT" <<< "$USER_PROMPT")" 2>/dev/null)

# --- Parse and output ---
if [ -z "$RESPONSE" ]; then
    echo "[REVIEW ERROR] No response from OpenAI API."
    exit 1
fi

python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    text = data.get('choices', [{}])[0].get('message', {}).get('content', '')
    print(text if text else '[REVIEW ERROR] Empty response from GPT')
except Exception as e:
    print(f'[REVIEW ERROR] Failed to parse response: {e}')
" <<< "$RESPONSE"
