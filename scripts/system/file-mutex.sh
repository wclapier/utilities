#!/bin/bash
# File-based Mutex Lock Manager
# Provides resilient file locking for concurrent process coordination
#
# Usage:
#   source file-mutex.sh
#   acquire_lock "resource-name" [timeout-seconds] [retry-interval]
#   # ... critical section ...
#   release_lock "resource-name"
#
# Features:
#   - Timeout-based deadlock detection
#   - Exponential backoff retry
#   - Graceful cleanup on script exit
#   - PID/timestamp tracking for debugging
#   - Auto-recovery from stale locks

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Where to store lock files
LOCK_DIR="${LOCK_DIR:-.locks}"

# Default timeout (seconds) — locks older than this are considered stale
LOCK_TIMEOUT="${LOCK_TIMEOUT:-3600}"  # 1 hour default

# Exponential backoff parameters
INITIAL_WAIT="${INITIAL_WAIT:-0.1}"  # 100ms
MAX_WAIT="${MAX_WAIT:-10}"            # 10 seconds max per attempt
BACKOFF_MULTIPLIER="${BACKOFF_MULTIPLIER:-1.5}"

# ============================================================================
# INITIALIZATION
# ============================================================================

# Ensure lock directory exists
mkdir -p "$LOCK_DIR"

# Cleanup on exit
trap 'cleanup_locks' EXIT INT TERM

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

# Get lock file path for a resource
_lock_file() {
  local resource="$1"
  echo "${LOCK_DIR}/${resource}.lock"
}

# Check if a lock exists and is valid (not stale)
_lock_exists() {
  local lock_file="$1"

  if [[ ! -f "$lock_file" ]]; then
    return 1  # Lock does not exist
  fi

  # Check if lock is stale
  local lock_age=$(( $(date +%s) - $(stat -f%m "$lock_file" 2>/dev/null || stat -c%Y "$lock_file" 2>/dev/null || echo 0) ))

  if [[ $lock_age -gt $LOCK_TIMEOUT ]]; then
    # Lock is stale, remove it
    rm -f "$lock_file"
    return 1  # Stale lock removed
  fi

  return 0  # Lock is valid and current
}

# ============================================================================
# PUBLIC API
# ============================================================================

# Acquire a lock (blocking with retry)
# Usage: acquire_lock "resource-name" [timeout-seconds] [initial-wait-ms]
acquire_lock() {
  local resource="$1"
  local timeout="${2:-30}"           # Default 30 second timeout
  local wait_time="$INITIAL_WAIT"    # Start with initial wait
  local elapsed=0
  local lock_file

  lock_file=$(_lock_file "$resource")

  echo "[mutex] Acquiring lock: $resource" >&2

  while [[ $elapsed -lt $timeout ]]; do
    # Try to create lock file atomically
    if mkdir "$lock_file" 2>/dev/null; then
      # Lock acquired! Write PID and timestamp
      {
        echo "pid=$$"
        echo "acquired=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "resource=$resource"
        echo "hostname=$(hostname)"
      } > "${lock_file}/metadata"

      echo "[mutex] ✓ Lock acquired: $resource (PID $$)" >&2
      return 0
    fi

    # Lock exists, check if stale
    if ! _lock_exists "$lock_file"; then
      # Stale lock was removed, try again immediately
      continue
    fi

    # Read lock metadata for debugging
    local lock_pid=""
    local lock_holder=""
    if [[ -f "${lock_file}/metadata" ]]; then
      lock_pid=$(grep "^pid=" "${lock_file}/metadata" | cut -d= -f2 || echo "unknown")
      lock_holder=$(grep "^resource=" "${lock_file}/metadata" | cut -d= -f2 || echo "unknown")
    fi

    # Lock held by another process, wait and retry
    echo "[mutex] ⏳ Lock held by PID $lock_pid (waited ${elapsed}s/${timeout}s, next retry in ${wait_time}s)" >&2
    sleep "$wait_time"
    elapsed=$(( elapsed + $(echo "$wait_time" | cut -d. -f1) + 1 ))

    # Exponential backoff
    wait_time=$(echo "$wait_time * $BACKOFF_MULTIPLIER" | bc -l)
    if (( $(echo "$wait_time > $MAX_WAIT" | bc -l) )); then
      wait_time="$MAX_WAIT"
    fi
  done

  # Timeout reached
  echo "[mutex] ✗ FAILED to acquire lock: $resource (timeout after ${timeout}s)" >&2
  return 1
}

# Release a lock
# Usage: release_lock "resource-name"
release_lock() {
  local resource="$1"
  local lock_file

  lock_file=$(_lock_file "$resource")

  if [[ -d "$lock_file" ]]; then
    rm -rf "$lock_file"
    echo "[mutex] ✓ Lock released: $resource" >&2
    return 0
  else
    echo "[mutex] ⚠ Lock not found: $resource (already released or never acquired)" >&2
    return 1
  fi
}

# Check if a lock is currently held
# Usage: is_locked "resource-name"
is_locked() {
  local resource="$1"
  local lock_file

  lock_file=$(_lock_file "$resource")
  _lock_exists "$lock_file"
}

# Wait for a lock to be released (polling)
# Usage: wait_for_release "resource-name" [timeout-seconds]
wait_for_release() {
  local resource="$1"
  local timeout="${2:-60}"
  local elapsed=0
  local lock_file

  lock_file=$(_lock_file "$resource")

  echo "[mutex] Waiting for lock release: $resource" >&2

  while [[ $elapsed -lt $timeout ]]; do
    if ! _lock_exists "$lock_file"; then
      echo "[mutex] ✓ Lock released: $resource" >&2
      return 0
    fi

    sleep 1
    elapsed=$((elapsed + 1))
  done

  echo "[mutex] ✗ Timeout waiting for lock release: $resource" >&2
  return 1
}

# List all active locks
# Usage: list_locks
list_locks() {
  echo "Active locks:" >&2

  if ! ls -d "$LOCK_DIR"/*.lock 2>/dev/null | head -20 > /dev/null; then
    echo "  (none)" >&2
    return 0
  fi

  for lock_dir in "$LOCK_DIR"/*.lock; do
    if [[ -d "$lock_dir" ]]; then
      local resource=$(basename "$lock_dir" .lock)
      local metadata_file="${lock_dir}/metadata"

      if [[ -f "$metadata_file" ]]; then
        echo "  - $resource:" >&2
        sed 's/^/      /' "$metadata_file" >&2
      else
        echo "  - $resource (no metadata)" >&2
      fi
    fi
  done
}

# Clean up all locks (useful for cleanup scripts)
# Usage: cleanup_locks
cleanup_locks() {
  local removed=0

  if ! ls -d "$LOCK_DIR"/*.lock 2>/dev/null > /dev/null; then
    return 0
  fi

  for lock_dir in "$LOCK_DIR"/*.lock; do
    if [[ -d "$lock_dir" ]]; then
      rm -rf "$lock_dir"
      removed=$((removed + 1))
    fi
  done

  if [[ $removed -gt 0 ]]; then
    echo "[mutex] Cleaned up $removed stale locks" >&2
  fi
}

# Force release a lock (admin function, use with caution)
# Usage: force_release "resource-name"
force_release() {
  local resource="$1"
  local lock_file

  lock_file=$(_lock_file "$resource")

  if [[ -d "$lock_file" ]]; then
    echo "[mutex] ⚠ Force releasing lock: $resource" >&2
    rm -rf "$lock_file"
    return 0
  else
    echo "[mutex] Lock not found: $resource" >&2
    return 1
  fi
}

# ============================================================================
# EXPORTED FUNCTIONS
# ============================================================================

export -f acquire_lock
export -f release_lock
export -f is_locked
export -f wait_for_release
export -f list_locks
export -f cleanup_locks
export -f force_release
