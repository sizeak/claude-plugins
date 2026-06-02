#!/usr/bin/env bash
# Fire a desktop notification on KDE Plasma, branded as Claude Code so it
# groups under the "Claude Code" app in the notification history / tray.
#
# Usage: notify.sh TITLE [BODY] [URGENCY]
#   TITLE    notification summary (required)
#   BODY     notification body (optional)
#   URGENCY  low | normal | critical   (default: normal)
#            Use "normal" for task-completion pings; "critical" for failures and
#            anything the user must not miss — critical notifications stay until
#            manually dismissed on Plasma.
#
# On first run it installs the Claude Code desktop entry and icon (bundled in
# the plugin's assets/) into ~/.local/share so the branding works on any
# machine, then no-ops on subsequent runs.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

ensure_branding() {
  local apps="$DATA_HOME/applications"
  local desktop="$apps/claude-code.desktop"
  [ -f "$desktop" ] && return 0

  local icons="$DATA_HOME/icons/hicolor"
  local assets="$SCRIPT_DIR/../assets"
  mkdir -p "$apps" "$icons/scalable/apps" "$icons/256x256/apps"
  [ -f "$assets/claude-code.svg" ] && cp "$assets/claude-code.svg" "$icons/scalable/apps/claude-code.svg"
  [ -f "$assets/claude-code.png" ] && cp "$assets/claude-code.png" "$icons/256x256/apps/claude-code.png"

  cat > "$desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Claude Code
GenericName=AI Coding Agent
Comment=Notifications from Claude Code
Icon=claude-code
Exec=claude
Terminal=true
NoDisplay=true
Categories=Development;Utility;
X-GNOME-UsesNotifications=true
DESKTOP

  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$apps" 2>/dev/null || true
  command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 >/dev/null 2>&1 || true
}

TITLE=${1:?usage: notify.sh TITLE [BODY] [URGENCY]}
BODY=${2:-}
URGENCY=${3:-normal}

ensure_branding

notify-send \
  --app-name="Claude Code" \
  --icon=claude-code \
  --hint=string:desktop-entry:claude-code \
  --urgency="$URGENCY" \
  -- "$TITLE" "$BODY"
