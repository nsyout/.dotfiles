#!/usr/bin/env zsh

# =============================================================================
# noisyoutput.com content management
# =============================================================================

# Main entry point: nsy [create|publish]
nsy() {
    local HUGO_DIR="${NSY_HUGO_DIR:-$HOME/projects/repos/noisyoutput.com}"

    if [[ ! -d "$HUGO_DIR" ]]; then
        echo "Error: Hugo directory not found: $HUGO_DIR"
        echo "Set NSY_HUGO_DIR to override."
        return 1
    fi

    local subcommand="$1"

    # If no subcommand, show menu
    if [[ -z "$subcommand" ]]; then
        subcommand=$(printf "Create\nManage\nSync" | fzf --prompt="nsy › " --height=10)
        [[ -z "$subcommand" ]] && { echo "Cancelled."; return 1; }
    fi

    case "$subcommand" in
        create|c|"Create")
            _nsy_create "$HUGO_DIR"
            ;;
        manage|m|"Manage")
            _nsy_manage "$HUGO_DIR"
            ;;
        sync|s|"Sync")
            _nsy_sync "$HUGO_DIR"
            ;;
        note|writing|page)
            # Direct type shortcut
            _nsy_create "$HUGO_DIR" "$1"
            ;;
        *)
            echo "Unknown command: $subcommand"
            echo "Usage: nsy [create|manage|sync|note|writing|page]"
            return 1
            ;;
    esac
}

# Create new content
_nsy_create() {
    local hugo_dir="$1"
    local type="$2"
    local name hugo_path content_file

    # Select type if not provided
    if [[ -z "$type" ]]; then
        type=$(printf "note\npage\nwriting" | fzf --prompt="Content type: " --height=10)
        [[ -z "$type" ]] && { echo "Cancelled."; return 1; }
    fi

    # Validate type
    case "$type" in
        note|notes) type="note" ;;
        writing) ;;
        page) ;;
        *)
            echo "Error: Type must be 'note', 'writing', or 'page'"
            return 1
            ;;
    esac

    # Get name
    echo -n "Name (slug): "
    read name
    [[ -z "$name" ]] && { echo "Cancelled."; return 1; }

    # Set hugo path based on type
    local note_type=""
    case "$type" in
        note)
            hugo_path="notes/$name.md"
            # Ask for note type (link, note, quote)
            note_type=$(printf "link\nnote\nquote" | fzf --prompt="Note type: " --height=10)
            [[ -z "$note_type" ]] && { echo "Cancelled."; return 1; }
            ;;
        writing) hugo_path="writing/$name.md" ;;
        page)    hugo_path="$name.md" ;;
    esac

    cd "$hugo_dir" || return 1
    content_file="content/$hugo_path"

    # Create the content
    echo "Creating: $hugo_path"
    hugo new "$hugo_path" || { echo "Error: Failed to create content"; return 1; }

    # Ensure draft = true is in frontmatter (TOML format)
    echo "Ensuring draft = true in $content_file"
    if grep -qE "^draft[[:space:]]*=" "$content_file"; then
        echo "  → Found existing draft line, setting to true"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' -E 's/^draft[[:space:]]*=.*/draft = true/' "$content_file"
        else
            sed -i -E 's/^draft[[:space:]]*=.*/draft = true/' "$content_file"
        fi
    else
        echo "  → No draft line found, adding draft = true"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' -E '/^title[[:space:]]*=/a\
draft = true' "$content_file"
        else
            sed -i -E '/^title[[:space:]]*=/a draft = true' "$content_file"
        fi
    fi

    # Set note type if creating a note
    if [[ -n "$note_type" ]]; then
        echo "  → Setting note type to: $note_type"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' -E "s/^note_type[[:space:]]*=.*/note_type = '$note_type'/" "$content_file"
        else
            sed -i -E "s/^note_type[[:space:]]*=.*/note_type = '$note_type'/" "$content_file"
        fi
    fi

    echo "  → Frontmatter now:"
    head -10 "$content_file"

    local done=false
    local hugo_pid

    while [[ "$done" == "false" ]]; do
        # Open in editor
        ${EDITOR:-nvim} "$content_file"

        # Start hugo serve in background
        echo "Starting preview server..."
        hugo serve --buildDrafts --quiet &
        hugo_pid=$!
        sleep 2

        # Open browser
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open "http://localhost:1313"
        else
            xdg-open "http://localhost:1313" 2>/dev/null
        fi

        echo "Preview opened at http://localhost:1313"
        echo ""

        # Prompt for action
        local action=$(printf "Discard\nKeep editing\nPublish\nSave as draft" | fzf --prompt="Action: " --height=10)

        # Kill hugo serve
        kill $hugo_pid 2>/dev/null
        wait $hugo_pid 2>/dev/null

        case "$action" in
            "Save as draft")
                git add "$content_file"
                echo "Staged as draft. Run 'nsy sync' to commit and push."
                done=true
                ;;
            "Publish")
                # Flip draft to false (TOML format)
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' -E 's/^draft[[:space:]]*=[[:space:]]*true/draft = false/' "$content_file"
                else
                    sed -i -E 's/^draft[[:space:]]*=[[:space:]]*true/draft = false/' "$content_file"
                fi
                git add "$content_file"
                echo "Staged for publish. Run 'nsy sync' to commit and push."
                done=true
                ;;
            "Keep editing")
                # Loop continues
                ;;
            "Discard"|"")
                echo -n "Delete the file? [y/N] "
                read confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -f "$content_file"
                    echo "Discarded."
                else
                    echo "File kept at: $content_file"
                fi
                done=true
                ;;
        esac
    done
}

# Manage all content (edit, delete, unpublish)
_nsy_manage() {
    local hugo_dir="$1"

    cd "$hugo_dir" || return 1

    # Filter selection
    local filter=$(printf "All\nDrafts\nPublished" | fzf --prompt="Show: " --height=10)
    [[ -z "$filter" ]] && { echo "Cancelled."; return 1; }

    while true; do
        # Find content based on filter (refresh each loop)
        local files
        case "$filter" in
            "All")
                files=$(find content -name "*.md" -type f 2>/dev/null | sort)
                ;;
            "Drafts")
                files=$(grep -rlE "^draft[[:space:]]*=[[:space:]]*true" content/ 2>/dev/null | sort)
                ;;
            "Published")
                # Files with draft = false OR no draft line
                files=$(find content -name "*.md" -type f 2>/dev/null | while read f; do
                    if ! grep -qE "^draft[[:space:]]*=[[:space:]]*true" "$f"; then
                        echo "$f"
                    fi
                done | sort)
                ;;
        esac

        if [[ -z "$files" ]]; then
            echo "No content found."
            return 0
        fi

        # Select content (Esc to exit)
        local selected=$(echo "$files" | fzf --prompt="Select content (Esc to exit): " --height=20 --preview="head -30 {}")
        [[ -z "$selected" ]] && { echo "Done."; return 0; }

        echo "Selected: $selected"

        local name=$(basename "$selected" .md)
        local is_draft=$(grep -qE "^draft[[:space:]]*=[[:space:]]*true" "$selected" && echo "yes" || echo "no")

    # Build action list based on draft status
    local actions="Delete\nEdit\nPreview"
    if [[ "$is_draft" == "yes" ]]; then
        actions="$actions\nPublish"
    else
        actions="$actions\nUnpublish"
    fi

    local action=$(echo -e "$actions" | sort | fzf --prompt="Action: " --height=10)
    [[ -z "$action" ]] && { echo "Cancelled."; return 1; }

    case "$action" in
        "Delete")
            echo -n "Delete '$name'? [y/N] "
            read confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                rm -f "$selected"
                git add "$selected"
                echo "Staged deletion. Run 'nsy sync' to commit and push."
            else
                echo "Cancelled."
            fi
            ;;
        "Edit")
            ${EDITOR:-nvim} "$selected"
            echo -n "Stage changes? [y/N] "
            read confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                # Update lastmod timestamp
                local timestamp=$(date -Iseconds)
                if grep -qE "^lastmod[[:space:]]*=" "$selected"; then
                    # Update existing lastmod
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        sed -i '' -E "s/^lastmod[[:space:]]*=.*/lastmod = $timestamp/" "$selected"
                    else
                        sed -i -E "s/^lastmod[[:space:]]*=.*/lastmod = $timestamp/" "$selected"
                    fi
                else
                    # Add lastmod after date
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        sed -i '' -E "/^date[[:space:]]*=/a\\
lastmod = $timestamp" "$selected"
                    else
                        sed -i -E "/^date[[:space:]]*=/a lastmod = $timestamp" "$selected"
                    fi
                fi
                git add "$selected"
                echo "Staged (lastmod updated). Run 'nsy sync' to commit and push."
            fi
            ;;
        "Preview")
            hugo serve --buildDrafts --quiet &
            local hugo_pid=$!
            sleep 2

            if [[ "$OSTYPE" == "darwin"* ]]; then
                open "http://localhost:1313"
            else
                xdg-open "http://localhost:1313" 2>/dev/null
            fi

            echo "Preview opened at http://localhost:1313"
            echo "Press enter when done..."
            read
            kill $hugo_pid 2>/dev/null
            wait $hugo_pid 2>/dev/null
            ;;
        "Publish")
            _nsy_publish_file "$selected" "$name"
            ;;
        "Unpublish")
            # Set draft = true
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' -E 's/^draft[[:space:]]*=[[:space:]]*false/draft = true/' "$selected"
            else
                sed -i -E 's/^draft[[:space:]]*=[[:space:]]*false/draft = true/' "$selected"
            fi
            git add "$selected"
            echo "Staged unpublish. Run 'nsy sync' to commit and push."
            ;;
    esac
    done
}

# Sync - commit and push all staged changes
_nsy_sync() {
    local hugo_dir="$1"

    cd "$hugo_dir" || return 1

    # Check if there are staged changes
    if git diff --cached --quiet; then
        echo "Nothing to sync (no staged changes)."
        git status --short
        return 0
    fi

    echo "Staged changes:"
    git diff --cached --name-status
    echo ""

    echo -n "Commit message: "
    read msg
    [[ -z "$msg" ]] && { echo "Cancelled."; return 1; }

    git commit -m "$msg"
    git push origin

    echo "Synced!"
}

# Helper to publish a draft file
_nsy_publish_file() {
    local file="$1"
    local name="$2"

    # Flip draft to false (TOML format)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' -E 's/^draft[[:space:]]*=[[:space:]]*true/draft = false/' "$file"
    else
        sed -i -E 's/^draft[[:space:]]*=[[:space:]]*true/draft = false/' "$file"
    fi

    git add "$file"
    echo "Staged for publish. Run 'nsy sync' to commit and push."
}

# =============================================================================
# Archive & compression utilities
# =============================================================================

screenres() {
    [ ! -z $1 ] && xrandr --current | grep '*' | awk '{print $1}' | sed -n "$1p"
}

# Extract files
extract() {
    for file in "$@"
    do
        if [ -f $file ]; then
            _ex $file
        else
            echo "'$file' is not a valid file"
        fi
    done
}

# Extract files in their own directories
mkextract() {
    for file in "$@"
    do
        if [ -f $file ]; then
            local filename=${file%\.*}
            mkdir -p $filename
            cp $file $filename
            cd $filename
            _ex $file
            rm -f $file
            cd -
        else
            echo "'$1' is not a valid file"
        fi
    done
}


# Internal function to extract any archive
_ex() {
    case $1 in
        *.tar.bz2)  tar xjf $1      ;;
        *.tar.gz)   tar xzf $1      ;;
        *.bz2)      bunzip2 $1      ;;
        *.gz)       gunzip $1       ;;
        *.tar)      tar xf $1       ;;
        *.tbz2)     tar xjf $1      ;;
        *.tgz)      tar xzf $1      ;;
        *.zip)      unzip $1        ;;
        *.7z)       7z x $1         ;; # require p7zip
        *.rar)      7z x $1         ;; # require p7zip
        *.iso)      7z x $1         ;; # require p7zip
        *.Z)        uncompress $1   ;;
        *)          echo "'$1' cannot be extracted" ;;
    esac
}

# Compress a file 
# TODO to improve to compress in any possible format
# TODO to improve to compress multiple files
compress() {
    local DATE="$(date +%Y%m%d-%H%M%S)"
    tar cvzf "$DATE.tar.gz" "$@"
}

# Download playlist videos (minimal)
ytdlplaylist() {
  if [ -z "$1" ]; then
    echo "Usage: ytdlplaylist <playlist-URL> [extra yt-dlp args...]"
    return 1
  fi
  local url="$1"; shift
  yt-dlp \
    --ignore-config \
    --cookies-from-browser firefox \
    --yes-playlist \
    -f "bv*+ba/b" \
    --merge-output-format mkv \
    -o "%(playlist_index)03d - %(title)s.%(ext)s" \
    "$@" \
    -- "$url"
}

# Download a single video (minimal)
ytdlvideo() {
  if [ -z "$1" ]; then
    echo "Usage: ytdlvideo <video-URL> [extra yt-dlp args...]"
    return 1
  fi
  local url="$1"; shift
  yt-dlp \
    --ignore-config \
    --cookies-from-browser firefox \
    --no-playlist \
    -f "bv*+ba/b" \
    --merge-output-format mkv \
    -o "%(title)s.%(ext)s" \
    "$@" \
    -- "$url"
}

# Extract audio to MP3 (minimal)
ytdlaudio() {
  if [ -z "$1" ]; then
    echo "Usage: ytdlaudio <video-URL> [extra yt-dlp args...]"
    return 1
  fi
  local url="$1"; shift
  yt-dlp \
    --ignore-config \
    --cookies-from-browser firefox \
    --no-playlist \
    -f bestaudio \
    --extract-audio --audio-format mp3 --audio-quality 0 \
    -o "%(title)s.%(ext)s" \
    "$@" \
    -- "$url"
}

# Default: progress + warnings (no debug spam)
# Add --debug anywhere after the URL to turn on full verbose for that run
ytdlarchive() {
  if [ -z "$1" ]; then
    echo "Usage: ytdlarchive <channel-or-playlist-URL> [extra yt-dlp args... | --debug]"
    return 1
  fi

  local url="$1"; shift

  # Peek for an optional --debug flag in user args
  local debug=0
  for arg in "$@"; do
    [ "$arg" = "--debug" ] && debug=1
  done
  # Strip our --debug from the args passed to yt-dlp
  # (safe even if it's not present)
  set -- ${@/--debug/}

  # Resolve uploader id
  local uploader_id
  uploader_id="$(yt-dlp --cookies-from-browser firefox --print "%(uploader_id|uploader)s" -- "$url" | head -n1)" || return 2
  [ -z "$uploader_id" ] && { echo "Could not resolve uploader id."; return 2; }

  # Paths
  local base="$HOME/yt-archives/${uploader_id}"
  local arch="${base}.txt"
  local alllog="${base}.log"
  local runlog="${base}.run.$(date +%Y%m%d-%H%M%S).log"
  local faillog="${base}.failures.log"
  local errraw="${base}.errors.raw.log"

  mkdir -p "$HOME/yt-archives"
  [ -e "$faillog" ] || : > "$faillog"
  [ -e "$errraw" ]  || : > "$errraw"

  echo "[ytdlarchive] URL: $url"
  echo "[ytdlarchive] Uploader: $uploader_id"
  echo "[ytdlarchive] Archive: $arch"
  echo "[ytdlarchive] Logs: $runlog (and $alllog)"

  # Build common flags: keep progress even through pipes, print each update on a new line
  # (no --verbose by default; add it only if --debug was requested)
  PYTHONUNBUFFERED=1 yt-dlp \
    "$@" \
    --download-archive "$arch" \
    --progress --newline \
    $( [ $debug -eq 1 ] && echo --verbose ) \
    -- "$url" 2>&1 | tee -a "$alllog" "$runlog"

  local code=${PIPESTATUS[0]:-${pipestatus[1]}}

  # Best-effort retry list from this run
  grep -oE '\[youtube\] [A-Za-z0-9_-]{11}' "$runlog" \
    | awk '{print "https://www.youtube.com/watch?v="$2}' \
    | sort -u >> "$faillog"
  grep -E '^ERROR:' "$runlog" >> "$errraw"

  echo "[ytdlarchive] Failures (retry list): $faillog"
  return "$code"
}

# Pull cheatsheet from cheat.sh
cheat() {
    curl cheat.sh/$1
}

# Trash management helper functions
trash-clean() {
    local days=${1:-7}
    echo "Emptying trash older than $days days..."
    if command -v trash-empty >/dev/null 2>&1; then
        trash-empty "$days"
    else
        echo "trash-empty command not found"
    fi
}

# Show trash size
trash-size() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        du -sh ~/.Trash 2>/dev/null || echo "Trash is empty"
    else
        du -sh ~/.local/share/Trash 2>/dev/null || echo "Trash is empty"
    fi
}

# Quick trash status
trash-status() {
    echo "=== Trash Status ==="
    trash-size
    echo ""
    echo "Recent items:"
    if command -v trash-list >/dev/null 2>&1; then
        trash-list | head -5
    else
        echo "trash-list command not found"
    fi
}

