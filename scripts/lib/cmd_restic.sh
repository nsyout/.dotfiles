#!/usr/bin/env bash

dot_restic_machine_name() {
	local short_hostname
	short_hostname="$(hostname -s)"

	case "$short_hostname" in
	sys-ms*)
		printf "sys-ms\n"
		;;
	sys-mbp*)
		printf "sys-mbp\n"
		;;
	*)
		error "Unknown machine: $short_hostname. Expected sys-ms or sys-mbp"
		return 1
		;;
	esac
}

dot_restic_require_personal_profile() {
	local active_profile
	active_profile="$(dot_profile_get)"
	if [[ "$active_profile" == "personal" ]]; then
		return 0
	fi

	error "dot restic setup is personal-only (current profile: $active_profile)"
	warn "Run: dot profile set personal"
	return 1
}

dot_restic_setup() {
	local assume_yes=false
	local machine_override=""
	local service_name="op-service-account-backups"

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--yes)
			assume_yes=true
			;;
		--machine)
			shift
			machine_override="${1:-}"
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot restic setup [options]

Options:
  --machine <sys-ms|sys-mbp>
  --yes
EOF
			return 0
			;;
		*)
			error "Unknown option for dot restic setup: $1"
			return 1
			;;
		esac
		shift
	done

	dot_restic_require_personal_profile || return 1

	local machine
	if [[ -n "$machine_override" ]]; then
		machine="$machine_override"
	else
		machine="$(dot_restic_machine_name)" || return 1
	fi

	step "Setting up restic credentials"
	info "Detected machine: $machine"

	if ! command_exists op; then
		error "1Password CLI (op) not found. Install with: brew install 1password-cli"
		return 1
	fi

	local skip_token=false
	if security find-generic-password -s "$service_name" -a "$USER" &>/dev/null; then
		warn "Service account token already exists in Keychain"
		if [[ "$assume_yes" == "true" ]]; then
			info "Keeping existing token (--yes)"
			skip_token=true
		else
			read -r -p "Overwrite token? [y/N] " -n 1 choice
			echo
			if [[ "$choice" =~ ^[Yy]$ ]]; then
				skip_token=false
			else
				skip_token=true
				info "Keeping existing token"
			fi
		fi
	fi

	if [[ "$skip_token" != "true" ]]; then
		local service_token
		echo -n "Enter Service Account token (ops_...): "
		read -r -s service_token
		echo

		if [[ -z "$service_token" ]]; then
			error "Token cannot be empty"
			return 1
		fi

		if [[ "$service_token" != ops_* ]]; then
			warn "Token does not start with 'ops_'"
			if [[ "$assume_yes" != "true" ]]; then
				read -r -p "Continue anyway? [y/N] " -n 1 token_choice
				echo
				if [[ ! "$token_choice" =~ ^[Yy]$ ]]; then
					error "Aborted"
					return 1
				fi
			fi
		fi

		security delete-generic-password -s "$service_name" -a "$USER" 2>/dev/null || true
		security add-generic-password -s "$service_name" -a "$USER" -w "$service_token"
		info "Stored service account token in Keychain"
	fi

	mkdir -p "$HOME/.local/share/resticprofile"

	local op_service_account_token
	op_service_account_token="$(security find-generic-password -s "$service_name" -a "$USER" -w)"
	export OP_SERVICE_ACCOUNT_TOKEN="$op_service_account_token"

	store_credential() {
		local keychain_service="$1"
		local op_path="$2"
		local description="$3"

		local value
		if ! value=$(op read "$op_path" 2>/dev/null); then
			warn "Failed to fetch: $description"
			return 1
		fi

		security delete-generic-password -s "$keychain_service" -a "$USER" 2>/dev/null || true
		security add-generic-password -s "$keychain_service" -a "$USER" -w "$value"
		info "Stored in Keychain: $description"
	}

	local items_ok=true
	store_credential "restic-password-$machine" "op://Restic/Restic Password - $machine/password" "Restic Password" || items_ok=false
	store_credential "restic-aws-access-key-$machine" "op://Restic/AWS Backup Credentials - $machine/AWS_ACCESS_KEY_ID" "AWS Access Key ID" || items_ok=false
	store_credential "restic-aws-secret-key-$machine" "op://Restic/AWS Backup Credentials - $machine/AWS_SECRET_ACCESS_KEY" "AWS Secret Access Key" || items_ok=false

	if [[ "$items_ok" != "true" ]]; then
		warn "Some items could not be read from 1Password"
		warn "Check vault access and item field names"
		return 1
	fi

	local launchd_src="$HOME/.config/resticprofile/launchd"
	local launchd_dst="$HOME/Library/LaunchAgents"
	local launchd_tmp

	if [[ ! -d "$launchd_src" ]]; then
		warn "Launchd directory not found: $launchd_src"
		warn "Credentials were stored, but schedules were not installed"
		return 0
	fi

	mkdir -p "$launchd_dst"
	launchd_tmp="$(mktemp -d)"
	trap 'rm -rf "$launchd_tmp"' RETURN

	local plist
	for plist in "$launchd_src"/*.plist; do
		[[ -e "$plist" ]] || continue
		local plist_name label
		plist_name="$(basename "$plist")"
		label="${plist_name%.plist}"

		launchctl unload "$launchd_dst/$plist_name" 2>/dev/null || true
		sed "s|__HOME__|$HOME|g" "$plist" >"$launchd_tmp/$plist_name"
		cp "$launchd_tmp/$plist_name" "$launchd_dst/$plist_name"
		launchctl load "$launchd_dst/$plist_name"
		info "Installed schedule: $label"
	done

	step "Restic setup complete"
	info "Credentials stored in Keychain for $machine"
	info "Test with: ~/.config/resticprofile/backup snapshots"
}

dot_restic_status() {
	step "Restic status"

	local machine
	machine="$(dot_restic_machine_name)" || return 1

	local keychain_ok=true
	security find-generic-password -s "restic-password-$machine" -a "$USER" >/dev/null 2>&1 || keychain_ok=false
	security find-generic-password -s "restic-aws-access-key-$machine" -a "$USER" >/dev/null 2>&1 || keychain_ok=false
	security find-generic-password -s "restic-aws-secret-key-$machine" -a "$USER" >/dev/null 2>&1 || keychain_ok=false

	if [[ "$keychain_ok" == "true" ]]; then
		info "Keychain credentials: present"
	else
		warn "Keychain credentials: missing (run 'dot restic setup')"
	fi

	local loaded
	loaded=$(launchctl list | grep -c "com.resticprofile" || true)
	if [[ "$loaded" -gt 0 ]]; then
		info "LaunchAgents loaded: $loaded"
	else
		warn "No restic launch agents loaded"
	fi
}

dot_cmd_restic() {
	local action="${1:-help}"
	shift || true

	case "$action" in
	setup)
		dot_restic_setup "$@"
		;;
	status)
		dot_restic_status
		;;
	-h | --help | help)
		cat <<'EOF'
Usage: dot restic <command>

Commands:
  setup   Configure keychain credentials and launchd schedules
  status  Show keychain and launchd status
EOF
		;;
	*)
		error "Unknown restic action: $action"
		return 1
		;;
	esac
}
