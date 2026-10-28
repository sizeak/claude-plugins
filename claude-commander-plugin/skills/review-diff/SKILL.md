---
name: review-diff
description: Triage a Claude Commander session's review diff — list its changed files, read their diffs, and mark files reviewed (or unmark them) in the diff view. Use when the user says "mark files as read/reviewed/viewed", "mark all the import-only (or formatting-only, lockfile, generated) files as reviewed", "which files in the diff haven't I reviewed", "show me the diff for session X", "unmark that file", or otherwise asks you to work through or tidy up a session's diff view.
arguments:
  - session
---

# Triage a Session's Review Diff

Claude Commander's review view (the full-screen diff in the TUI, also in the web and mobile clients) shows a session's changed files, each with a per-file **reviewed** mark, like GitHub's "Viewed" checkbox. The `claude-commander review` commands let you read that diff and change those marks for the user. A typical job is clearing out the noise so the user only reviews what matters: "mark every file whose only change is imports as reviewed".

Marks are **pinned to the file's diff content**. If the file changes again, its mark clears itself, so a mark always means "this exact change was looked at". To keep that true, mark with `PATH@HASH` (see below), which refuses the mark if the file changed after you read it. An open TUI review view picks up your marks within a few seconds and folds away any directory they finish. The web and mobile review views show them on their next refresh.

Requires a `claude-commander` build that has the `review` subcommand. If `claude-commander review --help` errors, tell the user their install is too old.

## Picking a session

`$1` is the session whose diff the user wants triaged, when they name one. If they haven't, run `claude-commander list --json` and ask which session they mean.

Every `review` command takes `<session>` as the **exact title or full ID**. ID prefixes are not accepted, unlike `status`/`log`. If you only have a fragment, run `claude-commander list --json` first and use the full title or ID.

Files are named by **display path**: the path `review files` prints, which is the new path, or the old path for a deleted file. Copy paths from its output; don't reconstruct them.

## Commands

### review files — list the diff's files

```bash
claude-commander review files <session> [--unreviewed] [--json]
```

| Flag | Description |
|------|-------------|
| `--unreviewed` | Only files not yet marked reviewed. Usually what you want when triaging. |
| `--json` | Array of `{path, old_path, status, added, removed, binary, reviewed, hash}`. `status` is `added`/`deleted`/`modified`/`renamed`; `old_path` is set for renames only; `hash` is the file's current diff hash, for `mark PATH@HASH`. **Use this when parsing.** |

`files` and `diff` are read-only.

### review diff — read the unified diff

```bash
claude-commander review diff <session> [FILE...] [--unreviewed]
```

Prints the unified diff for the named files, or for every file when none are named. Files may be given as `PATH@HASH`, like `mark`: the command then fails if the file changed since you took the hash, so you never judge content other than what you'll mark. `--unreviewed` limits it to unmarked files. The output is exactly the content the review view shows. Renames include `rename from`/`rename to` lines. A binary file prints its `diff --git` line plus `Binary files ... differ`; a Git-LFS file shows its pointer text as a hunk. Mode-only changes and "no newline at end of file" markers are not shown, so don't mark a file whose diff looks empty. A path that isn't in the diff is an error (exit 1) naming the bad path.

### review mark / review unmark — set or clear marks

```bash
claude-commander review mark   <session> FILE... [--json]
claude-commander review mark   <session> --all   [--json]
claude-commander review unmark <session> FILE... [--json]
claude-commander review unmark <session> --all   [--json]
```

- **Idempotent.** Marking an already-reviewed file is a no-op, so re-running is safe. (The TUI's `m` key toggles; these commands never do.)
- **Pin to what you read: pass `PATH@HASH`.** Use the `hash` from `review files --json`, taken *before* you ran `review diff`. If the file changed since (the session's agent is still working), the command fails with "changed since its hash was read" and marks nothing. Re-read that file's diff and decide again. A bare `PATH` pins to whatever the file is at mark time; use it only for `unmark`, or when the user said to mark regardless of content.
- **All-or-nothing.** If any path isn't in the diff, or any hash is stale, the command fails (exit 1) and **nothing** is marked. The error lists every bad file and why (not in the diff / changed since its hash was read), so fix them all and re-run.
- `--json` returns `{"changed": [...], "unchanged": [...]}`.
- Use `--all` only when the user explicitly wants every file marked or unmarked.

## Workflow

1. **List candidates.** Run `claude-commander review files <session> --unreviewed --json`. Keep each file's `hash`. If the list is empty, say so and stop.
2. **Read before you mark.** Run `claude-commander review diff <session> <path@hash...>` for the candidates, using the hashes from step 1. Batch paths into one call where the output stays readable; for a large diff, go in chunks. Never mark a file from its name or `+/-` counts alone.
3. **Classify strictly against the user's criterion.** A file qualifies only if *every* added and removed line meets it. For "only import changes", that means each `+`/`-` line is an import/use/require/include statement (in that file's language), part of a multi-line import list, or blank. A moved import qualifies. An import change alongside *any* other edit (a renamed symbol, a new line of code, a changed string) does **not** qualify. When unsure, leave the file unmarked: a false "reviewed" hides a change from the user, while a false "unreviewed" only costs them a glance.
4. **Mark.** Run `claude-commander review mark <session> <path@hash ...>` for the qualifying files in one call. If it reports a changed file, re-read that file's diff (and re-fetch its hash), then retry.
5. **Report.** Tell the user which files you marked, which near-misses you left (and why, in a few words), and how many unreviewed files remain. `review files <session> --unreviewed` gives the remaining count.

To undo, run `claude-commander review unmark <session> <paths...>`.

## Examples

```bash
# What's left to review in the fix-auth-bug session?
claude-commander review files fix-auth-bug --unreviewed --json

# Read the diffs of three candidate files, pinned to the hashes from `review files --json`
claude-commander review diff fix-auth-bug src/api.rs@3f9c0a1b2d4e5f60 src/lib.rs@5e6f708192a3b4c5 web/src/app.ts@0a1b2c3d4e5f6071

# Mark the two that only touched imports, pinned to the hashes from `review files --json`
claude-commander review mark fix-auth-bug src/api.rs@3f9c0a1b2d4e5f60 web/src/app.ts@0a1b2c3d4e5f6071

# The user wants to look at lib.rs again after all
claude-commander review unmark fix-auth-bug src/lib.rs
```

## Guidelines

- Marks change what the user sees as needing review. Only mark what the user's criterion clearly covers, and always report what you marked.
- Don't mark files the user didn't ask about. "Mark the import-only files" is not a licence to also mark files that look trivial.
- Lockfiles, generated files and snapshots are *not* "import-only". Mark them only when the user asks for that category.
- These commands work on local sessions. For a session on a remote Commander server, run them on that server.
- Always use long-form flags (`--unreviewed`, `--json`, `--all`).
