#!/bin/bash
# =============================================================================
# notify-discord.sh — Send ReviewForge notifications to Discord
# =============================================================================
# Usage:
#   bash .claude/scripts/notify-discord.sh \
#       --title "PR Ready: auth-oauth2" \
#       --url "https://github.com/org/repo/pull/42" \
#       --score "APPROVE" \
#       --status "approved"
#
# Requires: DISCORD_WEBHOOK_URL environment variable
# =============================================================================

set -euo pipefail

WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"

if [ -z "$WEBHOOK_URL" ]; then
    echo "[NOTIFY SKIPPED] No DISCORD_WEBHOOK_URL set."
    exit 0
fi

# --- Parse arguments ---
TITLE=""
URL=""
SCORE=""
STATUS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --title)  TITLE="$2"; shift 2 ;;
        --url)    URL="$2"; shift 2 ;;
        --score)  SCORE="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# --- Color by status ---
case "$STATUS" in
    approved|pass)   COLOR=65280 ;;   # Green
    changes|fail)    COLOR=16776960 ;; # Yellow
    blocked|error)   COLOR=16711680 ;; # Red
    *)               COLOR=8421504 ;;  # Gray
esac

# --- Send webhook ---
curl -s -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
print(json.dumps({
    'embeds': [{
        'title': '$TITLE',
        'url': '$URL',
        'description': 'Verdict: **$SCORE**',
        'color': $COLOR,
        'footer': {'text': 'ReviewForge'},
        'timestamp': '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
    }]
}))
")" \
    "$WEBHOOK_URL" > /dev/null 2>&1

echo "[NOTIFY] Discord notification sent: $TITLE"
