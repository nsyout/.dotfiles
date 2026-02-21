#!/usr/bin/env bash

dot_cmd_init() {
	local assume_yes=false
	local dry_run=false
	local disable_firefox=false
	local disable_fonts=false
	local disable_dock=false
	local disable_git=false
	local explicit_profile=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--yes)
			assume_yes=true
			;;
		--dry-run)
			dry_run=true
			;;
		--no-firefox)
			disable_firefox=true
			;;
		--no-fonts)
			disable_fonts=true
			;;
		--no-dock)
			disable_dock=true
			;;
		--no-git)
			disable_git=true
			;;
		--profile)
			shift
			explicit_profile="${1:-}"
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot init [options]

Options:
  --profile <base|personal|work>
  --yes
  --dry-run
  --no-firefox
  --no-fonts
  --no-dock
  --no-git
EOF
			return 0
			;;
		*)
			error "Unknown option for dot init: $1"
			return 1
			;;
		esac
		shift
	done

	local profile
	if [[ -n "$explicit_profile" ]]; then
		if ! dot_profile_is_valid "$explicit_profile"; then
			error "Invalid profile '$explicit_profile'. Use: base, personal, work"
			return 1
		fi
		profile="$explicit_profile"
	else
		profile="$(dot_profile_get)"
	fi

	local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
	local backup_dir
	backup_dir="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

	install_dependencies() {
		step "Installing dependencies for macOS"

		if ! command_exists brew; then
			info "Installing Homebrew..."
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

			if [[ -d "/opt/homebrew" ]]; then
				eval "$(/opt/homebrew/bin/brew shellenv)"
			else
				eval "$(/usr/local/bin/brew shellenv)"
			fi
		fi

		info "Installing required tools..."
		brew install git stow fzf ripgrep bat zoxide starship neovim tmux || warn "Some required tools failed to install"
	}

	backup_configs() {
		step "Backing up existing configurations"

		local files_to_backup=(
			"$HOME/.zshrc"
			"$HOME/.zshenv"
			"$HOME/.bashrc"
			"$HOME/.bash_profile"
			"$HOME/.gitconfig"
			"$HOME/.config"
		)

		local backed_up=0
		local file
		for file in "${files_to_backup[@]}"; do
			if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
				mkdir -p "$backup_dir"
				cp -r "$file" "$backup_dir/" 2>/dev/null || true
				info "Backed up: $(basename "$file")"
				((backed_up++))
			fi
		done

		if [[ $backed_up -gt 0 ]]; then
			info "Backed up $backed_up items to $backup_dir"
		else
			info "No existing configurations to backup"
		fi
	}

	configure_dock() {
		step "Configuring Dock"

		if [[ "$disable_dock" == "true" ]]; then
			info "Skipping Dock configuration (--no-dock)"
			return 0
		fi

		if ! command_exists dockutil; then
			warn "dockutil not found, skipping Dock configuration"
			return 0
		fi

		add_dock_app_if_present() {
			local app_path="$1"
			[[ -d "$app_path" ]] && dockutil --add "$app_path" --no-restart
		}

		info "Setting up Dock with preferred apps..."
		dockutil --remove all --no-restart

		dockutil --add "/System/Applications/System Settings.app" --no-restart

		if [[ "$profile" == "work" ]]; then
			add_dock_app_if_present "/Applications/Spotify.app"
			add_dock_app_if_present "/Applications/Ghostty.app"
			add_dock_app_if_present "/Applications/Microsoft Outlook.app"
			add_dock_app_if_present "/Applications/Slack.app"
			add_dock_app_if_present "/Applications/Firefox.app"
			add_dock_app_if_present "/Applications/Obsidian.app"
			add_dock_app_if_present "/Applications/Sublime Text.app"
			add_dock_app_if_present "/Applications/Linear.app"
		else
			dockutil --add "/System/Applications/Calendar.app" --no-restart
			dockutil --add "/System/Applications/Messages.app" --no-restart
			dockutil --add "/System/Applications/Mail.app" --no-restart
			add_dock_app_if_present "/Applications/Slack.app"
			add_dock_app_if_present "/Applications/Ghostty.app"
			add_dock_app_if_present "/Applications/Firefox.app"
			if [[ "$profile" == "personal" ]]; then
				add_dock_app_if_present "/Applications/Spotify.app"
				add_dock_app_if_present "/Applications/Obsidian.app"
				add_dock_app_if_present "/Applications/Drafts.app"
			fi
		fi

		dockutil --add ~/Downloads --view fan --display stack --sort dateadded --no-restart
		dockutil --add /Applications --view grid --display folder --sort name --no-restart

		killall Dock
		info "Dock configured"
	}

	configure_shell() {
		step "Configuring shell"

		if [[ "$SHELL" != *"zsh"* ]]; then
			info "Setting Zsh as default shell..."
			local zsh_path
			zsh_path="$(command -v zsh)"

			if [[ -n "$zsh_path" ]] && ! grep -q "$zsh_path" /etc/shells; then
				echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
			fi

			chsh -s "$zsh_path" || warn "Failed to set Zsh as default shell"
		else
			info "Zsh is already the default shell"
		fi
	}

	configure_git() {
		step "Configuring Git"

		if [[ "$disable_git" == "true" ]]; then
			info "Skipping Git configuration (--no-git)"
			return 0
		fi

		if [[ "$assume_yes" == "true" ]]; then
			info "Skipping interactive Git prompts (--yes)"
			return 0
		fi

		echo "Leave empty to skip git configuration."
		read -r -p "Git user name: " git_name
		if [[ -z "$git_name" ]]; then
			info "Skipping git configuration"
			return 0
		fi

		read -r -p "Git email: " git_email
		dot_git_setup --name "$git_name" --email "$git_email" --default-branch main --yes
		info "Git configured"
	}

	post_install() {
		step "Running post-installation tasks"

		info "Disabling Spotlight keyboard shortcuts..."
		defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '{ enabled = 0; value = { parameters = ( 32, 49, 1048576 ); type = "standard"; }; }'
		defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 '{ enabled = 0; value = { parameters = ( 32, 49, 1572864 ); type = "standard"; }; }'

		if [[ -d "/opt/homebrew/share" ]]; then
			info "Fixing Homebrew directory permissions for Zsh..."
			chmod -R go-w /opt/homebrew/share 2>/dev/null || true
		fi

		if command_exists nvim; then
			info "Setting up Neovim..."
			sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' 2>/dev/null || true
		fi

		if command_exists tmux; then
			info "Setting up tmux plugin manager..."
			local tpm_dir="$HOME/.config/tmux/plugins/tpm"
			if [[ ! -d "$tpm_dir" ]]; then
				mkdir -p "$HOME/.config/tmux/plugins"
				if ! GIT_TERMINAL_PROMPT=0 git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null; then
					warn "Git clone for TPM failed; downloading archive instead"
					local tpm_tmp
					tpm_tmp="$(mktemp -d)"
					if curl -fsSL https://codeload.github.com/tmux-plugins/tpm/tar.gz/refs/heads/master -o "$tpm_tmp/tpm.tar.gz"; then
						tar -xzf "$tpm_tmp/tpm.tar.gz" -C "$tpm_tmp" 2>/dev/null || true
						if [[ -d "$tpm_tmp/tpm-master" ]]; then
							mv "$tpm_tmp/tpm-master" "$tpm_dir"
						else
							warn "Unable to unpack TPM archive"
						fi
					else
						warn "Unable to download TPM archive"
					fi
					rm -rf "$tpm_tmp"
				fi
			fi
		fi

		if command_exists fzf && command_exists brew; then
			info "Setting up FZF..."
			"$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash 2>/dev/null || true
		fi

		if [[ -f "$HOME/.config/wallpapers/plane-wp.png" ]]; then
			info "Setting desktop wallpaper..."
			osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$HOME/.config/wallpapers/plane-wp.png\"" 2>/dev/null || warn "Failed to set wallpaper"
		fi
	}

	install_fonts() {
		if [[ "$disable_fonts" == "true" ]]; then
			info "Skipping fonts installation (--no-fonts)"
			return 0
		fi

		if [[ "$profile" != "personal" ]]; then
			info "Skipping fonts installation for profile '$profile'"
			return 0
		fi

		step "Installing personal fonts"
		local fonts_repo="git@github.com:nsyout/system-fonts.git"
		local fonts_dir="$HOME/projects/personal/system-fonts"

		if [[ -d "$fonts_dir" ]]; then
			info "Updating fonts repository..."
			git -C "$fonts_dir" pull || warn "Failed to update fonts repository"
		else
			info "Cloning fonts repository..."
			git clone "$fonts_repo" "$fonts_dir" || {
				warn "Unable to clone fonts repository, skipping"
				return 0
			}
		fi

		mkdir -p "$HOME/Library/Fonts"
		find "$fonts_dir" -maxdepth 1 -type f \( -name '*.ttf' -o -name '*.otf' -o -name '*.TTF' -o -name '*.OTF' \) -exec cp -f {} "$HOME/Library/Fonts/" \; 2>/dev/null || true
		info "Fonts installation complete"
	}

	setup_firefox() {
		if [[ "$disable_firefox" == "true" ]]; then
			info "Skipping Firefox setup (--no-firefox)"
			return 0
		fi

		step "Setting up Firefox configuration"

		local firefox_config="$dotfiles_dir/.config/firefox"
		local extensions_conf="$firefox_config/extensions.conf"
		local user_overrides="$firefox_config/user-overrides.js"
		local firefox_app="/Applications/Firefox.app"
		local profiles_dir="$HOME/Library/Application Support/Firefox/Profiles"
		local distribution_dir="$firefox_app/Contents/Resources/distribution"

		if [[ ! -d "$firefox_app" ]]; then
			warn "Firefox not installed, skipping"
			return 0
		fi

		if [[ ! -f "$extensions_conf" ]] || [[ ! -f "$user_overrides" ]]; then
			warn "Firefox config files missing from dotfiles"
			return 0
		fi

		local install_personal=false
		if [[ "$profile" == "personal" ]]; then
			install_personal=true
		fi

		info "Building extension policies..."
		local policies_tmp
		policies_tmp=$(mktemp)

		cat >"$policies_tmp" <<'POLICYHEAD'
{
  "policies": {
    "ExtensionSettings": {
      "*": {
        "installation_mode": "allowed"
      }
POLICYHEAD

		while IFS=: read -r category _name ext_id slug; do
			[[ "$category" =~ ^#.*$ ]] && continue
			[[ -z "$category" ]] && continue
			if [[ "$category" == "personal" && "$install_personal" != "true" ]]; then
				continue
			fi

			cat >>"$policies_tmp" <<EXTBLOCK
      ,"$ext_id": {
        "installation_mode": "normal_installed",
        "install_url": "https://addons.mozilla.org/firefox/downloads/latest/$slug/latest.xpi"
      }
EXTBLOCK
		done <"$extensions_conf"

		cat >>"$policies_tmp" <<'POLICYTAIL'
    }
  }
}
POLICYTAIL

		info "Deploying extension policies..."
		sudo mkdir -p "$distribution_dir"
		sudo cp "$policies_tmp" "$distribution_dir/policies.json"
		sudo chmod 644 "$distribution_dir/policies.json"
		rm -f "$policies_tmp"

		local profile_dir
		profile_dir=$(find "$profiles_dir" -maxdepth 1 -type d -name "*.default*" 2>/dev/null | head -1)
		if [[ -z "$profile_dir" ]]; then
			warn "No Firefox profile found; launch Firefox once and rerun init"
			return 0
		fi

		info "Downloading arkenfox user.js..."
		local arkenfox_url="https://raw.githubusercontent.com/arkenfox/user.js/master/user.js"
		curl -sL "$arkenfox_url" -o "$profile_dir/user.js" || {
			warn "Failed to download arkenfox user.js"
			return 0
		}

		info "Applying user overrides..."
		cat "$user_overrides" >>"$profile_dir/user.js"
		info "Firefox configured"
	}

	cat <<EOF
╔══════════════════════════════════════════╗
║             DOT INIT                     ║
╚══════════════════════════════════════════╝
EOF

	info "Using profile: $profile"

	if [[ "$dry_run" == "true" ]]; then
		step "Dry run"
		info "Would install dependencies"
		info "Would back up existing configs"
		info "Would stow profile packages:"
		dot_stow_profile_packages "$profile" | while IFS= read -r pkg; do
			info "  - $pkg"
		done
		info "Would sync package manifests:"
		dot_packages_manifest_files "$profile" | while IFS= read -r mf; do
			info "  - $(basename "$mf")"
		done
		[[ "$disable_fonts" == "true" ]] || info "Would run fonts flow (profile-gated)"
		[[ "$disable_firefox" == "true" ]] || info "Would run Firefox setup"
		[[ "$disable_dock" == "true" ]] || info "Would configure Dock"
		[[ "$disable_git" == "true" ]] || info "Would offer Git configuration"
		info "Would run post-install tasks"
		return 0
	fi

	install_dependencies
	backup_configs
	dot_stow_apply "$profile" "$assume_yes"
	dot_packages_sync "$profile"
	configure_dock
	install_fonts
	configure_shell
	configure_git
	setup_firefox
	post_install

	echo
	printf "%b╔══════════════════════════════════════════╗%b\n" "$COLOR_GREEN" "$COLOR_RESET"
	printf "%b║     INSTALLATION COMPLETED SUCCESSFULLY! ║%b\n" "$COLOR_GREEN" "$COLOR_RESET"
	printf "%b╚══════════════════════════════════════════╝%b\n" "$COLOR_GREEN" "$COLOR_RESET"
	info "Backup of old configurations saved to: $backup_dir"
}
