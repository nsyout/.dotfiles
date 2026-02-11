#!/usr/bin/env bash

dot_cmd_doctor() {
	local requested_profile=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--profile)
			shift
			requested_profile="${1:-}"
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot doctor [--profile <base|personal|work>]
EOF
			return 0
			;;
		*)
			error "Unknown option for dot doctor: $1"
			return 1
			;;
		esac
		shift
	done

	local profile
	if [[ -z "$requested_profile" ]]; then
		profile="$(dot_profile_get)"
	else
		if ! dot_profile_is_valid "$requested_profile"; then
			error "Invalid profile '$requested_profile'. Use: base, personal, work"
			return 1
		fi
		profile="$requested_profile"
	fi

	step "Running dot doctor (profile: $profile)"

	local issues=0
	local warnings=0

	if command_exists brew; then
		info "Homebrew: OK"
	else
		warn "Homebrew: missing"
		((issues++))
	fi

	if command_exists stow; then
		info "GNU Stow: OK"
	else
		warn "GNU Stow: missing"
		((issues++))
	fi

	if command_exists git; then
		info "Git: OK"
	else
		warn "Git: missing"
		((issues++))
	fi

	if command_exists nvim; then
		if nvim --headless "+lua print('doctor-nvim-ok')" +qa >/dev/null 2>&1; then
			info "Neovim: OK"
		else
			warn "Neovim: config failed to load"
			((warnings++))
		fi
	else
		warn "Neovim: missing"
		((warnings++))
	fi

	if command_exists tmux; then
		local tmux_conf="$DOTFILES_DIR/.config/tmux/tmux.conf"
		if [[ -f "$tmux_conf" ]]; then
			if tmux -f "$tmux_conf" -L dotdoctor new-session -d >/dev/null 2>&1; then
				tmux -L dotdoctor kill-server >/dev/null 2>&1 || true
				info "tmux: config OK"
			else
				warn "tmux: config check failed"
				((warnings++))
			fi
		else
			warn "tmux config missing: $tmux_conf"
			((warnings++))
		fi
	else
		warn "tmux: missing"
		((warnings++))
	fi

	if command_exists git; then
		local signing_key signing_enabled
		signing_key="$(git config --global --get user.signingKey || true)"
		signing_enabled="$(git config --global --get commit.gpgSign || true)"
		if [[ "$signing_enabled" == "true" ]]; then
			if [[ -n "$signing_key" ]]; then
				info "Git signing: enabled ($signing_key)"
			else
				warn "Git signing enabled but signing key unset"
				((warnings++))
			fi
		else
			warn "Git signing: not enforced"
			((warnings++))
		fi
	fi

	local dot_link="$HOME/.local/bin/dot"
	if [[ -L "$dot_link" ]]; then
		info "dot symlink: present ($dot_link)"
	else
		warn "dot symlink: missing ($dot_link)"
		((warnings++))
	fi

	local missing_packages=0
	local pkg
	while IFS= read -r pkg; do
		[[ -z "$pkg" ]] && continue
		if [[ -d "$DOTFILES_DIR/.config/$pkg" ]]; then
			continue
		fi
		warn "Missing stow package directory: .config/$pkg"
		((missing_packages++))
	done < <(dot_stow_profile_packages "$profile")

	if [[ $missing_packages -eq 0 ]]; then
		info "Stow package set for profile '$profile': OK"
	else
		((issues++))
	fi

	local missing_manifests=0
	local manifest
	while IFS= read -r manifest; do
		[[ -z "$manifest" ]] && continue
		if [[ -f "$manifest" ]]; then
			info "Package manifest: $(basename "$manifest")"
		else
			warn "Missing package manifest: $manifest"
			((missing_manifests++))
		fi
	done < <(dot_packages_manifest_files "$profile")

	if [[ $missing_manifests -gt 0 ]]; then
		((issues++))
	fi

	if command_exists brew; then
		local drift=0
		while IFS= read -r manifest; do
			[[ -z "$manifest" ]] && continue
			if [[ ! -f "$manifest" ]]; then
				continue
			fi

			if brew bundle check --file="$manifest" >/dev/null 2>&1; then
				info "Package drift: clean ($(basename "$manifest"))"
			else
				warn "Package drift detected ($(basename "$manifest"))"
				warn "Run: dot packages sync --profile $profile"
				((drift++))
			fi
		done < <(dot_packages_manifest_files "$profile")

		if [[ $drift -gt 0 ]]; then
			((warnings++))
		fi
	fi

	local managed_broken_links=0
	local managed_pkg
	while IFS= read -r managed_pkg; do
		[[ -z "$managed_pkg" ]] && continue
		local managed_path="$HOME/.config/$managed_pkg"
		if [[ ! -e "$managed_path" ]]; then
			continue
		fi

		local pkg_broken
		pkg_broken=$(find "$managed_path" -maxdepth 6 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ' || true)
		if [[ "$pkg_broken" != "0" ]]; then
			managed_broken_links=$((managed_broken_links + pkg_broken))
		fi
	done < <(dot_stow_profile_packages "$profile")

	if [[ "$managed_broken_links" == "0" ]]; then
		info "Broken symlinks in managed stow packages: none"
	else
		warn "Broken symlinks in managed stow packages: $managed_broken_links"
		((warnings++))
	fi

	if [[ "$profile" == "personal" ]]; then
		local machine
		machine=""
		if machine=$(dot_restic_machine_name 2>/dev/null); then
			:
		else
			machine=""
		fi

		if [[ -z "$machine" ]]; then
			warn "Restic checks skipped: unknown machine hostname"
			((warnings++))
		else
			local restic_keys_ok=true
			security find-generic-password -s "restic-password-$machine" -a "$USER" >/dev/null 2>&1 || restic_keys_ok=false
			security find-generic-password -s "restic-aws-access-key-$machine" -a "$USER" >/dev/null 2>&1 || restic_keys_ok=false
			security find-generic-password -s "restic-aws-secret-key-$machine" -a "$USER" >/dev/null 2>&1 || restic_keys_ok=false

			if [[ "$restic_keys_ok" == "true" ]]; then
				info "Restic keychain credentials: present"
			else
				warn "Restic keychain credentials: missing"
				warn "Run: dot restic setup"
				((warnings++))
			fi

			local launchd_dir="$HOME/Library/LaunchAgents"
			local installed_count=0
			installed_count=$(find "$launchd_dir" -maxdepth 1 -name 'com.resticprofile.*.plist' 2>/dev/null | wc -l | tr -d ' ' || true)

			local loaded_count=0
			loaded_count=$(launchctl list 2>/dev/null | grep -c 'com.resticprofile' || true)

			if [[ "$installed_count" == "0" ]]; then
				warn "Restic launch agents: not installed"
				warn "Run: dot restic setup"
				((warnings++))
			else
				info "Restic launch agents installed: $installed_count"
				if [[ "$loaded_count" == "0" ]]; then
					warn "Restic launch agents loaded: none"
					((warnings++))
				else
					info "Restic launch agents loaded: $loaded_count"
				fi
			fi
		fi
	else
		info "Restic checks skipped for profile '$profile'"
	fi

	if [[ $issues -eq 0 ]]; then
		if [[ $warnings -eq 0 ]]; then
			info "Doctor finished: no critical issues"
		else
			warn "Doctor finished: no critical issues, $warnings warning(s)"
		fi
	else
		warn "Doctor finished: $issues issue(s) detected"
		return 1
	fi
}
