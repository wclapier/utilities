#!/usr/bin/env bash
# status-display.sh — Terminal status badges for Claude Code agent workflows
#
# Provides tier_badge(), status_badge(), model_badge(), and agent_badge()
# functions used by taskgraph.sh and statusline.sh.
#
# Requires color-functions.sh to be sourced first (or sourced automatically).
#
# Usage:
#   source ~/utilities/bash/status-display.sh
#   tier_badge 0        # prints colored PUB badge
#   status_badge running
#   model_badge sonnet

# Guard against double-sourcing
[[ -n "${_STATUS_DISPLAY_LOADED:-}" ]] && return 0
_STATUS_DISPLAY_LOADED=1

# Source colors if not already loaded
_SD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -z "${_COLOR_FUNCTIONS_LOADED:-}" ]] && source "$_SD_DIR/color-functions.sh"

# ── Tier badges ───────────────────────────────────────────────────────────
# tier_badge TIER_NUM
# 0=public  1=private  2=private-private  3=secret

tier_badge() {
    case "$1" in
        0) printf "${GRN}█PUB█${R}" ;;
        1) printf "${YLW}█PRV█${R}" ;;
        2) printf "${MAG}█P·P█${R}" ;;
        3) printf "${RED}█SEC█${R}" ;;
        *) printf "${DIM}█···█${R}" ;;
    esac
}

# Short form for statusline (no block chars)
tier_color() {
    case "$1" in
        0) echo -e "${GRN}PUB${R}" ;;
        1) echo -e "${YLW}PRV${R}" ;;
        2) echo -e "${MAG}P-P${R}" ;;
        3) echo -e "${RED}SEC${R}" ;;
        *) echo -e "${DIM}???${R}" ;;
    esac
}

# ── Status badges ─────────────────────────────────────────────────────────
# status_badge STATUS_STRING

status_badge() {
    case "$1" in
        running|in_progress) printf "${GRN}${BOLD}▶ RUN ${R}" ;;
        pending)             printf "${YLW}○ PND ${R}" ;;
        completed|done)      printf "${BLU}✓ DON ${R}" ;;
        blocked)             printf "${RED}◌ BLK ${R}" ;;
        error|failed)        printf "${RED}✗ ERR ${R}" ;;
        *)                   printf "${DIM}· --- ${R}" ;;
    esac
}

# Compact icon form for statusline
status_icon() {
    case "$1" in
        running|in_progress) echo -e "${GRN}●${R}" ;;
        pending)             echo -e "${YLW}○${R}" ;;
        completed|done)      echo -e "${BLU}✓${R}" ;;
        blocked)             echo -e "${RED}◌${R}" ;;
        error|failed)        echo -e "${RED}✗${R}" ;;
        *)                   echo -e "${DIM}·${R}" ;;
    esac
}

# ── Model badges ──────────────────────────────────────────────────────────
# model_badge MODEL_STRING

model_badge() {
    case "$1" in
        *opus*|OPU)    printf "${MAG}◆OPU${R}" ;;
        *sonnet*|SON)  printf "${CYN}◆SON${R}" ;;
        *haiku*|HAI)   printf "${GRN}◆HAI${R}" ;;
        inherit|"")    printf "${DIM}◆inh${R}" ;;
        *gpt*|GPT)     printf "${BLU}◆GPT${R}" ;;
        *local*|LOC)   printf "${WHT}◆LOC${R}" ;;
        *)             printf "${DIM}◆${1:0:3}${R}" ;;
    esac
}

# Short model name for statusline
model_short() {
    case "$1" in
        *opus*)   echo -e "${MAG}OPU${R}" ;;
        *sonnet*) echo -e "${CYN}SON${R}" ;;
        *haiku*)  echo -e "${GRN}HAI${R}" ;;
        *)        echo -e "${DIM}${1:0:3}${R}" ;;
    esac
}

# ── Agent profile badge ───────────────────────────────────────────────────
# agent_badge PROFILE_NAME

agent_badge() {
    local name="$1"
    [[ -z "$name" ]] && { printf "${DIM}[no agent]${R}"; return; }
    local color
    case "$name" in
        orchestrator*) color="$MAG" ;;
        researcher*)   color="$CYN" ;;
        builder*)      color="$GRN" ;;
        analyst*)      color="$YLW" ;;
        sentinel*)     color="$RED" ;;
        *)             color="$WHT" ;;
    esac
    printf "${color}⬡ ${name}${R}"
}
