#!/usr/bin/env bash

dot_cmd_wallpaper() {
	local action="${1:-set}"
	shift || true

	local default_wallpaper="$HOME/.config/wallpapers/plane-wp.png"
	local wallpaper_path="$default_wallpaper"
	local dry_run=false

	if [[ "$action" == "set" ]]; then
		while [[ $# -gt 0 ]]; do
			case "$1" in
			--dry-run)
				dry_run=true
				;;
			-h | --help)
				cat <<'EOF'
Usage: dot wallpaper set [path] [--dry-run]
EOF
				return 0
				;;
			--*)
				error "Unknown option for dot wallpaper set: $1"
				return 1
				;;
			*)
				if [[ "$wallpaper_path" != "$default_wallpaper" ]]; then
					error "Only one wallpaper path is supported"
					return 1
				fi
				wallpaper_path="$1"
				;;
			esac
			shift
		done

		if [[ "$dry_run" == "true" ]]; then
			step "Dry run"
			info "Would set wallpaper to: $wallpaper_path"
			return 0
		fi

		if [[ ! -f "$wallpaper_path" ]]; then
			error "Wallpaper not found: $wallpaper_path"
			return 1
		fi

		step "Setting wallpaper"
		info "Using file: $wallpaper_path"
		osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$wallpaper_path\""
		info "Wallpaper set successfully"
		return 0
	fi

	if [[ "$action" == "-h" || "$action" == "--help" || "$action" == "help" ]]; then
		cat <<'EOF'
Usage: dot wallpaper set [path] [--dry-run]
EOF
		return 0
	fi

	error "Unknown wallpaper action: $action"
	return 1
}
