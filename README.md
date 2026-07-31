# Claude Plugins

A Claude Code plugin marketplace of general-purpose, organisation-agnostic plugins.

## Install

```
/plugin marketplace add https://github.com/sizeak/claude-plugins.git
/plugin install kde-notifications@sizeak-plugins
```

## Plugins

- **claude-commander** — Skills for [Claude Commander](https://github.com/sizeak/claude-commander): spin up, monitor, and tear down parallel Claude Code sessions backed by git worktrees and tmux.
- **kde-notifications** — Send KDE Plasma desktop notifications and schedule time-based reminders, branded as Claude Code. Use when you want to be pinged, alerted, or reminded out-of-band.

## Adding a plugin

1. Create a directory at the repo root (e.g. `my-plugin/`) containing `.claude-plugin/plugin.json` and a `skills/`, `agents/`, or `commands/` subdirectory.
2. Add an entry to `.claude-plugin/marketplace.json` with `name`, `source` (e.g. `./my-plugin`), and `description`.
3. Commit and push. Users refresh with `/plugin marketplace update`.

See the [Claude Code plugin docs](https://code.claude.com/docs/en/plugins) for details.
