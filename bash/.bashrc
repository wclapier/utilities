# Wade's Custom Bash Configuration
# Source this in your ~/.bashrc: echo "source ~/utilities/bash/.bashrc" >> ~/.bashrc

# ============================================================================
# SHELL OPTIONS
# ============================================================================

# Don't add duplicate commands to history
HISTCONTROL=ignoredups:erasedups
# Increase history size
HISTSIZE=50000
HISTFILESIZE=50000
# Append to history instead of overwriting
shopt -s histappend
# Record multi-line commands as single history entry
shopt -s cmdhist
# Update window size after each command
shopt -s checkwinsize
# Extended globbing
shopt -s extglob

# ============================================================================
# PROMPT
# ============================================================================

# Simple prompt with git branch (if git is available)
git_branch() {
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
        echo " [$branch]"
    fi
}

if [ -x /usr/bin/tput ] && tput setaf 1 >/dev/null 2>&1; then
    # Color support available
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(git_branch)\[\033[00m\]\$ '
else
    # Fallback for no color
    PS1='\u@\h:\w$(git_branch)\$ '
fi

# ============================================================================
# COMMON ALIASES
# ============================================================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ll='ls -lh'
alias la='ls -lha'
alias l='ls -CF'
alias cd-='cd -'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'
alias gb='git branch'

# Development
alias python='python3'
alias pip='pip3'
alias grep='grep --color=auto'
alias less='less -R'

# System
alias df='df -h'
alias du='du -h'
alias ps='ps aux'
alias c='clear'
alias reload='source ~/.bashrc'

# ============================================================================
# CUSTOM FUNCTIONS
# ============================================================================

# Make directory and change into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Quick find files by name
f() {
    find . -name "*$1*" 2>/dev/null
}

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1" ;;
            *.tar.gz)    tar xzf "$1" ;;
            *.bz2)       bunzip2 "$1" ;;
            *.rar)       unrar x "$1" ;;
            *.gz)        gunzip "$1" ;;
            *.tar)       tar xf "$1" ;;
            *.tbz2)      tar xjf "$1" ;;
            *.tgz)       tar xzf "$1" ;;
            *.zip)       unzip "$1" ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1" ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Show git status for all repos in current directory
gitall() {
    for dir in */; do
        if [ -d "$dir/.git" ]; then
            echo "=== $dir ==="
            (cd "$dir" && git status -s)
        fi
    done
}

# ============================================================================
# LOAD ADDITIONAL CONFIGS
# ============================================================================

# Load aliases if they exist
[ -f ~/utilities/bash/.bash_aliases ] && source ~/utilities/bash/.bash_aliases

# Load functions if they exist
[ -f ~/utilities/bash/.bash_functions ] && source ~/utilities/bash/.bash_functions

# ============================================================================
# ENVIRONMENT
# ============================================================================

# Preferred editor
export EDITOR=vim
export VISUAL=vim

# Colors for ls
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
fi

# ============================================================================
# OPTIONAL: Local machine overrides
# ============================================================================

# If ~/.bashrc.local exists, source it (for machine-specific settings)
[ -f ~/.bashrc.local ] && source ~/.bashrc.local

echo "✓ Wade's bash config loaded"
