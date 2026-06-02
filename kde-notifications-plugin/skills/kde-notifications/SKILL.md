---
name: kde-notifications
description: >-
  Send the user a KDE Plasma desktop notification, branded as Claude Code. Use
  this whenever the user asks to be told, pinged, alerted, or notified about
  something — e.g. "let me know when this finishes", "ping me when the build is
  done", "notify me when you're done", "give me a heads up", or "send me a
  notification". Also use it for time-based reminders like "remind me in 10
  minutes", "remind me at 3pm", or "tomorrow morning tell me to X" — these
  schedule a notification for later. Reach for this skill even when the user
  doesn't say the word "notification" but clearly wants an out-of-band desktop
  alert rather than just a chat reply, and proactively after finishing a
  long-running task the user asked to be alerted about. KDE Plasma only.
---

# Desktop notifications (KDE Plasma)

This skill fires desktop notifications on the user's KDE Plasma session via
`notify-send`. Notifications are branded as **Claude Code** (Claude logo, grouped
under the "Claude Code" app in Plasma's notification history) through a registered
desktop entry, so they persist in the tray until dismissed rather than vanishing.

On first use, `notify.sh` installs the Claude Code desktop entry and icon (bundled
in this skill's `assets/`) into `~/.local/share`; subsequent runs no-op. No manual
setup is required.

There are two scripts. Prefer them over hand-writing `notify-send` flags — they
apply the branding hints consistently.

## Notify now

For "tell me when you're done" / "ping me" — fire it the moment the work finishes:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/kde-notifications/scripts/notify.sh" "TITLE" "BODY" [URGENCY]
```

- `TITLE` — short summary (required).
- `BODY` — optional detail line.
- `URGENCY` — `low` | `normal` | `critical` (default `normal`). `normal` suits
  routine task-completion pings ("build's done"). Use `critical` for **failures**
  ("deploy failed", "tests red") and anything the user must not miss — Plasma
  keeps critical notifications on screen until manually dismissed and ignores any
  expire time.

Example — a routine completion ping (normal) and a failure (critical):

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/kde-notifications/scripts/notify.sh" "Tests passed ✅" "All 412 unit tests green on branch refactor-user-service"
"${CLAUDE_PLUGIN_ROOT}/skills/kde-notifications/scripts/notify.sh" "Deploy failed ❌" "staging deploy exited 1 — see the run logs" critical
```

## Notify later (scheduled reminders)

For "remind me in 10 minutes" / "remind me at 3pm" — schedule a transient
`systemd --user` timer that fires the notification later. It survives the Claude
session ending and the terminal closing (but not a reboot/logout — transient
timers live in memory only).

Reminders default to **`critical`** urgency — a reminder the user scheduled is
something they asked not to miss, so it stays on screen until dismissed. Pass a
trailing `normal` for a low-stakes nudge.

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/kde-notifications/scripts/notify-at.sh" "WHEN" "TITLE" "BODY" [URGENCY]
```

`WHEN` accepts two forms, auto-detected:

- **Relative duration** (fires that long from now): `10min`, `2h`, `90s`, `1h30m`
- **Absolute time** (systemd `OnCalendar` syntax): `"15:00"`, `"tomorrow 09:00"`,
  `"2026-06-03 14:30"`, `"Fri 17:00"`

Examples:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/kde-notifications/scripts/notify-at.sh" 10min "Stretch break" "Step away from the screen"
"${CLAUDE_PLUGIN_ROOT}/skills/kde-notifications/scripts/notify-at.sh" "15:00" "Standup prep" "Review the PR before the 3:15 call" critical
```

When the user gives a vague time ("this afternoon", "in a bit"), pick a sensible
concrete value, then tell them exactly when it's set for so they can correct it.
Today's date is available in your context — use it to resolve "tomorrow" etc.
into the right `OnCalendar` string if the auto-detection would be ambiguous.

### Managing scheduled reminders

```bash
systemctl --user list-timers 'claude-notify-*'   # see pending reminders
systemctl --user stop <unit>                      # cancel one (unit name from notify-at.sh output)
```

## In-session nudges vs. durable reminders

- A future wall-clock reminder the user must get regardless of Claude → use
  `notify-at.sh` (above). This is the default for real reminders.
- A nudge only meaningful while this session is alive (e.g. poll something, then
  ping) → you may instead use your own scheduling (ScheduleWakeup / a loop) and
  call `notify.sh` when you wake. Don't use `notify-at.sh` for that.

## How the branding works (for debugging / advanced use)

The scripts pass three things to `notify-send` that make Plasma treat the
notification as coming from the Claude Code "app":

- `--app-name="Claude Code"` — display name on the notification.
- `--icon=claude-code` — a named icon. The source files ship with this skill at
  `assets/claude-code.{svg,png}`; `notify.sh` copies them on first run into
  `~/.local/share/icons/hicolor/{scalable,256x256}/apps/claude-code.{svg,png}`,
  which is where Plasma resolves the `claude-code` name from.
- `--hint=string:desktop-entry:claude-code` — points at
  `~/.local/share/applications/claude-code.desktop`. This is the key hint: it's
  what makes Plasma group the notification under "Claude Code", apply its icon in
  history, and honour its notification settings.

If notifications stop showing the logo or grouping correctly, delete
`~/.local/share/applications/claude-code.desktop` and run `notify.sh` again to
reprovision, then rerun `kbuildsycoca6`. The raw command, if you ever need flags
the scripts don't expose (actions, replace-id, etc.):

```bash
notify-send --app-name="Claude Code" --icon=claude-code \
  --hint=string:desktop-entry:claude-code "TITLE" "BODY"
```

See `notify-send --help` for the full flag list (`-A`/`--action` for clickable
buttons, `-r`/`--replace-id` with `-p` to update an existing notification,
`-t`/`--expire-time` in ms, `-c`/`--category`).
