#!/usr/bin/env zsh

# Modular zsh configuration loader
# Load all .zsh files from .zshrc.d/ directory in order

# Helper function for safe sourcing with warnings
safe_source() {
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "Warning: Missing config file: $1" >&2
    fi
}

# Load modular configuration files
if [[ -d "$ZDOTDIR/.zshrc.d" ]]; then
    for config_file in "$ZDOTDIR/.zshrc.d"/*.zsh; do
        if [[ -r "$config_file" ]]; then
            source "$config_file"
        fi
    done
    unset config_file
else
    echo "Warning: ~/.zshrc.d directory not found" >&2
fi
# Created by `pipx` on 2025-09-17 04:30:12
export PATH="$PATH:$HOME/.local/bin"
