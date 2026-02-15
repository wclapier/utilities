# Git Error Handling & Suppression

When working with concurrent git operations, many messages are **expected and non-breaking**. This guide categorizes errors and shows how to handle them.

## Error Categories

### ✅ Safe to Suppress (Non-Breaking)

These don't indicate problems and can be safely suppressed:

```
✓ "nothing to commit, working tree clean"
✓ "Your branch is up to date with 'origin/main'"
✓ "Already up to date"
✓ "No changes added to commit"
✓ "fatal: pathspec 'file' did not match any files"
  (when file wasn't in that commit)
```

**Strategy**: Replace with friendly status message (<100 chars)

**Examples**:
```
✓ Working directory clean
✓ Already up to date with remote
✓ No staged changes
```

### ⚠️ Important (Should Log but Not Block)

These are non-breaking but indicate a situation worth noting:

```
⚠ "Your branch is ahead of 'origin/main' by X commits"
⚠ "Merge conflict in file.md"
⚠ "Could not push some refs to origin"
  (network timeout, not auth failure)
```

**Strategy**: Log brief message, continue execution

**Examples**:
```
[warn] Local branch 2 commits ahead, not yet pushed
[warn] Merge conflict in architecture.md — manual review needed
[warn] Network issue pushing, will retry
```

### 🔴 Breaking Errors (Must Show)

These indicate real problems and should stop execution:

```
✗ "fatal: not a git repository"
✗ "fatal: Permission denied"
✗ "fatal: Could not read from remote repository"
  (auth failure, not network timeout)
✗ "error: Your local changes would be overwritten by merge"
✗ "error: cannot delete branch: unmerged"
```

**Strategy**: Display in full, stop execution, recommend action

**Examples**:
```
✗ ERROR: Not a git repository
  → Initialize repo or check REPO_ROOT env var

✗ ERROR: Permission denied for origin
  → Check SSH keys or GitHub credentials

✗ ERROR: Local changes would be overwritten
  → Commit or stash changes first
```

## Git-Quiet Wrapper

Use `git-quiet.sh` to automatically suppress safe messages:

```bash
source ~/utilities/scripts/dev/git-quiet.sh

# These will show friendly status, not verbose output
git-quiet add file.txt       # → "✓ Changes staged"
git-quiet commit -m "msg"    # → "✓ Committed"
git-quiet push origin main   # → "✓ Pushed to remote"
git-quiet status             # → "✓ Working directory clean"
```

### How It Works

1. **Capture output** from git command
2. **Check for suppress patterns** (safe, expected messages)
3. **If safe**: Show brief status (<100 chars)
4. **If breaking error**: Show full output and exit with error code
5. **If normal output**: Show full output

### Suppress Patterns (Auto-Suppressed)

```
- "nothing to commit"
- "working tree clean"
- "Your branch is up to date"
- "already up to date"
- "No changes added to commit"
- "Untracked files:"
- "Changes not staged for commit"
```

## Integration with Claude's Auto-Commit

When Claude auto-commits and pushes:

1. **Stage changes**: `git add <files>`
   - May show "Changes staged" (suppressed) or actual warnings

2. **Commit**: `git commit -m "<message>"`
   - May show "Committed" (suppressed) or actual errors

3. **Push**: `git push origin <branch>`
   - May show "Pushed" (suppressed) or important warnings

**User sees**: Brief status line, not verbose git output

**Example**:
```
[1:0:0] CAN—BUS | Extracting specs
  ↳ Reading: findings.md
  ↳ Changes staged
  ↳ Committed (abc1234)
  ↳ Pushed to remote
```

## Recommended Practices

### For Claude Agent Code

When making git operations in agent scripts:

```bash
#!/bin/bash
source ~/utilities/scripts/dev/git-quiet.sh

# Do work
echo "Research findings" >> output.md

# Stage with suppressed noise
git-quiet add output.md

# Commit with meaningful message
git-quiet commit -m "Add CAN bus research findings

Includes:
- Technical specifications
- Tool inventory
- Community resources"

# Push quietly
git-quiet push origin main
```

### For User-Facing Operations

Show status inline during execution:

```
[Phase 1] Starting research...
  ↳ CAN Bus: Acquiring lock
  ↳ Executing web searches (15 queries)
  ↳ Writing findings
  ↳ ✓ Staged changes
  ↳ ✓ Committed (3a7f2e)
  ↳ ✓ Pushed to main
  ↳ Lock released
  ↳ Research complete
```

## Context Errors (What We Saw Earlier)

The errors we encountered earlier were **context/state errors**, not git errors:

```
Error: "fatal: not a git repository (or any parent...)"
Cause: Wrong working directory
Status: IGNORABLE (transient, fixed by cd)
Fix: Change to correct repo directory
```

```
Error: "fatal: pathspec 'CLAUDE.md' did not match any files"
Cause: Wrong working directory when running git add
Status: IGNORABLE (transient, fixed by cd)
Fix: Change to correct repo directory
```

These can be suppressed at execution level by:
1. Using absolute paths
2. Checking directory before git ops
3. Showing "→ Switching directories" status message

## Configuration

Set these env vars to customize error handling:

```bash
# Suppress specific error patterns (space-separated)
export GIT_SUPPRESS_PATTERNS="nothing to commit|Your branch is up to date|No changes added"

# Show warnings (non-breaking errors) with [warn] prefix
export GIT_SHOW_WARNINGS=1

# Detailed logging (for debugging)
export GIT_VERBOSE=0

# Color output (terminal-aware)
export GIT_COLOR=auto
```

## Error Message Format

When showing errors, use this format:

```
[context] Operation in progress
  ↳ Step 1: status
  ↳ Step 2: status
  ↳ ✓ Success (or ✗ Error)
  ↳ [error details if needed]
```

**Examples**:
```
[1:0:0] CAN—BUS | Writing findings
  ↳ ✓ Staged changes
  ↳ ✓ Committed
  ↳ ✗ Push failed: Network timeout (retrying...)
  ↳ ✓ Pushed to remote (retry successful)

[USER-Q] Updating config
  ↳ ✓ Changes staged
  ↳ ✓ Committed
  ↳ ✓ Pushed to remote
```

## Summary Table

| Error Type | Show? | Message Type | Example |
|-----------|-------|--------------|---------|
| Safe (clean working dir) | No | Status | "✓ Working directory clean" |
| Safe (up to date) | No | Status | "✓ Already up to date" |
| Warning (branch ahead) | Yes | Warning | "[warn] 2 commits ahead" |
| Conflict (merge) | Yes | Warning | "[warn] Merge conflict in file" |
| Breaking (permission) | Yes | Error | "✗ ERROR: Permission denied" |
| Breaking (not a repo) | Yes | Error | "✗ ERROR: Not a git repository" |

---

**See Also**: `git-quiet.sh` for implementation

