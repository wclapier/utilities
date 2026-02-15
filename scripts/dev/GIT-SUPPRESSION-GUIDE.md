# Git Output Suppression & Clean Error Handling

Complete guide to suppressing non-breaking git errors and maintaining clean console output across all environments.

## Overview

Git operations often produce verbose output and non-breaking error messages that clutter the console. This guide documents how Wade's environment suppresses these messages while ensuring critical errors still surface.

## Suppression Levels

### Level 1: Interactive Shell (Your Terminal)

**File**: `~/.bashrc` (sourced from `~/utilities/bash/.bashrc`)

Git commands are wrapped with `git-quiet.sh`:

```bash
# These are wrapped functions that suppress non-breaking errors:
gs              # git-quiet status
ga              # git-quiet add
gc              # git-quiet commit
gp              # git-quiet push
gpl             # git-quiet pull
gf              # git-quiet fetch
gst             # git-quiet stash
grm             # git-quiet rm
gl              # git-quiet log --oneline -10
gd              # git-quiet diff
gb              # git-quiet branch
```

**Usage**:
```bash
$ ga file.txt
✓ Changes staged

$ gp
✓ Pushed to remote

$ gs
✓ Working directory clean
```

**What happens**:
1. Wrapped function calls `git-quiet.sh <command> <args>`
2. git-quiet.sh executes git command
3. Captures output and exit code
4. Checks if message matches suppress patterns (safe, expected messages)
5. If safe: shows brief status (<100 chars)
6. If breaking error: shows full error and exits with error code

### Level 2: Git Configuration

**File**: `~/.gitconfig`

Global git config settings suppress verbose advice messages:

```ini
[advice]
    detachedHead = false
    pushUpdateRejected = false
    pushNonFFCurrent = false
    statusHints = false
    statusAhead = false

[status]
    short = true
    showUntrackedFiles = no

[fetch]
    prune = true

[push]
    default = current

[merge]
    ff = only

[rebase]
    autostash = true
    autoSquash = true
```

**Effect**: Git itself outputs less verbose advice, making console cleaner.

### Level 3: Shell Scripts & Agent Operations

**File**: `~/utilities/scripts/dev/git-quiet.sh`

When scripts or agents run git operations:

```bash
#!/bin/bash
source ~/utilities/scripts/dev/git-quiet.sh

# Do some work
echo "Research findings" >> output.md

# Use git-quiet for clean output
git-quiet add output.md
git-quiet commit -m "Add research findings"
git-quiet push origin main

# Output:
# ✓ Changes staged
# ✓ Committed
# ✓ Pushed to remote
```

### Level 4: Claude Code Auto-Commits

When I (Claude) make file changes via Bash tool:

```bash
# I automatically:
1. Make changes to files
2. Run: git-quiet add <files>
3. Run: git-quiet commit -m "meaningful message"
4. Run: git-quiet push origin main

# You see clean output showing what happened,
# not verbose git error messages
```

## Suppress Patterns

These messages are automatically suppressed (replaced with brief status):

```
✓ "nothing to commit, working tree clean"
✓ "Your branch is up to date with 'origin/main'"
✓ "Already up to date"
✓ "No changes added to commit"
✓ "Untracked files:"
✓ "Changes not staged for commit"
```

## Error Handling

**Critical errors ALWAYS surface** (not suppressed):

```
✗ "fatal: not a git repository"
✗ "fatal: Permission denied"
✗ "fatal: Could not read from remote repository"
✗ "error: Your local changes would be overwritten"
✗ "error: cannot delete branch: unmerged"
```

These show full output and exit with error code 1, requiring intervention.

## Configuration

Override suppression behavior with environment variables:

```bash
# Suppress specific patterns (space-separated regex)
export GIT_SUPPRESS_PATTERNS="nothing to commit|Your branch is up to date"

# Show warnings (non-breaking errors)
export GIT_SHOW_WARNINGS=1

# Verbose logging (for debugging)
export GIT_VERBOSE=1

# Color output (auto-detect by default)
export GIT_COLOR=auto
```

## Examples in Action

### Example 1: Staged Changes

```bash
$ ga *.md
✓ Changes staged
```

Instead of:
```
(no output - confusing is it worked?)
```

### Example 2: Already Committed

```bash
$ gc -m "Update docs"
✓ Committed
```

Instead of:
```
[main 3a7f2e] Update docs
 1 file changed, 45 insertions(+)
```

### Example 3: Nothing to Commit

```bash
$ ga .
(no output - nothing added, which is fine)
```

Instead of:
```
fatal: pathspec '.' did not match any files
```

### Example 4: Real Error

```bash
$ gp origin main
fatal: Not a git repository (or any parent up to mount point /)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).

[error] Git operation failed - check your working directory
```

This IS shown because it's a breaking error requiring action.

## Integration Points

### 1. Your Interactive Shell
- Source `~/utilities/bash/.bashrc`
- Automatically loads git-quiet wrapper functions
- Run `reload` to apply changes

### 2. Claude's Auto-Commits
- I use `git-quiet.sh` for all git operations
- You see clean status messages, not verbose output
- Critical errors still surface immediately

### 3. Shell Scripts
- Add `source ~/utilities/scripts/dev/git-quiet.sh` at top
- Use `git-quiet <command>` instead of `git <command>`
- Get automatic suppression for non-breaking errors

### 4. Pre-Commit Hooks
- Located in `.githooks/pre-commit` files
- Use `git-quiet.sh` wrapper if running git operations
- Keeps hook output clean

## Troubleshooting

### Git Command Shows Error But Continues

**This is usually fine.** Error is non-breaking:
- Nothing to commit → working directory is clean
- Already up to date → no new changes available
- Untracked files → not related to your operation

### Git Command Fails Silently

**This should not happen.** If it does:
1. Enable verbose logging: `export GIT_VERBOSE=1`
2. Run the command again to see what happened
3. Check git-quiet.sh patterns to understand suppression

### Seeing Too Much Output

**To suppress more**:
1. Add patterns to `GIT_SUPPRESS_PATTERNS` env var
2. Or update `SUPPRESS_PATTERNS` array in `git-quiet.sh`
3. Restart shell or run `reload`

### Critical Error Gets Suppressed

**This should not happen.** git-quiet.sh checks exit code first:
- If exit code ≠ 0, error is shown (never suppressed)
- Only suppresses when `git <command>` succeeds (exit 0)

If a critical error is being suppressed, report it so we can update the suppress patterns.

## Summary Table

| Scenario | Output | Suppressed? |
|----------|--------|------------|
| Changes staged successfully | ✓ Changes staged | Yes |
| Nothing to commit | (working tree clean) | Yes |
| Push to remote succeeds | ✓ Pushed to remote | Yes |
| Pull, already up to date | ✓ Repository up to date | Yes |
| Permission denied | fatal: Permission denied | No ✗ |
| Not a git repository | fatal: not a git repository | No ✗ |
| Merge conflict | error: Your local changes... | No ✗ |

## See Also

- `git-quiet.sh` — Implementation
- `GIT-ERROR-HANDLING.md` — Error categorization guide
- `~/.gitconfig` — Global configuration
- `~/utilities/bash/.bashrc` — Interactive shell config
