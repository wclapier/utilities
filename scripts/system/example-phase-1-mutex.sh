#!/bin/bash
# Example: Using File Mutexes in Phase 1 Research
# Shows how multiple researcher agents coordinate writes without conflicts

set -euo pipefail

# ============================================================================
# EXAMPLE: Phase 1 Researcher Agent with Mutex Protection
# ============================================================================

# Source the mutex library
source "$(dirname "$0")/file-mutex.sh"

# Configuration
PHASE="1"
RESEARCHER="auto"  # or "legal", "safety", "countersurv"
OUTPUT_DIR="$HOME/.claude-streams/phase-${PHASE}/researcher-${RESEARCHER}"
SHARED_LOG="$OUTPUT_DIR/phase-${PHASE}.log"
LOCK_TIMEOUT="60"

# ============================================================================
# SETUP
# ============================================================================

mkdir -p "$OUTPUT_DIR"

log_message() {
  local msg="$1"
  local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $msg"
}

# ============================================================================
# RESEARCHER WORKFLOW
# ============================================================================

log_message "[${RESEARCHER}] Starting Phase 1 research..."

# --- Step 1: Initialize research findings ---

log_message "[${RESEARCHER}] Acquiring lock for output file..."
if ! acquire_lock "phase-${PHASE}-output" "$LOCK_TIMEOUT"; then
  log_message "[${RESEARCHER}] ERROR: Could not acquire lock after ${LOCK_TIMEOUT}s"
  exit 1
fi

log_message "[${RESEARCHER}] Lock acquired, writing findings..."

# Write findings (now safe from concurrent writes)
cat >> "$OUTPUT_DIR/findings.md" << EOF
# Phase 1: Research Findings ($(date -u +%Y-%m-%d))

## Domain: Automotive $([ "$RESEARCHER" == "auto" ] && echo "CAN Bus" || echo "Other")

### Key Findings
- Finding 1
- Finding 2
- Finding 3

### Resources Identified
- Resource A
- Resource B

### Next Steps
- Follow-up 1
- Follow-up 2

---
EOF

log_message "[${RESEARCHER}] Finished writing findings"
release_lock "phase-${PHASE}-output"
log_message "[${RESEARCHER}] Lock released"

# --- Step 2: Acquire lock for metric updates ---

log_message "[${RESEARCHER}] Acquiring lock for metrics..."
if ! acquire_lock "phase-${PHASE}-metrics" "$LOCK_TIMEOUT"; then
  log_message "[${RESEARCHER}] WARNING: Could not acquire metrics lock, skipping metrics update"
else
  log_message "[${RESEARCHER}] Updating metrics..."

  # Update shared metrics file
  cat >> "$OUTPUT_DIR/metrics.json" << EOF
{
  "researcher": "$RESEARCHER",
  "phase": "$PHASE",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "tokens_used": 150000,
  "cost": 3.50,
  "duration_seconds": 300,
  "queries_executed": 50,
  "findings_count": 15
}
EOF

  release_lock "phase-${PHASE}-metrics"
  log_message "[${RESEARCHER}] Metrics updated"
fi

# --- Step 3: Wait for other researchers if needed ---

if [ "$RESEARCHER" == "auto" ]; then
  log_message "[${RESEARCHER}] Waiting for other researchers to complete..."

  # Optionally wait for other lock holders
  for other_researcher in legal safety countersurv; do
    if wait_for_release "phase-${PHASE}-researcher-${other_researcher}" 300; then
      log_message "[${RESEARCHER}] Researcher '$other_researcher' finished"
    fi
  done
fi

log_message "[${RESEARCHER}] Phase 1 research complete!"

# ============================================================================
# CLEANUP (automatic via trap, but can also be explicit)
# ============================================================================

cleanup_locks
log_message "[${RESEARCHER}] All locks cleaned up"

exit 0
