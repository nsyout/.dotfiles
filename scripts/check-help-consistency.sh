#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOT_CMD="$ROOT_DIR/dot"

if [[ ! -x "$DOT_CMD" ]]; then
	echo "[help-check] dot command not found or not executable: $DOT_CMD" >&2
	exit 1
fi

top_help="$($DOT_CMD help)"

require_snippet() {
	local snippet="$1"
	if ! grep -Fq "$snippet" <<<"$top_help"; then
		echo "[help-check] missing from top-level help:" >&2
		echo "  $snippet" >&2
		return 1
	fi
}

extract_main_commands() {
	awk '
    /^main\(\) \{/ { in_main = 1; next }
    in_main && /^\}/ { in_main = 0 }
    !in_main { next }

    /^[[:space:]]*[A-Za-z0-9-]+\)/ {
      cmd = $0
      gsub(/^[[:space:]]*/, "", cmd)
      sub(/\).*/, "", cmd)
      if (cmd != "profile" && cmd != "link" && cmd != "unlink" && cmd != "edit" && cmd != "qa" && cmd != "security" && cmd != "sast" && cmd != "bootstrap" && cmd != "init" && cmd != "update" && cmd != "stow" && cmd != "packages" && cmd != "retry-failed" && cmd != "doctor" && cmd != "restic" && cmd != "wallpaper" && cmd != "git" && cmd != "ssh" && cmd != "firefox" && cmd != "projects") {
        next
      }
      print cmd
    }
  ' "$DOT_CMD" | sort -u
}

while IFS= read -r cmd; do
	[[ -z "$cmd" ]] && continue
	require_snippet "dot $cmd"
done < <(extract_main_commands)

# Key canonical entries that should stay present in the top-level help.
require_snippet "dot bootstrap [--profile <base|personal|work>] [--yes] [--dry-run]"
require_snippet "dot init [--profile <base|personal|work>] [--yes] [--dry-run]"
require_snippet "dot update [--profile <base|personal|work>] [--dry-run]"
require_snippet "dot doctor [--profile <base|personal|work>]"
require_snippet "dot stow [--profile <base|personal|work>] [--dry-run]"
require_snippet "dot packages <sync|check|cleanup|list|update|add|remove> [--profile ...] [--dry-run]"
require_snippet "dot retry-failed [--profile ...] [--dry-run]"
require_snippet "dot git setup [--name <name>] [--email <email>] [--default-branch <branch>]"
require_snippet "dot git signing <status|enable [key-path]|disable|key <path>>"
require_snippet "dot ssh configure [--profile <base|personal|work>] [--dry-run] [--yes]"
require_snippet "dot ssh sync-yubikey-keys --slot <primary|backup> [--dry-run] [--yes]"
require_snippet "dot firefox sync [--dry-run] [--yes]"
require_snippet "dot restic setup [--machine <sys-ms|sys-mbp>] [--yes]"
require_snippet "dot wallpaper set [path] [--dry-run]"
require_snippet "dot projects normalize [--dry-run] [--yes]"

echo "[help-check] help output is consistent"
