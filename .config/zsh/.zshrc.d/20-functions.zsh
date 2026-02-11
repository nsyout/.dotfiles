#!/usr/bin/env zsh

# Helper function for safe sourcing with warnings
safe_source() {
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "Warning: Missing config file: $1" >&2
    fi
}

# Load custom functions and scripts
safe_source "$ZDOTDIR/scripts.zsh"