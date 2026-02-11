#!/usr/bin/env zsh

# FZF-enhanced utility functions
# Adapted from Phantas0s dotfiles for cross-platform use

# Git interactive file staging/unstaging
fgf() {
    local files
    files=$(git -c color.status=always status --short) &&
    echo "$files" | fzf --ansi \
        --height 80% --border \
        --preview 'git diff --color=always {2}' \
        --header 'CTRL-A: add, CTRL-R: reset, CTRL-D: diff' \
        --bind 'ctrl-a:execute-silent(git add {2})+reload(git -c color.status=always status --short)' \
        --bind 'ctrl-r:execute-silent(git reset {2})+reload(git -c color.status=always status --short)' \
        --bind 'ctrl-d:preview(git diff --color=always {2})'
}

# Git interactive commit browser
fgc() {
    local commits
    commits=$(git log --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr") &&
    echo "$commits" | fzf --ansi \
        --height 80% --border \
        --preview 'git show --color=always {1}' \
        --header 'CTRL-O: checkout, CTRL-Y: copy hash' \
        --bind 'ctrl-o:execute-silent(git checkout {1})' \
        --bind 'ctrl-y:execute-silent(echo {1} | pbcopy)+abort'
}

# Git interactive branch management  
fgb() {
    local branches
    branches=$(git branch -a --color=always | grep -v '/HEAD\s') &&
    echo "$branches" | fzf --ansi \
        --height 80% --border \
        --preview 'git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(sed s/^..// <<< {} | cut -d" " -f1) | head -'$LINES \
        --header 'CTRL-O: checkout, CTRL-D: delete' \
        --bind 'ctrl-o:execute-silent(git checkout $(sed s/^..// <<< {} | cut -d" " -f1))' \
        --bind 'ctrl-d:execute-silent(git branch -d $(sed s/^..// <<< {} | cut -d" " -f1))'
}

# Find text in files with preview
fif() {
    if [ ! "$#" -gt 0 ]; then
        echo "Need a string to search for!"
        return 1
    fi
    
    rg --files-with-matches --no-messages "$1" | \
    fzf --preview "rg --ignore-case --pretty --context 10 '$1' {}" \
        --height 80% --border \
        --header 'Enter: open file, CTRL-E: edit' \
        --bind "enter:execute($EDITOR {})" \
        --bind "ctrl-e:execute($EDITOR {})"
}

# Navigate to project directories
fwork() {
    local projects_dir="${HOME}/Projects"
    
    # Check common project directory names
    for dir in "${HOME}/Projects" "${HOME}/projects" "${HOME}/code" "${HOME}/dev"; do
        if [[ -d "$dir" ]]; then
            projects_dir="$dir"
            break
        fi
    done
    
    if [[ ! -d "$projects_dir" ]]; then
        echo "No projects directory found!"
        return 1
    fi
    
    local project
    project=$(find "$projects_dir" -mindepth 1 -maxdepth 2 -type d | \
              sed "s|$projects_dir/||" | \
              fzf --height 40% --border --header "Projects in $projects_dir") &&
    cd "$projects_dir/$project"
}

# Search directory stack
fpop() {
    local dir
    dir=$(dirs -v | fzf --height 40% --border --header 'Directory Stack' | awk '{print $2}') &&
    cd "$dir"
}

# Enhanced man page search
fman() {
    man -k . | fzf --height 80% --border \
        --preview 'man {1}' \
        --header 'Enter: open man page' \
        --bind 'enter:execute(man {1})'
}

# Process killer with fzf
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --height 80% --border \
          --header 'Select process to kill' | awk '{print $2}')
    
    if [ "x$pid" != "x" ]; then
        echo "$pid" | xargs kill -${1:-9}
    fi
}

# Docker container management
fdocker() {
    local container
    container=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | \
                tail -n +2 | \
                fzf --height 80% --border \
                    --header 'CTRL-S: start, CTRL-T: stop, CTRL-R: restart, CTRL-D: delete' \
                    --bind 'ctrl-s:execute-silent(docker start {1})' \
                    --bind 'ctrl-t:execute-silent(docker stop {1})' \
                    --bind 'ctrl-r:execute-silent(docker restart {1})' \
                    --bind 'ctrl-d:execute-silent(docker rm {1})')
}

# SSH host connection
fssh() {
    local host
    host=$(grep -E '^Host [^*]' ~/.ssh/config 2>/dev/null | \
           awk '{print $2}' | \
           fzf --height 40% --border --header 'SSH Hosts') &&
    ssh "$host"
}