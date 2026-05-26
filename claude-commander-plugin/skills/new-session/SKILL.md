---
name: new-session
description: Spin up a new Claude Commander session. Use when the user says "spin up a session", "hand this off", "create a new session", "start a new session", "delegate this", or asks you to work on something in a separate session.
arguments:
  - instructions
---

# New Claude Commander Session

Spin up a new Claude Commander session using the `claude-commander new` CLI command. Each session gets its own git worktree, branch, and tmux session.

## Syntax

```bash
claude-commander new <session-name> [options]
```

## Options

| Flag | Description |
|------|-------------|
| `--initial-prompt <text>` / `-i <text>` | Initial prompt/context for the new session. The session starts working on this immediately. |
| `--path <dir>` / `-d <dir>` | Project path. Defaults to current directory. Automatically discovers the git root (works from worktrees, subdirectories, and symlinks). |
| `--base-branch <branch>` / `-b <branch>` | Branch to fork from. If this matches an existing session's branch, the new session is automatically stacked on it. |
| `--mode <mode>` / `-m <mode>` | Permission mode for the Claude session (e.g. `auto`, `plan`, `default`). |
| `--effort <level>` / `-e <level>` | Claude effort level (e.g. `high`, `medium`, `low`). |

## Output

The command produces verbose logging. On success, report only a single line confirming the session was created and its name. Do not include the full command output, session ID, or attach instructions.

Example response: `Spun up session **fix-auth-bug** in plan mode.`

## Instructions

`$1` is the user's request describing what the new session should do. Use it to determine the session name, initial prompt, mode, effort, and base branch.

## Examples

```bash
# Create a session that starts working immediately
claude-commander new "fix-auth-bug" \
  --initial-prompt "There is an auth bypass in src/login.rs where the session token is not validated. Fix it and add a regression test."

# Create a session in plan mode with high effort
claude-commander new "design-api" \
  --initial-prompt "Design the new REST API for user management." \
  --mode plan --effort high

# Fork from a specific branch (stacks automatically if branch belongs to a session)
claude-commander new "feature-follow-up" \
  --base-branch feature-auth

# Minimal — just create a session with no initial prompt
claude-commander new "exploratory-work"
```

## Guidelines

- Write clear, self-contained prompts. The new session has no shared context with yours — include file paths, the problem description, and what the expected outcome is.
- When using `--mode plan`, include an explicit instruction in the prompt such as "You MUST use plan mode. Do not make any edits until the plan is approved." The `--mode` flag sets the Claude CLI permission mode, but the agent may still attempt edits unless the prompt reinforces the constraint.
- Keep session names short and descriptive (they become branch names).
- Always use long-form flags (`--initial-prompt`, `--mode`, `--effort`), never short flags, to avoid ambiguity.
- **Never spin up a new session unless the user explicitly asks you to.** Do not proactively create sessions, even if you think it would be helpful. Wait for a clear instruction like "spin up a session for this", "hand this off", or "create a new session".
- When you do create a session, always tell the user what you're doing and why.
