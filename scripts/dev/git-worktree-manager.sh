#!/bin/bash
# Git Worktree Manager
# Enables concurrent git work from multiple processes without conflicts
#
# Each process gets its own worktree (isolated filesystem + branch)
# Perfect for: Phase execution, parallel agent work, concurrent feature development
#
# Usage:
#   git-worktree-manager create <name> [base-branch]  # Create new worktree
#   git-worktree-manager checkout <name>              # Switch to worktree
#   git-worktree-manager sync <name> [target-branch]  # Merge changes back to main
#   git-worktree-manager list                         # List all worktrees
#   git-worktree-manager cleanup <name>               # Remove worktree
#   git-worktree-manager cleanup-all                  # Remove all worktrees

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

REPO_ROOT="${REPO_ROOT:-.}"
WORKTREE_BASE="${WORKTREE_BASE:-.worktrees}"
BASE_BRANCH="${BASE_BRANCH:-main}"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
  echo "[worktree] $*" >&2
}

error() {
  echo "[worktree] ERROR: $*" >&2
  exit 1
}

ensure_git_repo() {
  if [[ ! -d "$REPO_ROOT/.git" ]]; then
    error "Not a git repository: $REPO_ROOT"
  fi
}

# ============================================================================
# WORKTREE OPERATIONS
# ============================================================================

# Create a new worktree with isolated branch
# Usage: create_worktree <name> [base-branch]
create_worktree() {
  local name="$1"
  local base_branch="${2:-$BASE_BRANCH}"
  local worktree_path="${REPO_ROOT}/${WORKTREE_BASE}/${name}"
  local feature_branch="worktree/${name}"

  log "Creating worktree: $name"

  if [[ -d "$worktree_path" ]]; then
    error "Worktree already exists: $name (at $worktree_path)"
  fi

  cd "$REPO_ROOT"

  # Create feature branch if it doesn't exist
  if ! git rev-parse --verify "$feature_branch" &>/dev/null; then
    log "Creating feature branch: $feature_branch (from $base_branch)"
    git checkout -q "$base_branch"
    git pull -q origin "$base_branch" 2>/dev/null || true
    git checkout -q -b "$feature_branch" "$base_branch"
  else
    log "Feature branch exists: $feature_branch"
  fi

  # Create worktree on the feature branch
  log "Setting up worktree directory..."
  git worktree add -q "$worktree_path" "$feature_branch"

  # Create metadata file for tracking
  cat > "${worktree_path}/.worktree-meta" << EOF
name=${name}
created=$(date -u +%Y-%m-%dT%H:%M:%SZ)
branch=${feature_branch}
base_branch=${base_branch}
pid=$$
user=\${USER:-unknown}
EOF

  log "✓ Worktree created: $name"
  log "  Path: $worktree_path"
  log "  Branch: $feature_branch"
  log "  Isolated: YES (changes don't affect other worktrees)"

  echo "$worktree_path"
}

# Checkout (switch to) a worktree
# Usage: checkout_worktree <name>
checkout_worktree() {
  local name="$1"
  local worktree_path="${REPO_ROOT}/${WORKTREE_BASE}/${name}"

  if [[ ! -d "$worktree_path" ]]; then
    error "Worktree not found: $name"
  fi

  log "Switching to worktree: $name"
  cd "$worktree_path"

  # Show branch info
  local branch=$(cd "$worktree_path" && git rev-parse --abbrev-ref HEAD)
  log "✓ Now in worktree: $name (branch: $branch)"
  log "  Working directory: $worktree_path"

  echo "$worktree_path"
}

# Sync (merge) worktree changes back to a target branch
# Usage: sync_worktree <name> [target-branch]
sync_worktree() {
  local name="$1"
  local target_branch="${2:-$BASE_BRANCH}"
  local worktree_path="${REPO_ROOT}/${WORKTREE_BASE}/${name}"

  if [[ ! -d "$worktree_path" ]]; then
    error "Worktree not found: $name"
  fi

  log "Syncing worktree: $name → $target_branch"

  cd "$REPO_ROOT"

  local feature_branch=$(cd "$worktree_path" && git rev-parse --abbrev-ref HEAD)

  # Check if there are uncommitted changes
  if ! cd "$worktree_path" && git diff-index --quiet HEAD --; then
    log "Uncommitted changes in worktree, committing first..."
    cd "$worktree_path"
    git add -A
    git commit -m "WIP: Auto-commit before sync from $name"
  fi

  cd "$REPO_ROOT"

  # Push feature branch
  log "Pushing feature branch: $feature_branch"
  git push -q origin "$feature_branch" || log "Note: Could not push branch (maybe no remote)"

  # Checkout target branch and merge
  log "Merging $feature_branch into $target_branch"
  git checkout -q "$target_branch"
  git pull -q origin "$target_branch" 2>/dev/null || true
  git merge -q --no-edit "$feature_branch"

  # Push target branch
  log "Pushing $target_branch"
  git push -q origin "$target_branch" || log "Note: Could not push (maybe no remote)"

  log "✓ Sync complete: $name → $target_branch"
}

# List all active worktrees
# Usage: list_worktrees
list_worktrees() {
  local base_path="${REPO_ROOT}/${WORKTREE_BASE}"

  log "Active worktrees:"

  if [[ ! -d "$base_path" ]]; then
    log "  (none)"
    return 0
  fi

  if ! ls -d "$base_path"/* &>/dev/null; then
    log "  (none)"
    return 0
  fi

  for worktree_dir in "$base_path"/*; do
    if [[ -d "$worktree_dir" ]]; then
      local name=$(basename "$worktree_dir")
      local meta_file="${worktree_dir}/.worktree-meta"

      if [[ -f "$meta_file" ]]; then
        echo ""
        log "  $name:"
        sed 's/^/    /' "$meta_file" >&2

        # Show branch and status
        if [[ -d "${worktree_dir}/.git" ]]; then
          local branch=$(cd "$worktree_dir" && git rev-parse --abbrev-ref HEAD)
          local status=$(cd "$worktree_dir" && git status -s | wc -l | xargs)
          log "    branch: $branch"
          log "    changes: $status"
        fi
      fi
    fi
  done
}

# Remove (clean up) a worktree
# Usage: cleanup_worktree <name> [--merge]
cleanup_worktree() {
  local name="$1"
  local merge_flag="${2:-}"
  local worktree_path="${REPO_ROOT}/${WORKTREE_BASE}/${name}"

  if [[ ! -d "$worktree_path" ]]; then
    log "Worktree not found or already removed: $name"
    return 0
  fi

  log "Cleaning up worktree: $name"

  cd "$REPO_ROOT"

  # Get branch name
  local branch=$(cd "$worktree_path" && git rev-parse --abbrev-ref HEAD)

  # Remove worktree
  git worktree remove -q "$worktree_path" || log "Warning: Could not remove worktree directory"

  # Optionally remove branch
  if [[ "$merge_flag" == "--merge" ]]; then
    log "Removing branch: $branch"
    git branch -q -D "$branch" 2>/dev/null || log "Could not delete branch (may have been deleted already)"
  fi

  log "✓ Worktree removed: $name"
}

# Remove all worktrees
# Usage: cleanup_all_worktrees [--merge]
cleanup_all_worktrees() {
  local merge_flag="${1:-}"
  local base_path="${REPO_ROOT}/${WORKTREE_BASE}"

  if [[ ! -d "$base_path" ]]; then
    log "No worktrees directory found"
    return 0
  fi

  log "Cleaning up all worktrees..."

  for worktree_dir in "$base_path"/*; do
    if [[ -d "$worktree_dir" ]]; then
      local name=$(basename "$worktree_dir")
      cleanup_worktree "$name" "$merge_flag"
    fi
  done

  # Remove base directory if empty
  rmdir "$base_path" 2>/dev/null || true

  log "✓ All worktrees cleaned up"
}

# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

main() {
  local command="${1:---help}"

  ensure_git_repo

  case "$command" in
    create)
      create_worktree "${2:?Worktree name required}" "${3:-}"
      ;;
    checkout)
      checkout_worktree "${2:?Worktree name required}"
      ;;
    sync)
      sync_worktree "${2:?Worktree name required}" "${3:-}"
      ;;
    list)
      list_worktrees
      ;;
    cleanup)
      cleanup_worktree "${2:?Worktree name required}" "${3:-}"
      ;;
    cleanup-all)
      cleanup_all_worktrees "${2:-}"
      ;;
    --help|-h|help)
      cat << EOF
Git Worktree Manager — Concurrent process coordination

USAGE:
  $(basename "$0") <command> [options]

COMMANDS:

  create <name> [base-branch]
    Create a new isolated worktree with feature branch
    Example: $(basename "$0") create phase-1-research main

  checkout <name>
    Switch to an existing worktree
    Example: $(basename "$0") checkout phase-1-research

  sync <name> [target-branch]
    Merge worktree changes back to target branch (default: main)
    Example: $(basename "$0") sync phase-1-research main

  list
    Show all active worktrees and their status
    Example: $(basename "$0") list

  cleanup <name> [--merge]
    Remove a worktree (optionally remove its branch with --merge)
    Example: $(basename "$0") cleanup phase-1-research --merge

  cleanup-all [--merge]
    Remove all worktrees
    Example: $(basename "$0") cleanup-all --merge

ENVIRONMENT:

  REPO_ROOT        Git repository root (default: current directory)
  WORKTREE_BASE    Worktree directory name (default: .worktrees)
  BASE_BRANCH      Default base branch (default: main)

FEATURES:

  ✓ Isolation — Each worktree has its own branch and working directory
  ✓ Concurrency — Multiple processes can work simultaneously
  ✓ Metadata — Tracks creation time, creator, base branch
  ✓ Syncing — Merge changes back to main with one command
  ✓ No conflicts — Changes stay isolated until explicitly merged

EXAMPLE WORKFLOW:

  # Process 1: Phase 1 Research
  git-worktree-manager create phase-1 main
  cd .worktrees/phase-1
  # ... make changes, commit ...
  git-worktree-manager sync phase-1 main

  # Process 2: Phase 2 Building (simultaneous, no conflicts)
  git-worktree-manager create phase-2 main
  cd .worktrees/phase-2
  # ... make changes, commit ...
  git-worktree-manager sync phase-2 main

EOF
      ;;
    *)
      error "Unknown command: $command (use --help for usage)"
      ;;
  esac
}

main "$@"
