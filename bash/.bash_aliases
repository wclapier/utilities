# Additional Bash Aliases
# Sourced by .bashrc

# ============================================================================
# PROJECT NAVIGATION
# ============================================================================

alias wade='cd /home/wade/wade'
alias util='cd /home/wade/utilities'
alias proj='cd /home/wade/wade/projects'

# ============================================================================
# QUICK ACTIONS
# ============================================================================

# Git workflows
alias git-sync='git fetch origin && git rebase origin/main'
alias git-clean='git branch --merged | grep -v "\*" | xargs -n 1 git branch -d'

# System info
alias sysinfo='echo "=== System Info ===" && uname -a && echo && echo "=== Disk ===" && df -h && echo && echo "=== Memory ===" && free -h'
alias ports='lsof -i -P -n | grep LISTEN'

# ============================================================================
# DEVELOPMENT ALIASES
# ============================================================================

# Quick web server
alias serve='python3 -m http.server 8000'

# JSON pretty print
alias json='python3 -m json.tool'

# ============================================================================
# ADD YOUR CUSTOM ALIASES BELOW
# ============================================================================
