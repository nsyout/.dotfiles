#!/usr/bin/env bash

dot_cmd_update() {
	local dry_run=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			dry_run=true
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot update [options]

Options:
  --dry-run
EOF
			return 0
			;;
		*)
			error "Unknown option for dot update: $1"
			return 1
			;;
		esac
		shift
	done

	local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
	local warnings=()
	local dotfiles_updated=false
	local brewfile_changed=false

	check_system_updates() {
		step "Checking for macOS system updates"

		local updates
		set +e
		updates=$(softwareupdate -l 2>&1)
		local exit_code=$?
		set -e

		if [[ $exit_code -ne 0 ]]; then
			warn "Unable to check for macOS updates"
			return 0
		fi

		if echo "$updates" | grep -q "No new software available"; then
			info "macOS is up to date"
		elif echo "$updates" | grep -q -E "^\s*\*.*"; then
			warn "macOS system updates are available:"
			echo "$updates" | grep -E "^\s*\*.*"
			echo
			warn "Run 'sudo softwareupdate -i -a' to install updates"
			warnings+=("macOS system updates available")
		else
			info "macOS is up to date"
		fi
	}

	update_dotfiles_repo() {
		step "Updating dotfiles repository"

		if [[ ! -d "$dotfiles_dir/.git" ]]; then
			error "Dotfiles directory is not a git repository: $dotfiles_dir"
			return 1
		fi

		local previous_dir
		previous_dir="$(pwd)"
		cd "$dotfiles_dir"

		if ! git diff-index --quiet HEAD -- 2>/dev/null; then
			warn "Uncommitted changes detected in dotfiles repository"
			git status --short
			echo
			read -p "Continue with update? (y/n) " -n 1 -r
			echo
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				cd "$previous_dir"
				return 0
			fi
		fi

		info "Fetching remote changes..."
		git fetch origin

		local branch
		branch=$(git rev-parse --abbrev-ref HEAD)
		local local_head remote_head
		local_head=$(git rev-parse HEAD)
		remote_head=$(git rev-parse "origin/$branch" 2>/dev/null) || remote_head=""

		if [[ -z "$remote_head" ]]; then
			warn "Could not find remote branch origin/$branch"
			cd "$previous_dir"
			return 0
		fi

		if [[ "$local_head" == "$remote_head" ]]; then
			info "Dotfiles already up to date"
			cd "$previous_dir"
			return 0
		fi

		if git diff --name-only "$local_head" "$remote_head" | grep -q "^Brewfile$"; then
			brewfile_changed=true
		fi

		info "Pulling latest changes..."
		if ! git pull origin "$branch"; then
			cd "$previous_dir"
			error "Failed to pull latest changes"
			return 1
		fi

		dotfiles_updated=true
		info "Repository updated successfully"
		cd "$previous_dir"
	}

	restow_dotfiles() {
		if [[ "$dotfiles_updated" != "true" ]]; then
			info "Skipping re-link (no dotfiles changes)"
			return 0
		fi

		step "Re-linking dotfiles"

		local previous_dir
		previous_dir="$(pwd)"
		cd "$dotfiles_dir"

		if ! command_exists stow; then
			cd "$previous_dir"
			error "GNU Stow is not installed"
			return 1
		fi

		info "Re-deploying root-level configs..."

		stow --delete --target="$HOME" --no-folding --ignore='^\.config' . 2>/dev/null || true

		if ! stow --target="$HOME" --no-folding --ignore='^\.config' -v . 2>/dev/null; then
			warn "Conflicts detected in root configs"
			read -r -p "Override existing files? (y/N): " choice
			if [[ "$choice" =~ ^[Yy]$ ]]; then
				stow --target="$HOME" --no-folding --ignore='^\.config' --override=".*" -v . || warn "Failed to deploy root configs"
			else
				warn "Skipping root configs"
			fi
		fi

		local configs=(aerospace ghostty git nvim tmux zsh)

		for config in "${configs[@]}"; do
			if [[ ! -d ".config/$config" ]]; then
				continue
			fi

			info "Re-deploying $config..."
			mkdir -p "$HOME/.config"

			stow --delete --target="$HOME/.config" --dir=".config" "$config" 2>/dev/null || true

			if stow --target="$HOME/.config" --dir=".config" -v "$config" 2>/dev/null; then
				info "  ✓ $config updated"
			else
				warn "  Conflicts detected in $config"
				read -r -p "  Override existing $config files? (y/N): " choice

				if [[ "$choice" =~ ^[Yy]$ ]]; then
					if stow --target="$HOME/.config" --dir=".config" --override=".*" -v "$config"; then
						info "  ✓ $config updated with overrides"
					else
						cd "$previous_dir"
						error "  ✗ Failed to update $config"
						return 1
					fi
				else
					warn "  ✗ Skipping $config"
				fi
			fi
		done

		info "Dotfiles re-linking complete"
		cd "$previous_dir"
	}

	update_packages() {
		step "Updating Homebrew packages"

		if ! command_exists brew; then
			warn "Homebrew not installed, skipping package updates"
			return 0
		fi

		info "Updating Homebrew..."
		brew update || warn "Failed to update Homebrew"

		info "Upgrading installed packages..."
		brew upgrade || warn "Some packages failed to upgrade"

		if [[ "$brewfile_changed" == "true" && -f "$dotfiles_dir/Brewfile" ]]; then
			info "Brewfile changed, installing new packages..."
			local previous_dir
			previous_dir="$(pwd)"
			cd "$dotfiles_dir"
			brew bundle || warn "Some packages failed to install"
			cd "$previous_dir"
		fi

		info "Cleaning up Homebrew..."
		brew cleanup --prune=all || warn "Homebrew cleanup had issues"

		info "Checking Homebrew health..."
		if ! brew doctor; then
			warn "brew doctor found issues (see above)"
			warnings+=("Homebrew has issues - run 'brew doctor'")
		else
			info "Homebrew is healthy"
		fi
	}

	update_firefox() {
		local firefox_config="$dotfiles_dir/.config/firefox"
		local user_overrides="$firefox_config/user-overrides.js"
		local profiles_dir="$HOME/Library/Application Support/Firefox/Profiles"

		if [[ ! -d "/Applications/Firefox.app" ]]; then
			info "Firefox not installed, skipping"
			return 0
		fi

		if [[ ! -f "$user_overrides" ]]; then
			warn "Firefox user-overrides.js not found in dotfiles, skipping"
			return 0
		fi

		local profile_dir
		profile_dir=$(find "$profiles_dir" -maxdepth 1 -type d -name "*.default*" 2>/dev/null | head -1)

		if [[ -z "$profile_dir" ]]; then
			info "No Firefox profile found, skipping"
			return 0
		fi

		step "Updating Firefox configuration"
		info "Using profile: $(basename "$profile_dir")"

		info "Downloading latest arkenfox user.js..."
		local arkenfox_url="https://raw.githubusercontent.com/arkenfox/user.js/master/user.js"
		if ! curl -sL "$arkenfox_url" -o "$profile_dir/user.js"; then
			warn "Failed to download arkenfox user.js"
			return 0
		fi

		info "Applying user overrides from dotfiles..."
		cat "$user_overrides" >>"$profile_dir/user.js"

		info "Firefox configuration updated"
		info "Restart Firefox for changes to take effect"
	}

	reload_shell() {
		step "Reloading shell configuration"
		info "Shell configuration updated"
		info "Please restart your terminal or run: exec zsh"
	}

	cat <<EOF
╔══════════════════════════════════════════╗
║            DOT UPDATE                    ║
╚══════════════════════════════════════════╝
EOF

	if [[ "$dry_run" == "true" ]]; then
		step "Dry run"
		info "Would check macOS updates"
		info "Would fetch/pull latest dotfiles from git"
		info "Would re-deploy stow packages"
		info "Would run Homebrew update/upgrade/cleanup"
		info "Would refresh Firefox policies and user.js"
		info "Would print shell reload guidance"
		return 0
	fi

	if [[ "$(uname -s)" != "Darwin" ]]; then
		error "This command is for macOS only"
		return 1
	fi

	info "Starting dotfiles update..."

	check_system_updates
	update_dotfiles_repo || return 1
	restow_dotfiles || return 1
	update_packages
	update_firefox
	reload_shell

	echo
	printf "%b╔══════════════════════════════════════════╗%b\n" "$COLOR_GREEN" "$COLOR_RESET"
	printf "%b║      UPDATE COMPLETED SUCCESSFULLY!      ║%b\n" "$COLOR_GREEN" "$COLOR_RESET"
	printf "%b╚══════════════════════════════════════════╝%b\n" "$COLOR_GREEN" "$COLOR_RESET"
	echo

	if [[ ${#warnings[@]} -gt 0 ]]; then
		printf "%b⚠ ATTENTION REQUIRED:%b\n" "$COLOR_YELLOW" "$COLOR_RESET"
		for warning_msg in "${warnings[@]}"; do
			printf "  %b•%b %s\n" "$COLOR_YELLOW" "$COLOR_RESET" "$warning_msg"
		done
		echo

		if [[ " ${warnings[*]} " =~ "macOS system updates available" ]]; then
			printf "%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n" "$COLOR_YELLOW" "$COLOR_RESET"
			printf "%b  UPDATE YOUR MAC!%b\n" "$COLOR_YELLOW" "$COLOR_RESET"
			printf "%b  Run: sudo softwareupdate -i -a%b\n" "$COLOR_YELLOW" "$COLOR_RESET"
			printf "%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n" "$COLOR_YELLOW" "$COLOR_RESET"
			echo
		fi
	else
		info "✓ Everything is up to date!"
	fi

	info "Restart your terminal if you see any issues"
}
