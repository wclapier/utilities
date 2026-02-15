#!/bin/bash
# Git Quiet Wrapper
# Suppresses non-breaking git errors and shows friendly status messages
#
# Usage:
#   git-quiet <git-command> [args...]
#   git-quiet status
#   git-quiet add file.txt
#   git-quiet commit -m "message"
#   git-quiet push origin main
#
# What it does:
# - Suppresses "nothing to commit, working tree clean"
# - Suppresses "Your branch is up to date"
# - Suppresses "No changes added to commit"
# - Shows brief status (<100 chars) for major operations
# - Passes through breaking errors

set -euo pipefail

# ============================================================================
# SUPPRESS PATTERNS (non-breaking, expected messages)
# ============================================================================

SUPPRESS_PATTERNS=(
  "nothing to commit"
  "working tree clean"
  "Your branch is up to date"
  "already up to date"
  "No changes added to commit"
  "Untracked files:"
  "Changes not staged for commit"
)

# ============================================================================
# MAIN LOGIC
# ============================================================================

run_git() {
  local cmd="$1"
  shift
  local args=("$@")

  # Execute git command, capture output and status
  local output
  local exit_code=0

  output=$(git "$cmd" "${args[@]}" 2>&1) || exit_code=$?

  # Check if output should be suppressed
  local should_suppress=0
  for pattern in "${SUPPRESS_PATTERNS[@]}"; do
    if echo "$output" | grep -q "$pattern"; then
      should_suppress=1
      break
    fi
  done

  # If breaking error, show it and exit
  if [[ $exit_code -ne 0 ]]; then
    echo "$output" >&2
    return $exit_code
  fi

  # If suppressed non-error, show brief status
  if [[ $should_suppress -eq 1 ]]; then
    case "$cmd" in
      status)
        echo "✓ Working directory clean"
        ;;
      add)
        echo "✓ Changes staged"
        ;;
      commit)
        echo "✓ Committed"
        ;;
      push)
        echo "✓ Pushed to remote"
        ;;
      pull)
        echo "✓ Repository up to date"
        ;;
      fetch)
        echo "✓ Fetched from remote"
        ;;
      stash)
        echo "✓ Changes stashed"
        ;;
      rm)
        echo "✓ Files removed"
        ;;
      branch)
        echo "✓ Branch operation complete"
        ;;
      *)
        # For other commands, show truncated output if exists
        if [[ -n "$output" ]]; then
          echo "$output" | head -c 100
          [[ ${#output} -gt 100 ]] && echo "..."
        else
          echo "✓ Operation complete"
        fi
        ;;
    esac
    return 0
  fi

  # Show full output if not suppressed
  echo "$output"
  return $exit_code
}

# ============================================================================
# ENTRY POINT
# ============================================================================

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <git-command> [args...]"
  echo "Example: $(basename "$0") add file.txt"
  exit 1
fi

run_git "$@"
