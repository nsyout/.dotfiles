#!/usr/bin/env bash

dot_cmd_projects() {
	local action="${1:-help}"
	shift || true

	case "$action" in
	normalize)
		dot_projects_normalize "$@"
		;;
	-h | --help | help)
		cat <<'EOF'
Usage: dot projects <command>

Commands:
  normalize   Normalize ~/projects directory names to lowercase with compatibility symlinks
EOF
		;;
	*)
		error "Unknown projects action: $action"
		return 1
		;;
	esac
}

dot_projects_normalize() {
	local dry_run=false
	local assume_yes=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run)
			dry_run=true
			;;
		--yes)
			assume_yes=true
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot projects normalize [--dry-run] [--yes]

This command normalizes mixed-case ~/projects directories:
  Forks -> forks
  Playground -> playground
  Repos -> repos

It preserves compatibility by creating symlinks from old names to new names.
EOF
			return 0
			;;
		*)
			error "Unknown option for dot projects normalize: $1"
			return 1
			;;
		esac
		shift
	done

	local projects_dir="$HOME/projects"
	local mappings=("Forks:forks" "Playground:playground" "Repos:repos")

	is_case_only_pair() {
		local first="$1"
		local second="$2"
		local first_lower second_lower
		first_lower="$(printf "%s" "$first" | tr '[:upper:]' '[:lower:]')"
		second_lower="$(printf "%s" "$second" | tr '[:upper:]' '[:lower:]')"
		[[ "$first_lower" == "$second_lower" && "$first" != "$second" ]]
	}

	normalize_case_only_name() {
		local dir="$1"
		local from_name="$2"
		local to_name="$3"

		local from_path="$dir/$from_name"
		local to_path="$dir/$to_name"
		local temp_name="__dot_tmp_${to_name}_$RANDOM"
		local temp_path="$dir/$temp_name"

		if [[ "$dry_run" == "true" ]]; then
			info "Would case-normalize $from_name -> $to_name via temporary rename"
			return 0
		fi

		if [[ "$assume_yes" != "true" ]]; then
			read -r -p "Case-normalize '$from_name' to '$to_name'? [Y/n] " -n 1 choice
			echo
			if [[ "$choice" =~ ^[Nn]$ ]]; then
				warn "Skipped $from_name"
				return 0
			fi
		fi

		mv "$from_path" "$temp_path"
		mv "$temp_path" "$to_path"
		info "Case-normalized $from_name -> $to_name"
	}

	if [[ "$dry_run" == "true" ]]; then
		step "Dry run"
		info "Would normalize directories under $projects_dir"
	fi

	mkdir -p "$projects_dir"

	local pair
	for pair in "${mappings[@]}"; do
		local old_name new_name old_path new_path
		old_name="${pair%%:*}"
		new_name="${pair##*:}"
		old_path="$projects_dir/$old_name"
		new_path="$projects_dir/$new_name"

		if is_case_only_pair "$old_name" "$new_name"; then
			if [[ -e "$old_path" ]]; then
				normalize_case_only_name "$projects_dir" "$old_name" "$new_name"
			else
				info "Already normalized casing: $new_name"
			fi
			continue
		fi

		if [[ "$dry_run" == "true" ]]; then
			if [[ -L "$old_path" ]]; then
				info "Already normalized: $old_name -> $new_name (symlink present)"
				continue
			fi

			if [[ -d "$old_path" && ! -e "$new_path" ]]; then
				info "Would move $old_path -> $new_path and create compatibility symlink"
			elif [[ -d "$old_path" && -d "$new_path" ]]; then
				warn "Both exist, would skip for manual merge: $old_path and $new_path"
			elif [[ ! -e "$old_path" && ! -e "$new_path" ]]; then
				info "Would create missing lowercase directory: $new_path"
			else
				info "No action needed for $old_name/$new_name"
			fi
			continue
		fi

		if [[ -L "$old_path" ]]; then
			info "Already normalized: $old_name -> $new_name"
			[[ -d "$new_path" ]] || mkdir -p "$new_path"
			continue
		fi

		if [[ -d "$old_path" && ! -e "$new_path" ]]; then
			if [[ "$assume_yes" != "true" ]]; then
				read -r -p "Move '$old_name' to '$new_name' and create symlink? [Y/n] " -n 1 choice
				echo
				if [[ "$choice" =~ ^[Nn]$ ]]; then
					warn "Skipped $old_name"
					continue
				fi
			fi

			mv "$old_path" "$new_path"
			ln -s "$new_name" "$old_path"
			info "Normalized $old_name -> $new_name"
			continue
		fi

		if [[ -d "$old_path" && -d "$new_path" ]]; then
			warn "Both directories exist; skipping manual merge: $old_path and $new_path"
			continue
		fi

		if [[ ! -e "$old_path" && ! -e "$new_path" ]]; then
			mkdir -p "$new_path"
			info "Created $new_path"
			continue
		fi

		if [[ ! -e "$old_path" && -e "$new_path" ]]; then
			info "Already lowercase: $new_name"
			continue
		fi
	done
}
