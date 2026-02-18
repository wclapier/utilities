#!/usr/bin/env bash
# notify.sh — Unified ntfy.sh notification wrapper
#
# Usage:
#   notify.sh --title "Title" --message "Body" [--priority LEVEL] [--tags TAG1,TAG2] [--topic TOPIC]
#   notify.sh --preset backup-success "Snapshot abc123 created"
#   notify.sh --preset backup-failure "Connection timeout to B2"
#   notify.sh --preset health-warning "Disk usage at 90%"
#   notify.sh --dry-run --preset backup-success "Test message"
#
# Presets:
#   backup-success   priority=default  tags=white_check_mark,backup
#   backup-failure   priority=urgent   tags=rotating_light,backup
#   backup-warning   priority=high     tags=warning,backup
#   health-ok        priority=low      tags=white_check_mark,health
#   health-warning   priority=high     tags=warning,health
#   health-critical  priority=urgent   tags=rotating_light,health
#   metrics-report   priority=low      tags=chart_with_upwards_trend,metrics
#
# Can also be sourced to provide notify_send() function

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────

# Topic and URL come from environment variables or defaults.
# Set NTFY_TOPIC and NTFY_URL before sourcing/calling this script.
# Example: export NTFY_TOPIC="my-project-alerts"
NTFY_TOPIC="${NTFY_TOPIC:-notifications}"
NTFY_URL="${NTFY_URL:-https://ntfy.sh}"

# ── Preset Definitions ─────────────────────────────────────────────────────

declare -A PRESET_PRIORITY=(
    [backup-success]="default"
    [backup-failure]="urgent"
    [backup-warning]="high"
    [health-ok]="low"
    [health-warning]="high"
    [health-critical]="urgent"
    [metrics-report]="low"
)

declare -A PRESET_TAGS=(
    [backup-success]="white_check_mark,backup"
    [backup-failure]="rotating_light,backup"
    [backup-warning]="warning,backup"
    [health-ok]="white_check_mark,health"
    [health-warning]="warning,health"
    [health-critical]="rotating_light,health"
    [metrics-report]="chart_with_upwards_trend,metrics"
)

declare -A PRESET_TITLE=(
    [backup-success]="Backup Success"
    [backup-failure]="Backup FAILED"
    [backup-warning]="Backup Warning"
    [health-ok]="Health Check OK"
    [health-warning]="Health Check Warning"
    [health-critical]="Health Check CRITICAL"
    [metrics-report]="Metrics Report"
)

# ── Functions ──────────────────────────────────────────────────────────────

usage() {
    cat << 'EOF'
notify.sh — Unified ntfy.sh notification wrapper

Usage:
  notify.sh --title "Title" --message "Body" [OPTIONS]
  notify.sh --preset PRESET "Message body" [OPTIONS]

Options:
  --title TEXT         Notification title
  --message TEXT       Notification body
  --priority LEVEL     Priority: urgent, high, default, low, min (default: default)
  --tags TAGS          Comma-separated tags (e.g., warning,backup)
  --topic TOPIC        Override default topic (default: life-backups)
  --preset PRESET      Use preset config (see below)
  --dry-run            Print notification without sending
  -h, --help           Show this help

Presets:
  backup-success       Priority: default, Tags: white_check_mark,backup
  backup-failure       Priority: urgent, Tags: rotating_light,backup
  backup-warning       Priority: high, Tags: warning,backup
  health-ok            Priority: low, Tags: white_check_mark,health
  health-warning       Priority: high, Tags: warning,health
  health-critical      Priority: urgent, Tags: rotating_light,health
  metrics-report       Priority: low, Tags: chart_with_upwards_trend,metrics

Examples:
  notify.sh --preset backup-success "Snapshot abc123 created"
  notify.sh --title "Alert" --message "Disk full" --priority high
  notify.sh --dry-run --preset health-warning "Disk usage at 90%"

Can also be sourced to provide notify_send() function:
  source notify.sh
  notify_send "Title" "Message" "priority" "tags"
EOF
}

# Function for sending notifications (can be called when script is sourced)
notify_send() {
    local title="$1"
    local message="$2"
    local priority="${3:-default}"
    local tags="${4:-}"
    local topic="${5:-$NTFY_TOPIC}"
    local dry_run="${6:-false}"

    if [[ "$dry_run" == "true" ]]; then
        echo "[DRY RUN] Notification:"
        echo "  Topic:    $topic"
        echo "  Title:    $title"
        echo "  Message:  $message"
        echo "  Priority: $priority"
        echo "  Tags:     $tags"
        return 0
    fi

    # Send via curl, suppress all output, never fail
    curl -sS --max-time 10 \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -H "Tags: $tags" \
        -d "$message" \
        "$NTFY_URL/$topic" &>/dev/null || true
}

# ── Main (when executed directly) ──────────────────────────────────────────

# Only run main if script is executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse arguments
    TITLE=""
    MESSAGE=""
    PRIORITY="default"
    TAGS=""
    TOPIC="$NTFY_TOPIC"
    PRESET=""
    DRY_RUN=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --title)
                TITLE="$2"
                shift 2
                ;;
            --message)
                MESSAGE="$2"
                shift 2
                ;;
            --priority)
                PRIORITY="$2"
                shift 2
                ;;
            --tags)
                TAGS="$2"
                shift 2
                ;;
            --topic)
                TOPIC="$2"
                shift 2
                ;;
            --preset)
                PRESET="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                usage
                exit 1
                ;;
            *)
                # Assume it's the message body (for preset usage)
                MESSAGE="$1"
                shift
                ;;
        esac
    done

    # Apply preset if specified
    if [[ -n "$PRESET" ]]; then
        if [[ ! -v PRESET_PRIORITY[$PRESET] ]]; then
            echo "Error: Unknown preset: $PRESET" >&2
            echo "Available presets: ${!PRESET_PRIORITY[*]}" >&2
            exit 1
        fi

        # Use preset values if not overridden by command-line args
        [[ -z "$TITLE" ]] && TITLE="${PRESET_TITLE[$PRESET]}"
        [[ "$PRIORITY" == "default" ]] && PRIORITY="${PRESET_PRIORITY[$PRESET]}"
        [[ -z "$TAGS" ]] && TAGS="${PRESET_TAGS[$PRESET]}"
    fi

    # Validate required fields
    if [[ -z "$MESSAGE" ]]; then
        echo "Error: --message or positional message argument is required" >&2
        usage
        exit 1
    fi

    # Default title if not set
    [[ -z "$TITLE" ]] && TITLE="Notification"

    # Send notification
    notify_send "$TITLE" "$MESSAGE" "$PRIORITY" "$TAGS" "$TOPIC" "$DRY_RUN"
fi
