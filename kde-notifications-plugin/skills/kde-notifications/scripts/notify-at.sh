#!/usr/bin/env bash
# Schedule a Claude Code desktop notification to fire at a future time using a
# transient systemd --user timer. The reminder survives this Claude session and
# terminal closing; it does NOT survive a reboot/logout (transient timers are
# in-memory only).
#
# Usage: notify-at.sh WHEN TITLE [BODY] [URGENCY]
#   WHEN   either a relative duration (fires that long from now), e.g.
#            10min   2h   90s   1h30m
#          or an absolute systemd OnCalendar time, e.g.
#            "15:00"            (next 3pm)
#            "tomorrow 09:00"
#            "2026-06-03 14:30"
#            "Fri 17:00"
#   TITLE/BODY  passed through to notify.sh
#   URGENCY     low | normal | critical (default: critical) — reminders default
#               to critical because a reminder you scheduled is something you've
#               asked not to miss; on Plasma critical alerts stay on screen until
#               dismissed. Pass "normal" for a low-stakes nudge.
#
# Cancel pending reminders:  systemctl --user list-timers 'claude-notify-*'
#                            systemctl --user stop <unit>
set -euo pipefail

WHEN=${1:?usage: notify-at.sh WHEN TITLE [BODY] [URGENCY]}
TITLE=${2:?usage: notify-at.sh WHEN TITLE [BODY] [URGENCY]}
BODY=${3:-}
URGENCY=${4:-critical}

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# A bare duration (digits + a single optional unit, optionally repeated like
# 1h30m) means "from now" -> --on-active. Anything else is a calendar time.
if [[ "$WHEN" =~ ^([0-9]+(s|sec|seconds?|m|min|minutes?|h|hr|hours?|d|days?|w|weeks?)?)+$ ]]; then
  TIMER=(--on-active="$WHEN")
else
  TIMER=(--on-calendar="$WHEN")
fi

UNIT="claude-notify-${RANDOM}${RANDOM}"

systemd-run --user --quiet \
  --unit="$UNIT" \
  "${TIMER[@]}" \
  --timer-property=AccuracySec=1s \
  "$SCRIPT_DIR/notify.sh" "$TITLE" "$BODY" "$URGENCY"

echo "Scheduled '$TITLE' as $UNIT (when: $WHEN)"
