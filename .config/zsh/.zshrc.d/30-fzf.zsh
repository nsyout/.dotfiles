#!/usr/bin/env zsh

# fzf configuration

# Flexoki Dark theme
export FZF_DEFAULT_OPTS="
  --color=bg:#100F0F,bg+:#1C1B1A,fg:#CECDC3,fg+:#CECDC3
  --color=hl:#DA702C,hl+:#D0A215,info:#878580,marker:#879A39
  --color=prompt:#4385BE,spinner:#CE5D97,pointer:#CE5D97,header:#DA702C
  --color=border:#575653,label:#CECDC3,query:#CECDC3
"

# Source from Homebrew installation
if command -v fzf &>/dev/null; then
    # Homebrew fzf shell integration
    if [[ -d "/opt/homebrew/opt/fzf/shell" ]]; then
        source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
        source "/opt/homebrew/opt/fzf/shell/completion.zsh"
    elif [[ -d "/usr/local/opt/fzf/shell" ]]; then
        source "/usr/local/opt/fzf/shell/key-bindings.zsh"
        source "/usr/local/opt/fzf/shell/completion.zsh"
    fi
fi

# fzf utilities
[[ -f "$ZDOTDIR/plugins/fzf-utils/fzf-utils.zsh" ]] && source "$ZDOTDIR/plugins/fzf-utils/fzf-utils.zsh"