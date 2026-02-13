#!/usr/bin/env bash

dot_cmd_update() {
	local dry_run=false
	local requested_profile=""
	local profile=""
	local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
	local warnings=()
	local dotfiles_updated=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			dry_run=true
			;;
		--profile)
			shift
			requested_profile="${1:-}"
			if [[ -z "$requested_profile" ]]; then
				error "Usage: dot update [--dry-run] [--profile <base|personal|work>]"
				return 1
			fi
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot update [options]

Options:
  --dry-run
  --profile <base|personal|work>

Notes:
  - `dot update` is profile-aware for stow/package sync.
  - Package removal is explicit; run `dot packages cleanup` separately.
  - Firefox sync is explicit; run `dot firefox sync`.
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

	if [[ -n "$requested_profile" ]]; then
		if ! dot_profile_is_valid "$requested_profile"; then
			error "Invalid profile '$requested_profile'. Use: base, personal, work"
			return 1
		fi
		profile="$requested_profile"
	else
		profile="$(dot_profile_get)"
	fi

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

		if [[ ! -d "$dotfiles_dir/.git" && ! -d "$dotfiles_dir/.jj" ]]; then
			error "Dotfiles directory is not a git/jj repository: $dotfiles_dir"
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

		if [[ -d "$dotfiles_dir/.jj" ]] && command_exists jj; then
			info "Detected jj-managed repository"

			local before_head after_head
			before_head=$(jj -R "$dotfiles_dir" log -r @ --no-graph -T 'commit_id.shortest(12)' 2>/dev/null || true)

			info "Fetching remote changes via jj..."
			if ! jj -R "$dotfiles_dir" git fetch; then
				cd "$previous_dir"
				error "Failed to fetch latest changes via jj"
				return 1
			fi

			info "Rebasing working copy onto trunk() via jj..."
			if ! jj -R "$dotfiles_dir" rebase -d 'trunk()'; then
				cd "$previous_dir"
				error "Failed to rebase dotfiles via jj"
				return 1
			fi

			after_head=$(jj -R "$dotfiles_dir" log -r @ --no-graph -T 'commit_id.shortest(12)' 2>/dev/null || true)

			if [[ -n "$before_head" && -n "$after_head" && "$before_head" != "$after_head" ]]; then
				dotfiles_updated=true
				info "Repository updated successfully via jj"
			else
				info "Dotfiles already up to date"
			fi
		else
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

			info "Pulling latest changes..."
			if ! git pull origin "$branch"; then
				cd "$previous_dir"
				error "Failed to pull latest changes"
				return 1
			fi

			dotfiles_updated=true
			info "Repository updated successfully"
		fi
		cd "$previous_dir"
	}

	apply_profile_stow() {
		if [[ "$dotfiles_updated" != "true" ]]; then
			info "Skipping re-link (no dotfiles changes)"
			return 0
		fi

		step "Re-linking dotfiles (profile: $profile)"
		dot_stow_apply "$profile"
	}

	update_packages_for_profile() {
		step "Updating Homebrew and syncing packages (profile: $profile)"

		if ! command_exists brew; then
			warn "Homebrew not installed, skipping package updates"
			return 0
		fi

		info "Updating Homebrew..."
		brew update || warn "Failed to update Homebrew"

		info "Upgrading installed packages..."
		brew upgrade || warn "Some packages failed to upgrade"

		dot_packages_sync "$profile"

		if ! dot_packages_retry_failed "$profile"; then
			warnings+=("Some package manifests still failing - run 'dot retry-failed --profile $profile'")
		fi

		info "Cleaning Homebrew cache and old versions..."
		brew cleanup --prune=all || warn "Homebrew cleanup had issues"

		info "Checking Homebrew health..."
		if ! brew doctor; then
			warn "brew doctor found issues (see above)"
			warnings+=("Homebrew has issues - run 'brew doctor'")
		else
			info "Homebrew is healthy"
		fi

		info "Package removal is explicit; run 'dot packages cleanup --profile $profile' when desired"
	}

	cat <<EOF
╔══════════════════════════════════════════╗
║            DOT UPDATE                    ║
╚══════════════════════════════════════════╝
EOF

	if [[ "$dry_run" == "true" ]]; then
		step "Dry run"
		info "Profile: $profile"
		info "Would check macOS updates"
		info "Would update dotfiles repo (jj fetch+rebase when colocated; git fetch+pull otherwise)"
		info "Would re-deploy stow packages only if dotfiles changed"
		info "Would run Homebrew update/upgrade"
		info "Would run dot packages sync + retry-failed for profile '$profile'"
		info "Would run brew cleanup and brew doctor"
		info "Would not run package cleanup (explicit command)"
		info "Would not run Firefox sync (use: dot firefox sync)"
		return 0
	fi

	if [[ "$(uname -s)" != "Darwin" ]]; then
		error "This command is for macOS only"
		return 1
	fi

	info "Starting dotfiles update (profile: $profile)..."

	check_system_updates
	update_dotfiles_repo || return 1
	apply_profile_stow || return 1
	update_packages_for_profile
	dot_cmd_doctor

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

	info "Firefox sync is explicit: run 'dot firefox sync' when needed"
}
