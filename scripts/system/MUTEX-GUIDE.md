# File-Based Mutex Lock System

Resilient file locking for coordinating concurrent processes and Claude agents.

## Overview

The `file-mutex.sh` utility provides mutual exclusion (mutex) locks for filesystem resources. This prevents multiple agents from simultaneously writing to the same file, which causes corruption or lost data.

**Perfect for**: Multi-agent Phase 1 research where 4 researcher agents write to shared output files.

## Features

- ✅ **Atomic locking** — Uses `mkdir` for atomic operation
- ✅ **Timeout-based deadlock detection** — Stale locks auto-cleanup (default 1 hour)
- ✅ **Exponential backoff retry** — Reduces contention with smart waiting
- ✅ **PID/timestamp tracking** — Debug which process holds a lock
- ✅ **Graceful cleanup** — AUTO cleans up locks on script exit
- ✅ **Admin functions** — Force-release locks if needed

## Quick Start

### Basic Usage (Bash Script)

```bash
#!/bin/bash
source ~/utilities/scripts/system/file-mutex.sh

RESOURCE="phase-1-output"

# Try to acquire lock (blocking, 30s timeout)
acquire_lock "$RESOURCE" 30

# ... critical section (safe to write) ...
echo "Data" >> results.md

# Release lock
release_lock "$RESOURCE"
```

### Usage in Claude Agent Context

When Claude spawns multiple researcher agents for Phase 1:

```bash
# In each researcher agent's script:
source ~/.local/bin/file-mutex.sh  # Or wherever utilities are installed

# Acquire lock for the output file being written
acquire_lock "researcher-auto-output" 60

# Write research findings
cat >> ~/.claude-streams/phase-1/researcher-auto/findings.md << EOF
# CAN Bus Research

[findings]
EOF

# Release lock
release_lock "researcher-auto-output"
```

## API Reference

### `acquire_lock <resource> [timeout] [initial-wait]`

Acquire an exclusive lock on a resource (blocking with retry).

**Parameters:**
- `resource` (required) — Name of resource (e.g., "output-file", "phase-1-sync")
- `timeout` (optional) — Max seconds to wait before failing (default: 30)
- `initial-wait` (optional) — Initial wait before first retry (default: 0.1s)

**Returns:**
- `0` — Lock acquired
- `1` — Timeout reached, lock not acquired

**Example:**
```bash
acquire_lock "shared-output" 60  # Wait up to 60 seconds
```

### `release_lock <resource>`

Release a previously acquired lock.

**Parameters:**
- `resource` (required) — Name of resource to unlock

**Returns:**
- `0` — Lock released
- `1` — Lock not found (already released or never acquired)

**Example:**
```bash
release_lock "shared-output"
```

### `is_locked <resource>`

Check if a resource is currently locked (non-blocking).

**Parameters:**
- `resource` (required) — Name of resource

**Returns:**
- `0` — Lock is held
- `1` — Lock is not held

**Example:**
```bash
if is_locked "output"; then
  echo "Output is locked by another process"
fi
```

### `wait_for_release <resource> [timeout]`

Poll and wait for a lock to be released.

**Parameters:**
- `resource` (required) — Name of resource
- `timeout` (optional) — Max seconds to wait (default: 60)

**Returns:**
- `0` — Lock was released
- `1` — Timeout waiting for release

**Example:**
```bash
wait_for_release "output" 120  # Wait up to 2 minutes
```

### `list_locks`

Display all currently held locks (debugging).

**Output:**
```
Active locks:
  - researcher-auto-output:
        pid=12345
        acquired=2026-02-15T14:30:00Z
        resource=researcher-auto-output
        hostname=wade-machine
  - researcher-legal-output:
        pid=12346
        ...
```

### `cleanup_locks`

Remove all lock files (usually called automatically on script exit).

**Returns:**
- Number of locks cleaned up

**Example:**
```bash
cleanup_locks  # Manually trigger cleanup
```

### `force_release <resource>`

Forcefully release a lock (admin function, use carefully).

**Parameters:**
- `resource` (required) — Name of resource

**Example:**
```bash
force_release "stuck-lock"  # Use if a lock is somehow stuck
```

## Configuration

Environment variables (set before sourcing the script):

```bash
# Where to store lock files (default: .locks/)
export LOCK_DIR="~/.locks"

# Max age of a lock before auto-cleanup (default: 3600 seconds)
export LOCK_TIMEOUT=7200

# Initial wait time before first retry (default: 0.1 seconds)
export INITIAL_WAIT=0.05

# Maximum wait time between retries (default: 10 seconds)
export MAX_WAIT=5

# Backoff multiplier (default: 1.5x exponential)
export BACKOFF_MULTIPLIER=2
```

**Example:**
```bash
export LOCK_DIR="/tmp/phase-1-locks"
export LOCK_TIMEOUT=300  # 5 minute timeout
source ~/utilities/scripts/system/file-mutex.sh
```

## Practical Examples

### Example 1: Protecting Shared Output File

Multiple researchers write to the same findings file:

```bash
#!/bin/bash
source ~/utilities/scripts/system/file-mutex.sh

OUTPUT_FILE="phase-1-findings.md"
LOCK_NAME="phase-1-findings"

# Acquire exclusive write access
if ! acquire_lock "$LOCK_NAME" 30; then
  echo "ERROR: Could not acquire lock after 30 seconds"
  exit 1
fi

# Safe to write now
cat >> "$OUTPUT_FILE" << EOF
## Automotive CAN Bus Research

- Found X tools
- Y communities
- Z standards

EOF

# Release for next writer
release_lock "$LOCK_NAME"
```

### Example 2: Reader-Writer Pattern (Safe Reads)

Multiple readers can read simultaneously, but writers need exclusive access:

```bash
# Writer process
source ~/utilities/scripts/system/file-mutex.sh

# Writers acquire exclusive lock
acquire_lock "research-output" 60
# ... write new findings ...
release_lock "research-output"

# Reader process
source ~/utilities/scripts/system/file-mutex.sh

# Readers wait for exclusive lock release
wait_for_release "research-output" 120

# Safe to read (no writes happening)
cat research-output.md | grep "CAN Bus"
```

### Example 3: Multi-Step Critical Section

```bash
source ~/utilities/scripts/system/file-mutex.sh

acquire_lock "database" 60

# Multiple operations within critical section
{
  echo "Step 1: Reading current state"
  CURRENT=$(cat db.json)

  echo "Step 2: Processing"
  UPDATED=$(jq '.research += 1' <<< "$CURRENT")

  echo "Step 3: Writing"
  echo "$UPDATED" > db.json
} && release_lock "database" || {
  release_lock "database"
  exit 1
}
```

### Example 4: Phase 1 Research Agents

All 4 researchers coordinate writes:

```bash
#!/bin/bash
# researcher-auto.sh (CAN Bus Research Agent)

source ~/utilities/scripts/system/file-mutex.sh

OUTPUT_DIR="$HOME/.claude-streams/phase-1/researcher-auto"
LOCK_NAME="phase-1-researcher-outputs"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Acquire exclusive lock for writing to shared log
acquire_lock "$LOCK_NAME" 60

# Write findings to shared output file
cat >> "$OUTPUT_DIR/findings.md" << EOF
# CAN Bus Technical Research

## Specifications
- CAN 2.0A/B: [details]
- CAN FD: [details]

## Tools Found
- SavvyCAN
- BUSMASTER
- CANgaroo

EOF

release_lock "$LOCK_NAME"
```

## Debugging

### View Active Locks

```bash
source ~/utilities/scripts/system/file-mutex.sh
list_locks
```

Output shows PID, timestamp, and which resource is locked.

### Force Release a Stuck Lock

```bash
source ~/utilities/scripts/system/file-mutex.sh
force_release "stuck-resource"
```

### Custom Lock Directory

```bash
export LOCK_DIR="/var/tmp/phase-1-locks"
source ~/utilities/scripts/system/file-mutex.sh
```

## Integration with Claude Phase 1

### Recommended Setup

1. **Add to utilities repo** (already done):
   ```
   ~/utilities/scripts/system/file-mutex.sh
   ```

2. **Each researcher agent sources it**:
   ```bash
   source ~/utilities/scripts/system/file-mutex.sh
   ```

3. **Before writing outputs**:
   ```bash
   acquire_lock "phase-1-outputs" 60
   # ... write to shared files ...
   release_lock "phase-1-outputs"
   ```

4. **Cleanup automatic** — Exit trap cleans up locks

### Phase 1 Resource Names

Suggested lock names for Phase 1 research:

- `phase-1-log` — Shared execution log
- `researcher-auto-out` — CAN bus researcher output
- `researcher-legal-out` — Regulations researcher output
- `researcher-safety-out` — Safety researcher output
- `researcher-countersurv-out` — Counter-surveillance researcher output
- `phase-1-metrics` — Shared metrics/cost tracking

---

## Technical Details

### How It Works

1. **Atomic lock creation** — Uses `mkdir` which is atomic on all filesystems
2. **Lock directory structure**:
   ```
   .locks/
   └── resource-name.lock/        (lock is a directory, not a file)
       └── metadata               (contains PID, timestamp, etc.)
   ```
3. **Timeout-based cleanup** — Locks older than `LOCK_TIMEOUT` are auto-removed
4. **Exponential backoff** — Wait times increase: 0.1s → 0.15s → 0.22s → ... → 10s max
5. **Exit trap cleanup** — `trap 'cleanup_locks' EXIT` removes all locks on exit

### Why Directory-Based Locks?

- `mkdir` is atomic and works reliably across all filesystems
- File permissions don't matter (directory creation is atomic)
- Easy to include metadata (just add files inside the lock directory)
- Clear visual in filesystem when locked

### Thread Safety

This is **process-safe** (not thread-safe). It protects against:
- ✅ Multiple bash scripts/processes
- ✅ Multiple Claude agents
- ✅ Concurrent file access

It does **NOT** protect against:
- ❌ Multiple threads within same process
- ❌ Network filesystems with weak consistency (NFS, SMB)

For thread safety, use standard mutex libraries in your language (pthread, etc.).

---

## License

MIT — Part of Wade's utilities
