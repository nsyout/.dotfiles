#!/usr/bin/env bash

DOT_PROFILE_DEFAULT="base"

dot_profile_state_file() {
	local state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
	printf "%s\n" "$state_home/dot/profile"
}

dot_profile_is_valid() {
	case "$1" in
	base | personal | work)
		return 0
		;;
	*)
		return 1
		;;
	esac
}

dot_profile_set() {
	local requested_profile="$1"

	if [[ -z "$requested_profile" ]]; then
		error "Profile is required: base, personal, or work"
		return 1
	fi

	if ! dot_profile_is_valid "$requested_profile"; then
		error "Invalid profile '$requested_profile'. Use: base, personal, work"
		return 1
	fi

	local profile_file
	profile_file="$(dot_profile_state_file)"
	mkdir -p "$(dirname "$profile_file")"
	printf "%s\n" "$requested_profile" >"$profile_file"

	info "Active profile set to '$requested_profile'"
}

dot_profile_get() {
	local profile_file
	profile_file="$(dot_profile_state_file)"

	if [[ ! -f "$profile_file" ]]; then
		printf "%s\n" "$DOT_PROFILE_DEFAULT"
		return 0
	fi

	local profile
	profile="$(<"$profile_file")"

	if dot_profile_is_valid "$profile"; then
		printf "%s\n" "$profile"
		return 0
	fi

	warn "Invalid profile value in $profile_file; falling back to '$DOT_PROFILE_DEFAULT'"
	printf "%s\n" "$DOT_PROFILE_DEFAULT"
}

dot_profile_show() {
	local profile_file
	profile_file="$(dot_profile_state_file)"

	printf "Profile: %s\n" "$(dot_profile_get)"
	printf "State file: %s\n" "$profile_file"

	if [[ -f "$profile_file" ]]; then
		printf "State: present\n"
	else
		printf "State: missing (using default)\n"
	fi
}
