# Additional Bash Functions
# Sourced by .bashrc

# ============================================================================
# DEVELOPMENT FUNCTIONS
# ============================================================================

# Print colorized output
print_success() {
    echo -e "\033[0;32m✓ $1\033[0m"
}

print_error() {
    echo -e "\033[0;31m✗ $1\033[0m"
}

print_info() {
    echo -e "\033[0;34mℹ $1\033[0m"
}

# ============================================================================
# GIT FUNCTIONS
# ============================================================================

# Commit with timestamp
git-log-last() {
    local count=${1:-5}
    git log --oneline -n $count
}

# Create feature branch
git-feature() {
    local branch="feature/$1"
    git checkout -b "$branch"
    print_success "Created branch: $branch"
}

# ============================================================================
# FILE UTILITIES
# ============================================================================

# Show line count in current directory
linecount() {
    find . -type f -name "*.${1:-*}" | xargs wc -l | tail -1
}

# Show largest files in directory
largest() {
    local count=${1:-10}
    du -sh * | sort -rh | head -n $count
}

# ============================================================================
# SYSTEM FUNCTIONS
# ============================================================================

# Kill process by name
pkill-name() {
    ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
}

# ============================================================================
# ADD YOUR CUSTOM FUNCTIONS BELOW
# ============================================================================
