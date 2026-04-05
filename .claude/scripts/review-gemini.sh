#!/bin/bash
# =============================================================================
# review-gemini.sh — Blind Gemini Code Review via API
# =============================================================================
# Sends git diff to Gemini for independent review. Returns structured findings.
# Called by /review skill during Phase 2 (blind parallel review).
#
# Usage:
#   bash .claude/scripts/review-gemini.sh                    # review current branch vs main
#   bash .claude/scripts/review-gemini.sh docs/specs/auth.md # include spec context
#
# Requires: GEMINI_API_KEY environment variable
# =============================================================================

set -euo pipefail

REVIEWER_MODEL="${REVIEWER_MODEL:-gemini-2.5-flash}"
API_KEY="${GEMINI_API_KEY:-}"

if [ -z "$API_KEY" ]; then
    echo "[REVIEW SKIPPED] No GEMINI_API_KEY set."
    exit 0
fi

# --- Capture the diff ---
DIFF=$(git diff main...HEAD 2>/dev/null || git diff HEAD 2>/dev/null || echo "")

if [ -z "$DIFF" ]; then
    echo "[REVIEW SKIPPED] No changes to review."
    exit 0
fi

# Truncate large diffs
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
REVIEW_PROMPT="You are an independent code reviewer. Review this diff thoroughly.

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

Be specific. Reference file names and line numbers. Flag real issues, not style preferences.
${SPEC_CONTEXT}

DIFF:
${DIFF_TRUNCATED}"

# --- Call Gemini API ---
RESPONSE=$(curl -s --max-time 90 -X POST \
    "https://generativelanguage.googleapis.com/v1beta/models/${REVIEWER_MODEL}:generateContent?key=${API_KEY}" \
    -H 'Content-Type: application/json' \
    -d "$(python3 -c "
import json, sys
prompt = sys.stdin.read()
print(json.dumps({
    'contents': [{'parts': [{'text': prompt}]}],
    'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 4096}
}))
" <<< "$REVIEW_PROMPT")" 2>/dev/null)

# --- Parse and output ---
if [ -z "$RESPONSE" ]; then
    echo "[REVIEW ERROR] No response from Gemini API."
    exit 1
fi

python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    text = data.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].get('text', '')
    print(text if text else '[REVIEW ERROR] Empty response from Gemini')
except Exception as e:
    print(f'[REVIEW ERROR] Failed to parse response: {e}')
" <<< "$RESPONSE"
