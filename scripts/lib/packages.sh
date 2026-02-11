#!/usr/bin/env bash

dot_packages_failed_state_file() {
	local profile="$1"
	local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
	printf "%s\n" "$state_home/dot/failed-manifests-$profile"
}

dot_packages_manifest_files() {
	local profile="$1"
	local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"

	local base_manifest
	if [[ -f "$dotfiles_dir/Brewfile.base" ]]; then
		base_manifest="$dotfiles_dir/Brewfile.base"
	else
		base_manifest="$dotfiles_dir/Brewfile"
	fi

	[[ -f "$base_manifest" ]] && printf "%s\n" "$base_manifest"

	case "$profile" in
	personal)
		[[ -f "$dotfiles_dir/Brewfile.personal" ]] && printf "%s\n" "$dotfiles_dir/Brewfile.personal"
		;;
	work)
		[[ -f "$dotfiles_dir/Brewfile.work" ]] && printf "%s\n" "$dotfiles_dir/Brewfile.work"
		;;
	base) ;;
	*)
		warn "Unknown profile '$profile'; using base manifests only"
		;;
	esac
}

dot_packages_target_manifest_for_profile() {
	local profile="$1"
	local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"

	case "$profile" in
	base) printf "%s\n" "$dotfiles_dir/Brewfile" ;;
	personal) printf "%s\n" "$dotfiles_dir/Brewfile.personal" ;;
	work) printf "%s\n" "$dotfiles_dir/Brewfile.work" ;;
	*)
		error "Unknown profile '$profile'"
		return 1
		;;
	esac
}

dot_packages_manifest_has_entry() {
	local manifest="$1"
	local entry_type="$2"
	local package_name="$3"

	grep -Eq "^[[:space:]]*${entry_type}[[:space:]]+\"${package_name}\"" "$manifest"
}

dot_packages_add_entry() {
	local profile="$1"
	local package_name="$2"
	local entry_type="${3:-brew}"

	local manifest
	manifest="$(dot_packages_target_manifest_for_profile "$profile")" || return 1

	if [[ ! -f "$manifest" ]]; then
		touch "$manifest"
	fi

	if dot_packages_manifest_has_entry "$manifest" "$entry_type" "$package_name"; then
		warn "$entry_type '$package_name' already exists in $(basename "$manifest")"
		return 0
	fi

	printf "\n%s \"%s\"\n" "$entry_type" "$package_name" >>"$manifest"
	info "Added $entry_type '$package_name' to $(basename "$manifest")"
}

dot_packages_remove_entry() {
	local profile="$1"
	local package_name="$2"
	local entry_type="${3:-brew}"

	local manifest
	manifest="$(dot_packages_target_manifest_for_profile "$profile")" || return 1

	if [[ ! -f "$manifest" ]]; then
		warn "Manifest not found: $manifest"
		return 1
	fi

	if ! dot_packages_manifest_has_entry "$manifest" "$entry_type" "$package_name"; then
		warn "$entry_type '$package_name' not found in $(basename "$manifest")"
		return 0
	fi

	local temp_file
	temp_file="$(mktemp)"
	awk -v t="$entry_type" -v p="$package_name" '
		BEGIN { pattern = "^[[:space:]]*" t "[[:space:]]+\"" p "\"" }
		$0 ~ pattern { next }
		{ print }
	' "$manifest" >"$temp_file"
	mv "$temp_file" "$manifest"

	info "Removed $entry_type '$package_name' from $(basename "$manifest")"
}

dot_packages_list_entries() {
	local profile="$1"
	local show_type="${2:-all}"

	local manifest
	while IFS= read -r manifest; do
		[[ -z "$manifest" ]] && continue
		info "Manifest: $(basename "$manifest")"
		awk -v mode="$show_type" '
			/^[[:space:]]*brew[[:space:]]+"/ {
				if (mode == "all" || mode == "brew") print "  brew  " $2
			}
			/^[[:space:]]*cask[[:space:]]+"/ {
				if (mode == "all" || mode == "cask") print "  cask  " $2
			}
			/^[[:space:]]*mas[[:space:]]+"/ {
				if (mode == "all" || mode == "mas") print "  mas   " $2
			}
		' "$manifest"
	done < <(dot_packages_manifest_files "$profile")
}

dot_packages_sync() {
	local profile="$1"
	local failed_state_file
	failed_state_file="$(dot_packages_failed_state_file "$profile")"
	mkdir -p "$(dirname "$failed_state_file")"
	: >"$failed_state_file"

	if ! command_exists brew; then
		warn "Homebrew not installed, skipping package sync"
		return 0
	fi

	local manifest
	local found_any=false
	while IFS= read -r manifest; do
		[[ -z "$manifest" ]] && continue
		found_any=true
		info "Syncing packages from $(basename "$manifest")..."
		if ! brew bundle --file="$manifest"; then
			warn "Some packages failed for $(basename "$manifest")"
			printf "%s\n" "$manifest" >>"$failed_state_file"
		fi
	done < <(dot_packages_manifest_files "$profile")

	if [[ "$found_any" != "true" ]]; then
		warn "No Brewfile manifests found"
		return 0
	fi

	if [[ -s "$failed_state_file" ]]; then
		warn "Some manifests failed. Retry with: dot retry-failed --profile $profile"
	else
		rm -f "$failed_state_file"
	fi
}

dot_packages_check() {
	local profile="$1"

	if ! command_exists brew; then
		warn "Homebrew not installed"
		return 1
	fi

	local manifest
	while IFS= read -r manifest; do
		[[ -z "$manifest" ]] && continue
		info "Checking packages in $(basename "$manifest")..."
		brew bundle check --file="$manifest" || warn "Drift detected for $(basename "$manifest")"
	done < <(dot_packages_manifest_files "$profile")
}

dot_packages_cleanup() {
	local profile="$1"

	if ! command_exists brew; then
		warn "Homebrew not installed, skipping cleanup"
		return 0
	fi

	local manifest
	while IFS= read -r manifest; do
		[[ -z "$manifest" ]] && continue
		info "Cleaning packages not in $(basename "$manifest")..."
		brew bundle cleanup --file="$manifest" || warn "Cleanup reported issues for $(basename "$manifest")"
	done < <(dot_packages_manifest_files "$profile")
}

dot_packages_update() {
	local profile="$1"

	if ! command_exists brew; then
		warn "Homebrew not installed"
		return 1
	fi

	step "Updating Homebrew"
	brew update
	brew upgrade
	dot_packages_sync "$profile"
	brew cleanup --prune=all || warn "Homebrew cleanup reported issues"
}

dot_packages_retry_failed() {
	local profile="$1"
	local failed_state_file
	failed_state_file="$(dot_packages_failed_state_file "$profile")"

	if ! command_exists brew; then
		warn "Homebrew not installed"
		return 1
	fi

	if [[ ! -f "$failed_state_file" ]] || [[ ! -s "$failed_state_file" ]]; then
		info "No failed manifests to retry for profile '$profile'"
		return 0
	fi

	step "Retrying failed manifests"

	local retry_temp
	retry_temp="$(mktemp)"

	local manifest
	while IFS= read -r manifest; do
		[[ -z "$manifest" ]] && continue
		if [[ ! -f "$manifest" ]]; then
			warn "Manifest missing, keeping in retry list: $manifest"
			printf "%s\n" "$manifest" >>"$retry_temp"
			continue
		fi

		info "Retrying $(basename "$manifest")..."
		if ! brew bundle --file="$manifest"; then
			warn "Still failing: $(basename "$manifest")"
			printf "%s\n" "$manifest" >>"$retry_temp"
		fi
	done <"$failed_state_file"

	if [[ -s "$retry_temp" ]]; then
		mv "$retry_temp" "$failed_state_file"
		warn "Retry completed with remaining failures"
		return 1
	fi

	rm -f "$retry_temp" "$failed_state_file"
	info "Retry completed successfully"
}
