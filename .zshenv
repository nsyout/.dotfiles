# macOS-specific environment variables

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"

# Export path to root of dotfiles repo
export DOTFILES=${DOTFILES:="$HOME/.dotfiles"}

# zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/.zsh_history"    # History filepath
export HISTSIZE=10000                   # Maximum events for internal history
export SAVEHIST=10000                   # Maximum events in history file

# other software
export VIMCONFIG="$XDG_CONFIG_HOME/nvim"

# fzf (theme in .config/zsh/.zshrc.d/30-fzf.zsh)
export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Locale
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

 # Default pager
export PAGER='less'

# less options
less_opts=(
  # Quit if entire file fits on first screen.
  -FX
  # Ignore case in searches that do not contain uppercase.
  --ignore-case
  # Allow ANSI colour escapes, but no other escapes.
  --RAW-CONTROL-CHARS
  # Quiet the terminal bell. (when trying to scroll past the end of the buffer)
  --quiet
  # Do not complain when we are on a dumb terminal.
  --dumb
)
export LESS="${less_opts[*]}"

# Better formatting for time command
export TIMEFMT=$'\n================\nCPU\t%P\nuser\t%*U\nsystem\t%*S\ntotal\t%*E'

# Load Rust environment if available
if [[ -f "$HOME/.cargo/env" ]]; then
    . "$HOME/.cargo/env"
fi

# macOS-specific settings
export HOMEBREW_NO_ANALYTICS=1

# Add Homebrew to PATH if it exists (before system paths)
if [[ -d "/opt/homebrew" ]]; then
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
elif [[ -d "/usr/local/bin" ]]; then
    export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
fi

# User-local binaries
export PATH="$HOME/.local/bin:$PATH"

# Overseer runtime paths
export OVERSEER_HOST_SCRIPT="$HOME/.local/share/overseer/current/host/dist/index.js"
export OVERSEER_UI_DIST="$HOME/.local/share/overseer/current/ui/dist"

# SSH FIDO2 support - use Homebrew's OpenSSH on macOS
# System SSH may lack FIDO2 support, Homebrew OpenSSH includes libfido2
if [[ -f "/opt/homebrew/bin/ssh" ]]; then
    alias ssh="/opt/homebrew/bin/ssh"
    alias ssh-add="/opt/homebrew/bin/ssh-add"
    alias ssh-keygen="/opt/homebrew/bin/ssh-keygen"
fi
