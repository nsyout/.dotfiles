#!/usr/bin/env bash

dot_ssh_ssh_keygen_bin() {
	if [[ -x "/opt/homebrew/bin/ssh-keygen" ]]; then
		printf "%s\n" "/opt/homebrew/bin/ssh-keygen"
		return 0
	fi

	if command_exists ssh-keygen; then
		command -v ssh-keygen
		return 0
	fi

	error "ssh-keygen not found"
	return 1
}

dot_ssh_require_deps() {
	local missing=0

	if ! dot_ssh_ssh_keygen_bin >/dev/null 2>&1; then
		warn "Missing dependency: ssh-keygen"
		missing=1
	fi

	if ! command_exists ykman; then
		warn "Missing dependency: ykman"
		missing=1
	fi

	if [[ "$missing" -eq 1 ]]; then
		error "Install dependencies first (openssh, libfido2, ykman)"
		return 1
	fi
}

dot_ssh_configure() {
	local requested_profile=""
	local dry_run=false
	local assume_yes=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--profile)
			shift
			requested_profile="${1:-}"
			;;
		--dry-run)
			dry_run=true
			;;
		--yes)
			assume_yes=true
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot ssh configure [options]

Options:
  --profile <base|personal|work>
  --dry-run
  --yes
EOF
			return 0
			;;
		*)
			error "Unknown option for dot ssh configure: $1"
			return 1
			;;
		esac
		shift
	done

	local profile
	if [[ -n "$requested_profile" ]]; then
		if ! dot_profile_is_valid "$requested_profile"; then
			error "Invalid profile '$requested_profile'. Use: base, personal, work"
			return 1
		fi
		profile="$requested_profile"
	else
		profile="$(dot_profile_get)"
	fi

	local config_dir="$DOTFILES_DIR/.config/ssh"
	local base_template="$config_dir/config.base"
	local overlay_template="$config_dir/config.$profile"
	local target_dir="$HOME/.ssh"
	local target_file="$target_dir/config"
	local managed_begin="# >>> dot managed ssh begin"
	local managed_end="# <<< dot managed ssh end"

	if [[ ! -f "$base_template" ]]; then
		error "Missing SSH base template: $base_template"
		return 1
	fi

	if [[ ! -f "$overlay_template" ]]; then
		warn "Missing SSH profile template: $overlay_template"
		warn "Proceeding with base template only"
	fi

	if [[ "$dry_run" == "true" ]]; then
		step "Dry run"
		info "Would merge managed SSH block into ~/.ssh/config for profile '$profile'"
		info "Managed block markers: '$managed_begin' ... '$managed_end'"
		info "Base template: $(basename "$base_template")"
		[[ -f "$overlay_template" ]] && info "Overlay template: $(basename "$overlay_template")"
		return 0
	fi

	mkdir -p "$target_dir"

	local managed_tmp
	managed_tmp="$(mktemp)"
	{
		printf "%s\n" "$managed_begin"
		printf "# Managed by dot ssh configure (%s)\n\n" "$profile"
		cat "$base_template"
		if [[ -f "$overlay_template" ]]; then
			printf "\n"
			cat "$overlay_template"
		fi
		printf "\n%s\n" "$managed_end"
	} >"$managed_tmp"

	if [[ ! -f "$target_file" ]]; then
		cp "$managed_tmp" "$target_file"
		chmod 600 "$target_file"
		rm -f "$managed_tmp"
		info "Wrote ~/.ssh/config for profile '$profile'"
		return 0
	fi

	cp "$target_file" "$target_file.bak.$(date +%Y%m%d-%H%M%S)"

	local merged_tmp
	merged_tmp="$(mktemp)"

	if grep -Fq "$managed_begin" "$target_file" && grep -Fq "$managed_end" "$target_file"; then
		awk -v begin="$managed_begin" -v end="$managed_end" -v managed_file="$managed_tmp" '
			BEGIN { in_block = 0 }
			$0 == begin {
				while ((getline line < managed_file) > 0) print line
				close(managed_file)
				in_block = 1
				next
			}
			$0 == end {
				in_block = 0
				next
			}
			!in_block { print }
		' "$target_file" >"$merged_tmp"
	else
		if [[ "$assume_yes" != "true" ]]; then
			read -r -p "No managed block found in ~/.ssh/config. Append managed block? [Y/n] " -n 1 choice
			echo
			if [[ "$choice" =~ ^[Nn]$ ]]; then
				rm -f "$managed_tmp" "$merged_tmp"
				warn "Canceled"
				return 0
			fi
		fi

		cat "$target_file" >"$merged_tmp"
		printf "\n\n" >>"$merged_tmp"
		cat "$managed_tmp" >>"$merged_tmp"
	fi

	mv "$merged_tmp" "$target_file"
	rm -f "$managed_tmp"

	chmod 600 "$target_file"
	info "Updated managed SSH config block for profile '$profile'"
}

dot_ssh_sync_yubikey_keys() {
	local slot=""
	local dry_run=false
	local assume_yes=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--slot)
			shift
			slot="${1:-}"
			;;
		--dry-run)
			dry_run=true
			;;
		--yes)
			assume_yes=true
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot ssh sync-yubikey-keys [options]

Options:
  --slot <primary|backup>   Required: target key file set to update
  --dry-run
  --yes
EOF
			return 0
			;;
		*)
			error "Unknown option for dot ssh sync-yubikey-keys: $1"
			return 1
			;;
		esac
		shift
	done

	if [[ "$slot" != "primary" && "$slot" != "backup" ]]; then
		error "--slot is required and must be 'primary' or 'backup'"
		return 1
	fi

	dot_ssh_require_deps || return 1

	local ssh_keygen_bin
	ssh_keygen_bin="$(dot_ssh_ssh_keygen_bin)" || return 1

	local target_personal="$HOME/.ssh/personal_$slot"
	local target_work="$HOME/.ssh/work_$slot"

	if [[ "$dry_run" == "true" ]]; then
		step "Dry run"
		info "Would run: $ssh_keygen_bin -K"
		info "Would map id_ed25519_sk_rk_personal -> $target_personal"
		info "Would map id_ed25519_sk_rk_work -> $target_work"
		return 0
	fi

	mkdir -p "$HOME/.ssh"

	if [[ "$assume_yes" != "true" ]]; then
		read -r -p "Insert the $slot YubiKey and press Enter to continue... " _ignore
	fi

	step "Downloading resident keys from YubiKey"
	local temp_dir
	temp_dir="$(mktemp -d)"

	local previous_dir
	previous_dir="$(pwd)"
	cd "$temp_dir" || return 1

	if ! "$ssh_keygen_bin" -K; then
		cd "$previous_dir" || return 1
		rm -rf "$temp_dir"
		error "Failed to download resident keys"
		return 1
	fi

	local source_private source_public
	local target_private target_public

	for key_name in personal work; do
		source_private="id_ed25519_sk_rk_$key_name"
		source_public="id_ed25519_sk_rk_$key_name.pub"
		target_private="$HOME/.ssh/${key_name}_$slot"
		target_public="$HOME/.ssh/${key_name}_$slot.pub"

		if [[ ! -f "$source_private" ]] || [[ ! -f "$source_public" ]]; then
			warn "Missing downloaded key files for '$key_name' (expected $source_private)"
			continue
		fi

		if [[ -f "$target_private" && "$assume_yes" != "true" ]]; then
			read -r -p "Overwrite $target_private? [y/N] " -n 1 choice
			echo
			if [[ ! "$choice" =~ ^[Yy]$ ]]; then
				warn "Skipping $target_private"
				continue
			fi
		fi

		mv "$source_private" "$target_private"
		mv "$source_public" "$target_public"
		chmod 600 "$target_private"
		chmod 644 "$target_public"
		info "Installed $key_name $slot key pointers"
	done

	cd "$previous_dir" || return 1
	rm -rf "$temp_dir"

	info "YubiKey key sync complete for slot '$slot'"
}

dot_ssh_status() {
	step "SSH + YubiKey status"

	if command_exists ykman; then
		info "ykman: $(ykman --version 2>/dev/null || printf 'available')"
		if ykman list >/dev/null 2>&1; then
			info "YubiKey detected"
		else
			warn "No YubiKey detected"
		fi
	else
		warn "ykman not installed"
	fi

	local ssh_keygen_bin
	if ssh_keygen_bin="$(dot_ssh_ssh_keygen_bin 2>/dev/null)"; then
		info "ssh-keygen: $ssh_keygen_bin"
	else
		warn "ssh-keygen unavailable"
	fi

	local key_file
	for key_file in "$HOME/.ssh/personal_primary" "$HOME/.ssh/personal_backup" "$HOME/.ssh/work_primary" "$HOME/.ssh/work_backup"; do
		if [[ -f "$key_file" ]]; then
			info "Key pointer present: $key_file"
		else
			warn "Key pointer missing: $key_file"
		fi
	done

	if [[ -f "$HOME/.ssh/config" ]]; then
		info "SSH config present: ~/.ssh/config"
	else
		warn "SSH config missing: ~/.ssh/config (run: dot ssh configure)"
	fi
}

dot_cmd_ssh() {
	local action="${1:-help}"
	shift || true

	case "$action" in
	configure)
		dot_ssh_configure "$@"
		;;
	sync-yubikey-keys)
		dot_ssh_sync_yubikey_keys "$@"
		;;
	status)
		dot_ssh_status
		;;
	-h | --help | help)
		cat <<'EOF'
Usage: dot ssh <command>

Commands:
  configure          Write ~/.ssh/config from profile templates
  sync-yubikey-keys  Download resident keys from YubiKey and map pointer files
  status             Show dependency, YubiKey, and key pointer status
EOF
		;;
	*)
		error "Unknown ssh action: $action"
		return 1
		;;
	esac
}
