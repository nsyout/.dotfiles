function show-keybinds() {
    bindkey | fzf --header 'ZSH Keybindings' --reverse --border=rounded --prompt="❯ " --ansi --height=50%
}

function show-aliases() {
    alias | fzf --header 'Aliases' --reverse --border=rounded --prompt="❯ " --ansi --height=50%
}

function show-functions() {
    print -l ${(ok)functions} | fzf --header 'Functions' --reverse --border=rounded --prompt="❯ " --ansi --height=50%
}

# Register as ZLE widgets
zle -N show-keybinds
zle -N show-aliases
zle -N show-functions

# Bind to keys
bindkey '^[w' show-keybinds   # Option+w for which-key
bindkey '^[a' show-aliases    # Option+A for aliases
bindkey '^[f' show-functions  # Option+F for functions