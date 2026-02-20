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
	local assume_yes="${2:-false}"
	local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
	local root_links=(
		".zshenv:.zshenv"
		".local/bin/dot:dot"
	)

	if ! command_exists stow; then
		error "GNU Stow is not installed"
		return 1
	fi

	local previous_dir
	previous_dir="$(pwd)"
	cd "$dotfiles_dir" || return 1

	step "Deploying dotfiles (profile: $profile)"

	info "Deploying root-level links..."
	local link_spec
	for link_spec in "${root_links[@]}"; do
		local link_name source_rel source_path target_path
		link_name="${link_spec%%:*}"
		source_rel="${link_spec#*:}"
		source_path="$dotfiles_dir/$source_rel"
		target_path="$HOME/$link_name"

		if [[ ! -e "$source_path" ]]; then
			warn "  Source missing, skipping: $source_rel"
			continue
		fi

		if [[ -L "$target_path" ]]; then
			local current_target
			current_target="$(readlink "$target_path")"
			if [[ "$current_target" == "$source_path" || "$current_target" == ".dotfiles/$source_rel" || "$current_target" == "../.dotfiles/$source_rel" ]]; then
				info "  ✓ $link_name deployed"
				continue
			fi
		fi

		if [[ -e "$target_path" || -L "$target_path" ]]; then
			warn "  Conflicts detected for $link_name"
			if [[ "$assume_yes" != "true" ]]; then
				local choice
				read -r -p "  Override existing $link_name? (y/N): " choice
				if [[ ! "$choice" =~ ^[Yy]$ ]]; then
					warn "  ✗ Skipping $link_name"
					continue
				fi
			else
				info "  Auto-overriding $link_name (--yes)"
			fi
			command rm -rf "$target_path"
		fi

		mkdir -p "$(dirname "$target_path")"
		ln -s "$source_path" "$target_path"
		info "  ✓ $link_name deployed"
	done

	local legacy_dot_link="$HOME/dot"
	if [[ -L "$legacy_dot_link" ]]; then
		local legacy_target
		legacy_target="$(readlink "$legacy_dot_link")"
		if [[ "$legacy_target" == "$dotfiles_dir/dot" || "$legacy_target" == ".dotfiles/dot" ]]; then
			command rm -f "$legacy_dot_link"
			info "  ✓ Removed legacy ~/dot symlink (now using ~/.local/bin/dot)"
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
			if [[ "$assume_yes" != "true" ]]; then
				read -r -p "  Override existing $package files? (y/N): " choice
				if [[ ! "$choice" =~ ^[Yy]$ ]]; then
					warn "  ✗ Skipping $package"
					continue
				fi
			else
				info "  Auto-overriding $package (--yes)"
			fi
			command rm -rf "$target_path"
		fi

		ln -s "$source_path" "$target_path"
		info "  ✓ $package deployed"
	done < <(dot_stow_profile_packages "$profile")

	cd "$previous_dir" || return 1
}
