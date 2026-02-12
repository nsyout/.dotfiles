#!/usr/bin/env bash

dot_cmd_firefox() {
	local action="${1:-}"
	shift || true

	case "$action" in
	"" | -h | --help | help)
		cat <<'EOF'
Usage: dot firefox sync [options]

Options:
  --dry-run
  --yes
EOF
		return 0
		;;
	sync)
		dot_cmd_firefox_sync "$@"
		;;
	*)
		error "Unknown firefox action: $action"
		return 1
		;;
	esac
}

dot_cmd_firefox_sync() {
	local dry_run=false
	local assume_yes=false
	local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
	local firefox_config="$dotfiles_dir/.config/firefox"
	local user_overrides="$firefox_config/user-overrides.js"
	local profiles_dir="$HOME/Library/Application Support/Firefox/Profiles"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			dry_run=true
			;;
		--yes)
			assume_yes=true
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot firefox sync [options]

Options:
  --dry-run
  --yes
EOF
			return 0
			;;
		*)
			error "Unknown option for dot firefox sync: $1"
			return 1
			;;
		esac
		shift
	done

	if [[ ! -d "/Applications/Firefox.app" ]]; then
		warn "Firefox not installed, skipping"
		return 0
	fi

	if [[ ! -f "$user_overrides" ]]; then
		warn "Firefox overrides not found: $user_overrides"
		return 0
	fi

	local profile_dir
	profile_dir=$(find "$profiles_dir" -maxdepth 1 -type d -name "*.default*" 2>/dev/null | head -1)

	if [[ -z "$profile_dir" ]]; then
		warn "No Firefox profile found in $profiles_dir"
		return 0
	fi

	if [[ "$dry_run" == "true" ]]; then
		step "Dry run"
		info "Would update Firefox profile: $(basename "$profile_dir")"
		info "Would download latest arkenfox user.js"
		info "Would append overrides from: $user_overrides"
		return 0
	fi

	if [[ "$assume_yes" != "true" ]]; then
		warn "This will overwrite Firefox user.js for profile: $(basename "$profile_dir")"
		read -r -p "Continue? (y/N): " choice
		if [[ ! "$choice" =~ ^[Yy]$ ]]; then
			info "Firefox sync canceled"
			return 0
		fi
	fi

	step "Updating Firefox configuration"
	info "Using profile: $(basename "$profile_dir")"

	local arkenfox_url="https://raw.githubusercontent.com/arkenfox/user.js/master/user.js"
	if ! curl -fsSL "$arkenfox_url" -o "$profile_dir/user.js"; then
		error "Failed to download arkenfox user.js"
		return 1
	fi

	cat "$user_overrides" >>"$profile_dir/user.js"
	info "Firefox user.js updated successfully"
	info "Restart Firefox for changes to take effect"
}
