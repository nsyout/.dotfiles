#!/usr/bin/env bash

dot_stow_manifest_files() {
	local profile="$1"
	local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"

	local base_manifest="$dotfiles_dir/stow-manifest.base"
	[[ -f "$base_manifest" ]] && printf "%s\n" "$base_manifest"

	case "$profile" in
	personal)
		[[ -f "$dotfiles_dir/stow-manifest.personal" ]] && printf "%s\n" "$dotfiles_dir/stow-manifest.personal"
		;;
	work)
		[[ -f "$dotfiles_dir/stow-manifest.work" ]] && printf "%s\n" "$dotfiles_dir/stow-manifest.work"
		;;
	base) ;;
	*)
		warn "Unknown profile '$profile', using base stow manifest only"
		;;
	esac
}

dot_stow_profile_packages() {
	local profile="$1"
	local manifest
	while IFS= read -r manifest; do
		[[ -z "$manifest" ]] && continue
		while IFS= read -r line; do
			line="${line%%#*}"
			line="${line%%$'\r'}"
			[[ -z "$line" ]] && continue
			printf "%s\n" "$line"
		done <"$manifest"
	done < <(dot_stow_manifest_files "$profile")
}

dot_stow_apply() {
	local profile="$1"
	local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"

	if ! command_exists stow; then
		error "GNU Stow is not installed"
		return 1
	fi

	local previous_dir
	previous_dir="$(pwd)"
	cd "$dotfiles_dir" || return 1

	step "Deploying dotfiles (profile: $profile)"

	info "Deploying root-level configs..."
	stow --delete --target="$HOME" --no-folding --ignore='^\.config' . 2>/dev/null || true

	if ! stow --target="$HOME" --no-folding --ignore='^\.config' -v . 2>/dev/null; then
		warn "Conflicts detected in root-level configs"
		read -r -p "Override existing root-level files? (y/N): " choice
		if [[ "$choice" =~ ^[Yy]$ ]]; then
			stow --target="$HOME" --no-folding --ignore='^\.config' --override='.*' -v . || warn "Failed to deploy some root-level configs"
		else
			warn "Skipping root-level config deployment"
		fi
	fi

	mkdir -p "$HOME/.config"

	local package
	while IFS= read -r package; do
		[[ -z "$package" ]] && continue
		if [[ ! -d ".config/$package" ]]; then
			continue
		fi

		local source_path target_path
		source_path="$dotfiles_dir/.config/$package"
		target_path="$HOME/.config/$package"

		info "Deploying .config/$package..."

		if [[ -L "$target_path" ]]; then
			local current_target
			current_target="$(readlink "$target_path")"
			if [[ "$current_target" == "$source_path" || "$current_target" == "../.dotfiles/.config/$package" ]]; then
				info "  ✓ $package deployed"
				continue
			fi
		fi

		if [[ -e "$target_path" || -L "$target_path" ]]; then
			warn "  Conflicts detected for $package"
			read -r -p "  Override existing $package files? (y/N): " choice
			if [[ ! "$choice" =~ ^[Yy]$ ]]; then
				warn "  ✗ Skipping $package"
				continue
			fi
			command rm -rf "$target_path"
		fi

		ln -s "$source_path" "$target_path"
		info "  ✓ $package deployed"
	done < <(dot_stow_profile_packages "$profile")

	cd "$previous_dir" || return 1
}
