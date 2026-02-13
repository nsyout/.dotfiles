#!/usr/bin/env bash

dot_git_setup() {
	local git_name=""
	local git_email=""
	local default_branch="main"
	local signing_key=""
	local enable_signing=""
	local jj_name=""
	local jj_email=""
	local sync_jj_identity=false
	local assume_yes=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--name)
			shift
			git_name="${1:-}"
			;;
		--email)
			shift
			git_email="${1:-}"
			;;
		--default-branch)
			shift
			default_branch="${1:-main}"
			;;
		--signing-key)
			shift
			signing_key="${1:-}"
			;;
		--enable-signing)
			enable_signing="true"
			;;
		--disable-signing)
			enable_signing="false"
			;;
		--jj-name)
			shift
			jj_name="${1:-}"
			;;
		--jj-email)
			shift
			jj_email="${1:-}"
			;;
		--sync-jj-identity)
			sync_jj_identity=true
			;;
		--yes)
			assume_yes=true
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot git setup [options]

Options:
  --name <name>
  --email <email>
  --default-branch <branch>
  --signing-key <public-key-path>
  --enable-signing | --disable-signing
  --sync-jj-identity
  --jj-name <name>
  --jj-email <email>
  --yes
EOF
			return 0
			;;
		*)
			error "Unknown option for dot git setup: $1"
			return 1
			;;
		esac
		shift
	done

	step "Configuring Git"

	if ! command_exists git; then
		error "git not found"
		return 1
	fi

	if [[ -z "$git_name" && "$assume_yes" != "true" ]]; then
		read -r -p "Git user name (leave blank to skip): " git_name
	fi

	if [[ -n "$git_name" ]]; then
		git config --global user.name "$git_name"
		info "Set git user.name"
	else
		info "Skipped git user.name"
	fi

	if [[ -z "$git_email" && "$assume_yes" != "true" ]]; then
		read -r -p "Git email (leave blank to skip): " git_email
	fi

	if [[ -n "$git_email" ]]; then
		git config --global user.email "$git_email"
		info "Set git user.email"
	else
		info "Skipped git user.email"
	fi

	git config --global init.defaultBranch "$default_branch"
	info "Set git init.defaultBranch to '$default_branch'"

	local ignore_file="$HOME/.config/git/ignore"
	if [[ -f "$ignore_file" ]]; then
		git config --global core.excludesfile "$ignore_file"
		info "Set git core.excludesfile to '$ignore_file'"
	fi

	local managed_git_config="$HOME/.config/git/config"
	if [[ -f "$managed_git_config" ]]; then
		if ! git config --global --get-all include.path | grep -Fxq "$managed_git_config"; then
			git config --global --add include.path "$managed_git_config"
			info "Added git include.path '$managed_git_config'"
		else
			info "git include.path already contains '$managed_git_config'"
		fi
	fi

	if [[ "$enable_signing" == "true" ]]; then
		if [[ -z "$signing_key" ]]; then
			signing_key="$HOME/.ssh/personal_primary.pub"
		fi
		git config --global gpg.format ssh
		git config --global user.signingKey "$signing_key"
		git config --global commit.gpgSign true
		git config --global tag.gpgSign true
		info "Enabled SSH commit/tag signing with '$signing_key'"
	elif [[ "$enable_signing" == "false" ]]; then
		git config --global --unset-all commit.gpgSign >/dev/null 2>&1 || true
		git config --global --unset-all tag.gpgSign >/dev/null 2>&1 || true
		info "Disabled enforced commit/tag signing"
	elif [[ -n "$signing_key" ]]; then
		git config --global gpg.format ssh
		git config --global user.signingKey "$signing_key"
		info "Set SSH signing key to '$signing_key'"
	fi

	if [[ "$sync_jj_identity" == "true" || -n "$jj_name" || -n "$jj_email" ]]; then
		if command_exists jj; then
			if [[ -z "$jj_name" && -n "$git_name" ]]; then
				jj_name="$git_name"
			fi
			if [[ -z "$jj_email" && -n "$git_email" ]]; then
				jj_email="$git_email"
			fi

			if [[ -n "$jj_name" ]]; then
				jj config set --user user.name "$jj_name"
				info "Set jj user.name"
			fi
			if [[ -n "$jj_email" ]]; then
				jj config set --user user.email "$jj_email"
				info "Set jj user.email"
			fi

			if [[ -z "$jj_name" && -z "$jj_email" ]]; then
				warn "jj identity sync requested, but no identity values were provided"
			fi
		else
			warn "jj not found, skipping jj identity setup"
		fi
	fi
}

dot_git_status() {
	step "Git configuration status"

	if ! command_exists git; then
		error "git not found"
		return 1
	fi

	local name email branch excludes include_paths signing_key gpg_format commit_sign tag_sign
	name="$(git config --global --get user.name || true)"
	email="$(git config --global --get user.email || true)"
	branch="$(git config --global --get init.defaultBranch || true)"
	excludes="$(git config --global --get core.excludesfile || true)"
	include_paths="$(git config --global --get-all include.path || true)"
	signing_key="$(git config --global --get user.signingKey || true)"
	gpg_format="$(git config --global --get gpg.format || true)"
	commit_sign="$(git config --global --get commit.gpgSign || true)"
	tag_sign="$(git config --global --get tag.gpgSign || true)"

	printf "user.name: %s\n" "${name:-<unset>}"
	printf "user.email: %s\n" "${email:-<unset>}"
	printf "init.defaultBranch: %s\n" "${branch:-<unset>}"
	printf "core.excludesfile: %s\n" "${excludes:-<unset>}"
	printf "gpg.format: %s\n" "${gpg_format:-<unset>}"
	printf "user.signingKey: %s\n" "${signing_key:-<unset>}"
	printf "commit.gpgSign: %s\n" "${commit_sign:-<unset>}"
	printf "tag.gpgSign: %s\n" "${tag_sign:-<unset>}"
	printf "include.path:\n%s\n" "${include_paths:-<unset>}"
}

dot_git_signing_status() {
	step "Git signing status"
	printf "gpg.format: %s\n" "$(git config --global --get gpg.format || printf '<unset>')"
	printf "user.signingKey: %s\n" "$(git config --global --get user.signingKey || printf '<unset>')"
	printf "commit.gpgSign: %s\n" "$(git config --global --get commit.gpgSign || printf '<unset>')"
	printf "tag.gpgSign: %s\n" "$(git config --global --get tag.gpgSign || printf '<unset>')"
}

dot_git_signing_enable() {
	local key_path="${1:-$HOME/.ssh/personal_primary.pub}"
	git config --global gpg.format ssh
	git config --global user.signingKey "$key_path"
	git config --global commit.gpgSign true
	git config --global tag.gpgSign true
	info "Enabled SSH commit/tag signing with '$key_path'"
}

dot_git_signing_disable() {
	git config --global --unset-all commit.gpgSign >/dev/null 2>&1 || true
	git config --global --unset-all tag.gpgSign >/dev/null 2>&1 || true
	info "Disabled enforced commit/tag signing"
}

dot_cmd_git_signing() {
	local action="${1:-status}"
	shift || true

	case "$action" in
	status)
		dot_git_signing_status
		;;
	enable)
		dot_git_signing_enable "$@"
		;;
	disable)
		dot_git_signing_disable
		;;
	key)
		if [[ -z "${1:-}" ]]; then
			error "Usage: dot git signing key <public-key-path>"
			return 1
		fi
		git config --global gpg.format ssh
		git config --global user.signingKey "$1"
		info "Set SSH signing key to '$1'"
		;;
	-h | --help | help)
		cat <<'EOF'
Usage: dot git signing <status|enable|disable|key>

Commands:
  status              Show current signing configuration
  enable [key-path]   Enable commit and tag signing (default: ~/.ssh/personal_primary.pub)
  disable             Disable enforced commit/tag signing
  key <path>          Set SSH signing key path
EOF
		;;
	*)
		error "Unknown git signing action: $action"
		return 1
		;;
	esac
}

dot_cmd_git() {
	local action="${1:-help}"
	shift || true

	case "$action" in
	setup)
		dot_git_setup "$@"
		;;
	status)
		dot_git_status
		;;
	signing)
		dot_cmd_git_signing "$@"
		;;
	-h | --help | help)
		cat <<'EOF'
Usage: dot git <command>

Commands:
  setup   Configure global git identity and defaults
  status  Show current global git identity and defaults
  signing Manage git signing defaults and key path
EOF
		;;
	*)
		error "Unknown git action: $action"
		return 1
		;;
	esac
}
