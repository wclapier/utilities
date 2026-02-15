# Git Worktree Manager — Concurrent Process Coordination

Enable multiple processes to work on git repositories simultaneously without conflicts.

## Overview

Each process gets its **own isolated worktree** with a **separate feature branch**. Changes in one worktree don't affect others until explicitly merged.

**Perfect for**:
- ✅ Phase 1: 4 researchers working simultaneously
- ✅ Phase 2: Multiple architects designing in parallel
- ✅ Continuous orchestration while agents work
- ✅ Team collaboration without merge conflicts

## How It Works

### Traditional Git (Problems)

```
main branch (shared)
├─ Process 1 working... conflict!
└─ Process 2 working... conflict!
```

### Git Worktree Manager (Solution)

```
.git (shared metadata)
├── main branch (orchestrator)
├── worktree/phase-1 (researcher-auto)
├── worktree/phase-2 (architect-data)
└── worktree/builder (implementation)

Each process works independently.
Changes merge back to main when ready.
```

## Architecture

### Directory Structure

```
/home/wade/wade/
├── .git/                           (shared repo metadata)
├── .worktrees/                     (process worktrees)
│   ├── phase-1-research/          (isolated workspace)
│   │   ├── .worktree-meta         (metadata: branch, creator, time)
│   │   ├── master-plan.md         (local copy, can be modified)
│   │   └── ... (all files for this process)
│   ├── phase-2-architect/         (another isolated workspace)
│   │   └── ...
│   └── builder-infra/
│       └── ...
└── main/ (or mainline, orchestrator workspace)
```

### Branch Structure

```
main                           (mainline, orchestrator)
├── worktree/phase-1-research (feature branch for Phase 1)
├── worktree/phase-2-architect (feature branch for Phase 2)
└── worktree/builder-infra     (feature branch for builders)
```

## Quick Start

### Create a Worktree for Phase 1 Research

```bash
# Orchestrator creates isolated worktree for Phase 1
git-worktree-manager create phase-1-research main

# Output:
# [worktree] Creating worktree: phase-1-research
# [worktree] Creating feature branch: worktree/phase-1-research
# [worktree] ✓ Worktree created: phase-1-research
#   Path: /home/wade/wade/.worktrees/phase-1-research
#   Branch: worktree/phase-1-research
```

### Switch to the Worktree

```bash
# Researcher agent switches to its workspace
git-worktree-manager checkout phase-1-research

# Output:
# [worktree] Switching to worktree: phase-1-research
# [worktree] ✓ Now in worktree: phase-1-research
#   Working directory: /home/wade/wade/.worktrees/phase-1-research
```

### Make Changes (Independent)

```bash
# In worktree directory
cd /home/wade/wade/.worktrees/phase-1-research

# Make changes (no conflicts with other worktrees)
echo "Research findings" >> research.md

# Commit changes
git add research.md
git commit -m "Add CAN bus research findings"

# Changes are isolated to this feature branch
```

### Sync Changes Back to Main

```bash
# After research completes, merge changes back
git-worktree-manager sync phase-1-research main

# Output:
# [worktree] Syncing worktree: phase-1-research → main
# [worktree] Pushing feature branch: worktree/phase-1-research
# [worktree] Merging worktree/phase-1-research into main
# [worktree] Pushing main
# [worktree] ✓ Sync complete: phase-1-research → main
```

### Cleanup

```bash
# After syncing, remove the worktree
git-worktree-manager cleanup phase-1-research --merge

# Output:
# [worktree] Cleaning up worktree: phase-1-research
# [worktree] Removing branch: worktree/phase-1-research
# [worktree] ✓ Worktree removed: phase-1-research
```

## API Reference

### `git-worktree-manager create <name> [base-branch]`

Create a new isolated worktree with feature branch.

**Parameters:**
- `name` (required) — Worktree name (e.g., "phase-1-research", "phase-2-architect")
- `base-branch` (optional) — Base branch to create from (default: "main")

**Returns:**
- Path to new worktree

**Example:**
```bash
git-worktree-manager create phase-1-research main
# /home/wade/wade/.worktrees/phase-1-research
```

### `git-worktree-manager checkout <name>`

Switch to an existing worktree's working directory.

**Parameters:**
- `name` (required) — Worktree name

**Returns:**
- Path to worktree

**Example:**
```bash
git-worktree-manager checkout phase-1-research
```

### `git-worktree-manager sync <name> [target-branch]`

Merge worktree changes back to target branch and push.

**Parameters:**
- `name` (required) — Worktree name
- `target-branch` (optional) — Branch to merge into (default: "main")

**Returns:**
- Status of merge and push

**What it does:**
1. Commits any uncommitted changes in worktree
2. Pushes feature branch to remote
3. Checks out target branch
4. Merges feature branch into target
5. Pushes target branch to remote

**Example:**
```bash
git-worktree-manager sync phase-1-research main
```

### `git-worktree-manager list`

Show all active worktrees with status.

**Output:**
```
[worktree] Active worktrees:

  phase-1-research:
    name=phase-1-research
    created=2026-02-15T14:30:00Z
    branch=worktree/phase-1-research
    base_branch=main
    pid=12345
    user=claude
    branch: worktree/phase-1-research
    changes: 5

  phase-2-architect:
    ...
```

### `git-worktree-manager cleanup <name> [--merge]`

Remove a worktree.

**Parameters:**
- `name` (required) — Worktree name
- `--merge` (optional) — Also delete the feature branch

**Example:**
```bash
git-worktree-manager cleanup phase-1-research --merge
```

### `git-worktree-manager cleanup-all [--merge]`

Remove all worktrees.

**Example:**
```bash
git-worktree-manager cleanup-all --merge
```

## Concurrent Workflow Example

### Scenario: Phase 1 & Phase 2 Happening Simultaneously

```bash
# Orchestrator: Create worktrees for concurrent work
git-worktree-manager create phase-1-research main
git-worktree-manager create phase-2-architect main

# Process 1: Phase 1 Research (4 parallel researchers)
cd .worktrees/phase-1-research
git checkout worktree/phase-1-research

# Make changes (no interference with phase 2)
echo "## CAN Bus Findings" >> research.md
git add research.md
git commit -m "Add CAN bus research"

# Meanwhile, Process 2: Phase 2 Architecture (simultaneously)
cd .worktrees/phase-2-architect
git checkout worktree/phase-2-architect

# Make different changes (isolated from phase 1)
echo "## Database Schema" >> architecture.md
git add architecture.md
git commit -m "Design database schema"

# Both processes push independently (no conflicts)
# Orchestrator merges both when each phase completes:

git-worktree-manager sync phase-1-research main
git-worktree-manager sync phase-2-architect main

# Both feature branches merged into main successfully
# No conflicts, clean commit history, full traceability
```

## Configuration

Environment variables:

```bash
# Repository root (default: current directory)
export REPO_ROOT="/home/wade/wade"

# Base directory for worktrees (default: .worktrees)
export WORKTREE_BASE=".worktrees"

# Default base branch (default: main)
export BASE_BRANCH="main"

# Then run:
git-worktree-manager create phase-1 main
```

## Integration with Phase Execution

### Before Phase 1 Starts

```bash
# Orchestrator creates isolated worktree
git-worktree-manager create phase-1-research main

# Set environment for researchers
export PHASE_WORKTREE_PATH="/home/wade/wade/.worktrees/phase-1-research"
```

### During Phase 1

```bash
# Each researcher sources worktree in their startup
cd "$PHASE_WORKTREE_PATH"

# Make changes independently
echo "Research findings" >> findings.md
git add findings.md
git commit -m "Add findings"

# No conflicts with other researchers or orchestrator
```

### After Phase 1 Completes

```bash
# Orchestrator syncs Phase 1 changes back to main
git-worktree-manager sync phase-1-research main

# Remove worktree
git-worktree-manager cleanup phase-1-research --merge

# Ready for Phase 2 (which already has its own isolated worktree)
```

## Metadata File

Each worktree has a `.worktree-meta` file:

```
name=phase-1-research
created=2026-02-15T14:30:00Z
branch=worktree/phase-1-research
base_branch=main
pid=12345
user=claude
```

This tracks:
- When worktree was created
- Which branch it's using
- Which process created it (PID)
- Which user/agent owns it

## Conflict Resolution

### If Merge Conflict Occurs

```bash
# Conflicts only happen when merging back to main
# (worktrees are isolated until sync)

# During sync, if conflicts arise:
git-worktree-manager sync phase-1-research main
# [error] CONFLICT: ...

# Manually resolve in main branch:
cd /home/wade/wade
git status  # Shows conflicts
# ... resolve manually ...
git add .
git commit -m "Resolve merge conflicts from phase-1-research"
git push origin main
```

### Prevention Strategy

Minimize conflicts by:
1. **Using separate feature branches** — Each worktree has its own branch
2. **Syncing immediately after completion** — Don't let changes sit
3. **Clear file ownership** — Each phase modifies different files
4. **Frequent main merges** — Orchestrator merges regularly

## Troubleshooting

### Worktree is "locked"

```bash
# If a worktree is marked as locked (stale process):
git worktree list

# Force remove it:
rm -rf /home/wade/wade/.worktrees/stale-worktree
git worktree prune
```

### Can't create worktree (branch exists)

```bash
# Feature branch already exists, reuse it:
git-worktree-manager cleanup old-name

# Or force checkout:
git checkout worktree/old-name
git reset --hard origin/main  # Reset to clean state
```

### Sync fails (can't push)

```bash
# Usually due to no remote or auth issues
# Check remote:
git remote -v

# Check permissions:
git push origin worktree/phase-1-research --dry-run
```

## Best Practices

1. **One worktree per process** — Don't share worktrees
2. **Clear naming** — Use descriptive names (phase-X, builder-Y)
3. **Sync frequently** — Don't let changes accumulate
4. **Use metadata** — Check `.worktree-meta` to debug
5. **Cleanup after** — Remove worktrees when done
6. **Document ownership** — Note in commit who owns what

## Performance

**Worktree overhead**:
- Each worktree = full working directory copy (filesystem space)
- Minimal git overhead (shared .git folder)
- Negligible performance impact on operations

**Typical usage**:
- Create: ~100ms (lightweight operation)
- Checkout: ~50ms (just filesystem switch)
- Sync: ~500ms-2s (depends on merge complexity)
- Cleanup: ~50ms (just remove directory)

---

## License

MIT — Part of Wade's utilities
