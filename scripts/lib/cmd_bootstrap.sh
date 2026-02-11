#!/usr/bin/env bash

dot_cmd_bootstrap() {
	local assume_yes=false
	local dry_run=false
	local explicit_profile=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--yes)
			assume_yes=true
			;;
		--dry-run)
			dry_run=true
			;;
		--profile)
			shift
			explicit_profile="${1:-}"
			;;
		-h | --help)
			cat <<'EOF'
Usage: dot bootstrap [options]

Options:
  --profile <base|personal|work>
  --yes
  --dry-run
EOF
			return 0
			;;
		*)
			error "Unknown option for dot bootstrap: $1"
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

	if [[ "$(uname -s)" != "Darwin" ]]; then
		error "dot bootstrap is for macOS only"
		return 1
	fi

	cat <<EOF
╔══════════════════════════════════════════╗
║            DOT BOOTSTRAP                 ║
║            Fresh System Setup            ║
╚══════════════════════════════════════════╝
EOF

	info "Using profile: $profile"

	if [[ "$dry_run" == "true" ]]; then
		step "Dry run"
		info "Would request sudo access"
		info "Would apply macOS defaults (Finder, Dock, Trackpad, Keyboard, Security)"
		info "Would install Xcode Command Line Tools"
		info "Would create standard directories"
		info "Would install Homebrew and essential tools"
		info "Would optionally run YubiKey key extraction"
		info "Would invoke: dot init --profile $profile"
		return 0
	fi

	info "Requesting administrator privileges..."
	sudo -v
	while true; do
		sudo -n true
		sleep 60
		kill -0 "$$" || exit
	done 2>/dev/null &

	step "Configuring System Preferences"
	info "Setting Finder preferences..."
	defaults write com.apple.finder ShowPathbar -bool true
	defaults write com.apple.finder ShowStatusBar -bool true
	defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
	defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
	defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	defaults write com.apple.finder AppleShowAllFiles -bool false

	info "Configuring Dock..."
	defaults write com.apple.dock autohide -bool true
	defaults write com.apple.dock autohide-delay -float 0.1
	defaults write com.apple.dock autohide-time-modifier -float 0.5
	defaults write com.apple.dock tilesize -int 40
	defaults write com.apple.dock show-recents -bool false
	defaults write com.apple.dock minimize-to-application -bool false
	defaults write com.apple.dock mru-spaces -bool false

	info "Configuring Trackpad and Keyboard..."
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
	defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
	defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
	defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
	defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool false
	defaults write com.apple.AppleMultitouchTrackpad ActionsEnabled -bool false
	defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
	defaults write NSGlobalDomain KeyRepeat -int 2
	defaults write NSGlobalDomain InitialKeyRepeat -int 15
	defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

	info "Configuring security settings..."
	sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
	defaults write com.apple.screensaver askForPassword -int 1
	defaults write com.apple.screensaver askForPasswordDelay -int 0

	step "Installing Xcode Command Line Tools"
	if ! xcode-select -p &>/dev/null; then
		info "Installing Xcode Command Line Tools..."
		xcode-select --install
		until xcode-select -p &>/dev/null; do
			sleep 5
		done
		info "Xcode Command Line Tools installed"
	else
		info "Xcode Command Line Tools already installed"
	fi

	step "Creating standard directories"
	mkdir -p "$HOME/Developer"
	mkdir -p "$HOME/projects/repos"
	mkdir -p "$HOME/projects/forks"
	mkdir -p "$HOME/projects/playground"
	mkdir -p "$HOME/projects/fonts"
	mkdir -p "$HOME/.config"
	mkdir -p "$HOME/.local/bin"
	mkdir -p "$HOME/.local/share"
	mkdir -p "$HOME/.cache"

	step "Configuring hostname"
	local current_name
	current_name=$(scutil --get ComputerName 2>/dev/null || echo "Unknown")
	info "Current hostname: $current_name"
	if [[ "$assume_yes" != "true" ]]; then
		read -r -p "Enter new hostname (leave blank to keep '$current_name'): " new_hostname
		if [[ -n "$new_hostname" ]]; then
			info "Setting hostname to '$new_hostname'..."
			sudo scutil --set ComputerName "$new_hostname"
			sudo scutil --set HostName "$new_hostname"
			sudo scutil --set LocalHostName "$(echo "$new_hostname" | tr ' ' '-' | tr -cd '[:alnum:]-')"
		fi
	else
		info "Skipping hostname prompt (--yes)"
	fi

	step "Installing Homebrew"
	if ! command_exists brew; then
		info "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
		if [[ -d "/opt/homebrew" ]]; then
			eval "$(/opt/homebrew/bin/brew shellenv)"
		else
			eval "$(/usr/local/bin/brew shellenv)"
		fi
	else
		info "Homebrew already installed"
		brew update
	fi

	info "Disabling Homebrew analytics..."
	brew analytics off

	step "Installing essential tools"
	brew install git stow coreutils findutils gnu-sed grep wget curl jq gh openssh libfido2 ykman dockutil || warn "Some essential tools failed to install"

	if [[ "$assume_yes" != "true" ]]; then
		step "Setting up YubiKey SSH Keys"
		info "Run key extraction later if you prefer; skipping for now in automated cutover flow"
	else
		info "Skipping YubiKey prompts (--yes)"
	fi

	step "Restarting affected applications"
	for app in Finder Dock SystemUIServer; do
		killall "$app" >/dev/null 2>&1 || true
	done

	echo
	printf "%b╔══════════════════════════════════════════╗%b\n" "$COLOR_GREEN" "$COLOR_RESET"
	printf "%b║     BOOTSTRAP COMPLETED SUCCESSFULLY!    ║%b\n" "$COLOR_GREEN" "$COLOR_RESET"
	printf "%b╚══════════════════════════════════════════╝%b\n" "$COLOR_GREEN" "$COLOR_RESET"
	echo

	if [[ "$assume_yes" == "true" ]]; then
		info "Running dot init with --yes..."
		dot_cmd_init --profile "$profile" --yes
	else
		read -p "Run dot init now? (y/n) " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			dot_cmd_init --profile "$profile"
		else
			info "Run 'dot init --profile $profile' when ready"
		fi
	fi
}
