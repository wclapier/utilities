#!/usr/bin/env bash
# logging-functions.sh — Structured JSONL logging helpers
#
# Source this file to get a consistent log_jsonl() function across
# all scripts. Writes newline-delimited JSON to a log file.
#
# Usage:
#   source ~/utilities/bash/logging-functions.sh
#
#   # Basic event
#   log_jsonl "backup" "ok" '{"snapshot":"abc123"}' "$LOG_FILE"
#
#   # With auto-timestamp (recommended)
#   log_jsonl "health-check" "critical" '{"check":"disk","pct":96}' "$HEALTH_LOG"
#
# Output format:
#   {"timestamp":"2026-02-18T23:00:00Z","event":"backup","status":"ok","data":{...}}

# Guard against double-sourcing
[[ -n "${_LOGGING_FUNCTIONS_LOADED:-}" ]] && return 0
_LOGGING_FUNCTIONS_LOADED=1

# ── ISO 8601 UTC timestamp ─────────────────────────────────────────────────

ts_utc() {
    date -u +%Y-%m-%dT%H:%M:%SZ
}

ts_local() {
    date -Iseconds
}

# ── JSONL append ───────────────────────────────────────────────────────────
# log_jsonl EVENT STATUS [DATA_JSON] [LOG_FILE]
#
# EVENT     — event name, e.g. "backup", "health-check", "session-start"
# STATUS    — status string, e.g. "ok", "error", "warning"
# DATA_JSON — optional JSON object with additional fields (default: {})
# LOG_FILE  — path to append to (defaults to $LOG_FILE env var)
#
# Example:
#   log_jsonl "backup" "ok" '{"snapshot":"abc123","duration_s":42}' "$BACKUP_JSONL"

log_jsonl() {
    local event="$1"
    local status="$2"
    local data="${3:-{\}}"
    local log_file="${4:-${LOG_FILE:-/dev/stderr}}"

    # Validate data is JSON; fall back to wrapping as string if not
    if ! echo "$data" | jq -e . &>/dev/null 2>&1; then
        data=$(jq -n --arg d "$data" '{"raw": $d}')
    fi

    jq -n \
        --arg ts "$(ts_utc)" \
        --arg event "$event" \
        --arg status "$status" \
        --argjson data "$data" \
        '{timestamp: $ts, event: $event, status: $status, data: $data}' \
        >> "$log_file"
}

# ── Simple line append (no JSON, just timestamped text) ───────────────────
# log_line MESSAGE [LOG_FILE]

log_line() {
    local message="$1"
    local log_file="${2:-${LOG_FILE:-/dev/stderr}}"
    echo "[$(ts_utc)] $message" >> "$log_file"
}

# ── Tee to both stdout and file ───────────────────────────────────────────
# log_tee MESSAGE [LOG_FILE]

log_tee() {
    local message="$1"
    local log_file="${2:-${LOG_FILE:-/dev/null}}"
    echo "[$(ts_local)] $message" | tee -a "$log_file"
}
