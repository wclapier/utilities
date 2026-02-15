# Wade's Utilities Repository

Personal collection of useful scripts, dotfiles, and setup templates.

## Structure

```
utilities/
├── bash/              # Bash configuration, aliases, functions
│   ├── .bashrc        # Main bash config
│   ├── .bash_aliases  # Custom aliases
│   └── .bash_functions # Reusable functions
├── scripts/           # Standalone utility scripts
│   ├── dev/           # Development utilities
│   ├── system/        # System utilities
│   └── automation/    # Automation scripts
├── dotfiles/          # Configuration files (.vimrc, .gitconfig, etc.)
└── README.md          # This file
```

## Quick Setup

```bash
# Clone and source in ~/.bashrc
git clone <repo> ~/utilities
echo "source ~/utilities/bash/.bashrc" >> ~/.bashrc
```

## Categories

### Bash Utilities
- Custom prompt with git status
- Directory navigation shortcuts
- Development workflow commands
- System monitoring aliases

### Scripts (Ready)
- (TBD — see execution plan)

### Dotfiles (Ready)
- (TBD — see execution plan)

## Adding New Utilities

1. Add script to appropriate `scripts/*/` subdirectory
2. Update README with description
3. Test before committing
4. Commit to ~/utilities repo

## Usage

Most utilities are auto-loaded via `~/.bashrc`. For standalone scripts:
```bash
~/utilities/scripts/dev/some-tool.sh
```

---

**Status**: Initialized 2026-02-15
**See also**: Execution plan (Topic X — Utilities Framework)
