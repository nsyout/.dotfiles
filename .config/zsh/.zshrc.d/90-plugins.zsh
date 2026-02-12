#!/usr/bin/env zsh

# Prompt - Starship (fast Rust-based prompt)
eval "$(starship init zsh)"

# zoxide
eval "$(zoxide init zsh)"

# Plugin loading - order matters for some plugins

# Load utility plugins first
safe_source "$ZDOTDIR/plugins/bd/bd.zsh"
safe_source "$ZDOTDIR/plugins/smartdots/smartdots.zsh"
safe_source "$ZDOTDIR/plugins/which-key/which-key.zsh"
safe_source "$ZDOTDIR/plugins/gitit.zsh"

# Syntax highlighting - Should be at the end of all plugins
safe_source "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
