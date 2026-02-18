#!/usr/bin/env bash
# color-functions.sh — ANSI color codes and terminal output helpers
#
# Source this file to get consistent color codes and print helpers
# across all scripts.
#
# Usage:
#   source ~/utilities/bash/color-functions.sh
#   echo -e "${RED}error${RESET}"
#   print_ok "Backup completed"
#   print_warn "Disk at 85%"
#   print_error "Connection failed"

# ── Color codes ────────────────────────────────────────────────────────────
# Guard against double-sourcing
[[ -n "${_COLOR_FUNCTIONS_LOADED:-}" ]] && return 0
_COLOR_FUNCTIONS_LOADED=1

export RESET='\033[0m'
export BOLD='\033[1m'
export DIM='\033[2m'
export UNDERLINE='\033[4m'

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'

# Short aliases (used in statusline/taskgraph style scripts)
export R="$RESET"
export GRN="$GREEN"
export YLW="$YELLOW"
export BLU="$BLUE"
export MAG="$MAGENTA"
export CYN="$CYAN"
export WHT="$WHITE"
export BGBLK='\033[40m'

# Backward-compat alias used in backup scripts
export NC="$RESET"

# ── Print helpers ──────────────────────────────────────────────────────────

print_ok() {
    echo -e "${GREEN}✓${RESET} $*"
}

print_error() {
    echo -e "${RED}✗${RESET} $*" >&2
}

print_warn() {
    echo -e "${YELLOW}!${RESET} $*"
}

print_info() {
    echo -e "${BLUE}ℹ${RESET} $*"
}

# Timestamped variants (used in backup/health scripts)
log_ok()    { echo -e "[$(date -Iseconds)] ${GREEN}OK${RESET}: $*"; }
log_info()  { echo -e "[$(date -Iseconds)] INFO: $*"; }
log_warn()  { echo -e "[$(date -Iseconds)] ${YELLOW}WARN${RESET}: $*"; }
log_error() { echo -e "[$(date -Iseconds)] ${RED}ERROR${RESET}: $*" >&2; }
