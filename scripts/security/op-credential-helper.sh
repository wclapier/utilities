#!/usr/bin/env bash
# op-credential-helper.sh — 1Password credential retrieval with flat-file fallback
#
# Sourceable helper providing get_credential() for all backup/mount scripts.
# Tries `op read` first (interactive sessions with 1Password CLI).
# Falls back to flat files (systemd unattended context).
#
# Usage: source /path/to/op-credential-helper.sh
#
# Functions:
#   _op_available          — returns 0 if `op` CLI is authenticated
#   get_credential REF FB  — returns credential from 1Password ref or fallback file
#   get_credential_value REF FB — same but prints to stdout (for subshell capture)

# ─── Cache ────────────────────────────────────────────────────────────────
# Cache op availability check for the lifetime of the sourcing script
_OP_CHECKED=""
_OP_AVAILABLE=""

# ─── Functions ────────────────────────────────────────────────────────────

_op_available() {
    # Return cached result if already checked
    if [[ -n "$_OP_CHECKED" ]]; then
        [[ "$_OP_AVAILABLE" == "yes" ]]
        return $?
    fi

    _OP_CHECKED="1"

    # Check if op binary exists
    if ! command -v op &>/dev/null; then
        _OP_AVAILABLE="no"
        return 1
    fi

    # Check if op is authenticated (op whoami succeeds when signed in)
    if op whoami &>/dev/null; then
        _OP_AVAILABLE="yes"
        return 0
    fi

    _OP_AVAILABLE="no"
    return 1
}

# get_credential_value OP_REFERENCE FALLBACK_FILE
#
# Prints the credential value to stdout.
# Tries 1Password first, falls back to reading file contents.
# Returns non-zero if neither source is available.
get_credential_value() {
    local op_ref="$1"
    local fallback_file="${2:-}"

    if _op_available && [[ -n "$op_ref" ]]; then
        local value
        value=$(op read "$op_ref" 2>/dev/null) && {
            printf '%s' "$value"
            return 0
        }
    fi

    # Fallback to flat file
    if [[ -n "$fallback_file" && -f "$fallback_file" ]]; then
        cat "$fallback_file"
        return 0
    fi

    return 1
}

# get_credential OP_REFERENCE FALLBACK_FILE
#
# Alias for get_credential_value (backward compat).
get_credential() {
    get_credential_value "$@"
}

# source_credential_env OP_PREFIX FALLBACK_ENV_FILE
#
# Sources B2 environment variables. Tries 1Password first for individual
# fields, falls back to sourcing the flat env file.
# OP_PREFIX should be the vault item path, e.g. "op://Private/B2-Private-Credentials"
source_credential_env() {
    local op_prefix="$1"
    local fallback_env="${2:-}"

    if _op_available && [[ -n "$op_prefix" ]]; then
        local acct_id acct_key
        acct_id=$(op read "${op_prefix}/account-id" 2>/dev/null) || true
        acct_key=$(op read "${op_prefix}/account-key" 2>/dev/null) || true

        if [[ -n "$acct_id" && -n "$acct_key" ]]; then
            export B2_ACCOUNT_ID="$acct_id"
            export B2_ACCOUNT_KEY="$acct_key"
            return 0
        fi
    fi

    # Fallback to flat env file
    if [[ -n "$fallback_env" && -f "$fallback_env" ]]; then
        source "$fallback_env"
        return 0
    fi

    return 1
}

# ─── Validation ───────────────────────────────────────────────────────────

# Ensure this file was sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: op-credential-helper.sh should be sourced, not executed directly"
    echo "Usage: source /path/to/op-credential-helper.sh"
    exit 1
fi
