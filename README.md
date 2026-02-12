# macOS Dotfiles

A clean, streamlined dotfiles configuration for macOS with automated installation and modern CLI tools.

## Inspiration

Parts of this repository's ongoing `dot` CLI redesign are inspired by
[`dmmulroy/.dotfiles`](https://github.com/dmmulroy/.dotfiles), especially the
single-command workflow and modular dotfiles management approach.

## Features

- **macOS Optimized**: Tailored specifically for macOS with Homebrew integration
- **Modular Architecture**: Clear separation between configurations
- **Performance First**: Starship prompt for 10-50x faster shell rendering
- **Modern Tools**: Latest CLI tools (ghostty, fzf, ripgrep, bat, zoxide, btop, etc.)
- **Zero Conflicts**: Whitelist approach prevents config pollution
- **Smart Installation**: Automated setup with dependency management
- **Aerospace WM**: Tiling window manager configuration included

## Structure

```text
dotfiles/
├── dot                   # Primary CLI entrypoint
├── .config/              # All configuration files
│   ├── zsh/             # Shell configuration
│   │   ├── .zshrc       # Modular zsh loader
│   │   ├── .zshrc.d/    # Modular config components
│   │   │   ├── 00-env.zsh      # Environment setup
│   │   │   ├── 05-settings.zsh # Zsh options and settings
│   │   │   ├── 10-aliases.zsh  # Alias loader
│   │   │   ├── 20-functions.zsh# Function loader
│   │   │   ├── 30-fzf.zsh      # FZF configuration
│   │   │   ├── 40-completion.zsh# Tab completion
│   │   │   └── 90-plugins.zsh  # Starship & plugin loading
│   │   ├── aliases.zsh   # Consolidated aliases (macOS + cross-platform)
│   │   ├── scripts.zsh   # Custom shell functions
│   │   └── plugins/      # Zsh plugins (syntax highlighting, completions, etc.)
│   ├── starship/         # Starship prompt configuration
│   ├── aerospace/        # Tiling window manager
│   ├── ghostty/          # Terminal emulator
│   ├── git/              # Git configuration
│   ├── nvim/             # Neovim configuration (LazyVim)
│   └── tmux/             # Tmux configuration
│
├── .zshenv               # Environment variables
├── Brewfile              # Base package definitions
├── Brewfile.base         # Base manifest loader for dot packages
├── Brewfile.personal     # Personal package overlay
├── Brewfile.work         # Work package overlay
├── stow-manifest.base    # Base stow package set
├── stow-manifest.personal# Personal stow overlay
├── stow-manifest.work    # Work stow overlay
├── dot                   # Primary CLI entrypoint
│
└── scripts/              # Supporting scripts + modular libraries
    └── lib/              # Command implementations and shared modules
```

## Installation

### Quick Start by Machine Type

#### Fresh Personal Machine

```bash
git clone https://github.com/nsyout/sys-forbidden.git ~/.dotfiles
cd ~/.dotfiles
./dot profile set personal
./dot bootstrap --profile personal
```

After bootstrap completes:

```bash
dot stow --profile personal
dot packages sync --profile personal
dot ssh configure --profile personal --yes
dot doctor --profile personal
```

#### Fresh Work Machine

```bash
git clone https://github.com/nsyout/sys-forbidden.git ~/.dotfiles
cd ~/.dotfiles
./dot profile set work
./dot bootstrap --profile work
```

After bootstrap completes:

```bash
dot stow --profile work
dot packages sync --profile work
dot ssh configure --profile work --yes
dot doctor --profile work
```

Work profile notes:

- personal-only modules are skipped (for example: `claude`, `resticprofile`)
- restic setup is personal-only and blocked on work profile

### Fresh macOS Setup

For a brand new macOS installation:

```bash
git clone https://github.com/nsyout/sys-forbidden.git ~/.dotfiles
cd ~/.dotfiles
./dot bootstrap
```

Bootstrap will prompt you to run full setup at the end, or you can run `./dot init` later.

**Bootstrap includes:**

- macOS system preferences (Finder, Dock, Trackpad, Keyboard, etc.)
- Xcode Command Line Tools
- Hostname configuration
- Homebrew installation
- Essential tools (git, stow, openssh, YubiKey tools)
- YubiKey SSH key extraction (requires YubiKey hardware)
- Standard directory structure

### Existing System

```bash
git clone https://github.com/nsyout/sys-forbidden.git ~/.dotfiles
cd ~/.dotfiles
./dot init
```

### Profile Model

Profiles are additive overlays:

- `base`: deploy/install base manifests only
- `personal`: base + personal overlay manifests
- `work`: base + work overlay manifests

This applies to both:

- stow deployment (`stow-manifest.base` + profile overlay)
- package sync (`Brewfile.base` + profile overlay)

The setup command will:

1. Install Homebrew if not present
2. Install required tools (git, stow, starship, etc.)
3. Clean up broken symlinks
4. Deploy configurations using GNU Stow (with smart conflict handling)
   - Detects conflicting files automatically
   - Offers to backup and replace, skip, or abort
   - Preserves directory structure in backups
5. Install packages from profile-aware Brewfile manifests
6. Install fonts from private system-fonts repository
7. Configure Zsh as default shell
8. Prompt for hostname configuration (optional)
9. Prompt for Git configuration (optional)
10. Clone and configure Firefox with custom settings
11. Set up plugins and tools (vim-plug, tmux, fzf)
12. Set desktop wallpaper

### SSH (YubiKey Resident Keys)

Use `dot ssh` commands for pointer-key workflows (not local software key generation):

```bash
# Download resident key pointers from the inserted YubiKey
dot ssh sync-yubikey-keys --slot primary
dot ssh sync-yubikey-keys --slot backup

# Generate ~/.ssh/config from profile templates
dot ssh configure --profile personal

# Check YubiKey + pointer key status
dot ssh status
```

### OpenCode Configuration

OpenCode configuration lives in `.config/opencode/`.

- Git-only policy: command/skill docs are aligned to `git` + `gh` workflows
- MCP servers currently enabled:
  - `context7` (remote docs lookup)
  - `grep_app` (remote code search)
  - `opensrc` (local source exploration via `npx opensrc-mcp`)
  - `overseer` (local task orchestration via `npx @dmmulroy/overseer mcp`)
- Plugins:
  - `~/.config/opencode/plugins/*.js|*.ts` are auto-loaded by OpenCode at startup
  - `opencode.json` keeps `"plugin": []` so no npm plugin package is pinned
  - no local plugin is currently tracked in this repo

## noisyoutput.com Content Management

The `nsy` function provides a safe workflow for creating and publishing content to noisyoutput.com (Hugo static site).

### Creating Content

```bash
nsy              # Interactive: prompts for type and name
nsy create       # Same as above
nsy note         # Skip type selection, go straight to note
nsy writing      # Skip type selection, go straight to writing
nsy page         # Skip type selection, go straight to page
```

**Workflow:**

1. Select content type (note, writing, page)
2. Enter slug/name
3. Hugo creates the file with `draft: true`
4. Opens in `$EDITOR`
5. After saving, starts `hugo serve` for local preview
6. Prompts:
   - **Commit as draft** → pushes but won't go live
   - **Publish live** → flips draft to false, pushes, goes live immediately
   - **Keep editing** → back to editor
   - **Discard** → optionally delete the file

### Publishing Drafts

```bash
nsy publish      # Select from existing drafts
nsy pub          # Shorthand
```

**Workflow:**

1. Shows list of drafts (fzf selection with preview)
2. Option to preview locally first
3. Flips `draft: false` in frontmatter
4. Commits and pushes → content goes live

### Configuration

Set `NSY_HUGO_DIR` to override the default Hugo directory:

```bash
export NSY_HUGO_DIR="$HOME/projects/repos/noisyoutput.com"
```

## Firefox Configuration

Firefox is configured via `.config/firefox/`:

- **Privacy hardening** via arkenfox user.js (downloaded fresh on setup/update)
- **Custom overrides** in `user-overrides.js` (session restore, Kagi search, vertical tabs, etc.)
- **Extension policies** in `extensions.conf` - auto-installs uBlock Origin, 1Password, Kagi, and more
- **Automatic updates** via the `update` command

## Backup Configuration (restic)

Automated backups to S3 using restic and resticprofile, with credentials securely stored via 1Password Service Account.

### Architecture

```text
macOS Keychain (encrypted)
    └── 1Password Service Account token
            └── fetches at runtime:
                ├── Restic repository password
                └── AWS S3 credentials
```

- **No secrets on disk** - credentials stay in 1Password
- **Machine-aware** - automatically uses correct credentials for sys-ms or sys-mbp
- **Scheduled backups** - daily at 6 AM via launchd
- **Concurrent run protection** - lock file prevents scheduled and manual backups from colliding

### Setup

1. **Create 1Password Service Account**:
   - Go to <https://my.1password.com> → Developer Tools → Service Accounts
   - Create account named "Backups" (or similar)
   - Grant read access to the "Restic" vault
   - Copy the token (starts with `ops_`)

2. **Required 1Password Items** (in "Restic" vault):
   - `Restic Password - sys-ms` (or `sys-mbp`) - password field
   - `AWS Backup Credentials - sys-ms` (or `sys-mbp`) - AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY fields

3. **Run setup command**:

   ```bash
   dot profile set personal
   dot restic setup
   ```

   Machine naming note:
   - Auto-detection currently maps hostnames starting with `sys-ms` or `sys-mbp`.
   - For a new machine naming scheme, use `dot restic setup --machine <sys-ms|sys-mbp>` temporarily,
     then update machine mapping in `scripts/lib/cmd_restic.sh`.

4. **Initialize repository** (first time only):

   ```bash
   restic-backup init
   ```

The setup command automatically installs launchd schedules for:

- Daily backup at 06:00
- Weekly forget at Sunday 03:00
- Weekly prune at Sunday 03:30
- Weekly check at Sunday 04:00

### Usage

```bash
# Run backup manually
restic-backup backup

# View snapshots
restic-backup snapshots

# Check repository integrity
restic-backup check

# Restore files
restic-backup restore latest --target /tmp/restore
```

### Backup configuration files

- Config: `~/.config/resticprofile/profiles.toml`
- Wrapper: `~/.config/resticprofile/backup`
- Logs: `~/.local/share/resticprofile/backup.log`
- Lock file: `~/.local/share/resticprofile/backup.lock`

Backup includes `/Users/readerr` with exclusions for caches, build artifacts, and reinstallable applications.

The lock file prevents concurrent backup runs. If a scheduled backup fires while a manual backup is running, it exits gracefully. Stale locks (from crashes or reboots) are automatically cleaned up by verifying the PID is still a running backup process.

## Manual Setup Required

Some components require manual setup or purchase:

### Fonts

**Berkeley Mono** (Commercial font, used in terminal):

- Purchase from [Berkeley Graphics](https://berkeleygraphics.com/)
- Stored in private repository: `git@github.com:nsyout/system-fonts.git`
- Automatically installed during `dot init` (personal profile) if you have SSH access
- Fallback to **IosevkaTerm Nerd Font** (free, included in Brewfile) if not available

To use your own fonts:

1. Create a private fonts repository
2. Update the `install_fonts` flow in `scripts/lib/cmd_init.sh` with your repo URL
3. Or manually install fonts to `~/Library/Fonts/`

### Mac App Store Apps

The following apps require Mac App Store sign-in and previous purchase:

- **Reeder Classic** (RSS reader)
- **Drafts** (Quick notes)

These are installed automatically if you're signed into the App Store.

## Key Configurations

### Environment Variables (`.zshenv`)

- XDG Base Directory specification
- Editor preferences (Neovim)
- FZF configuration with custom theme
- Homebrew paths and settings
- SSH FIDO2 support via Homebrew OpenSSH (for YubiKey)
- GNU utilities paths
- Development paths (Go, Rust, Python, Node, LM Studio)

### Shell Configuration

**Modular Zsh setup**:

- Numbered configuration files in `.zshrc.d/` for ordered loading
- **Starship prompt** (10-50x faster than custom shell prompts)
  - Async rendering for instant prompt display
  - Context-aware language version detection (Node, Python, Go, Rust)
  - Git status integration
  - Terraform, Docker, AWS context display
  - Custom configuration in `.config/starship/starship.toml`
- Syntax highlighting (zsh-syntax-highlighting)
- FZF integration with custom bindings
- Smart directory navigation (zoxide, bd)
- Git utilities (full `git`/`gh` commands preferred)
- Consolidated aliases (single source of truth)

**Key aliases**:

- `dotf` for jumping to `~/.dotfiles`
- Project and directory navigation (`pj`, `pjf`, `pjp`, `pjr`, `dl`, `dt`)
- Listing defaults with `eza` (`l`, `lt`, `lt1`, `lt2`, `lt3`)
- Explicit disk usage helper (`diskusage`)
- Safe trash function (macOS Finder integration via `trash`)

**Custom functions** (defined in `.config/zsh/scripts.zsh`):

|Function|Description|
|---|---|
|`nsy`|noisyoutput.com content management (see below)|
|`extract <file>`|Extract any archive (zip, tar, gz, 7z, rar, etc.)|
|`mkextract <file>`|Extract archive into its own directory|
|`compress <files>`|Create timestamped tar.gz archive|
|`ytdlvideo <url>`|Download single video (best quality, mkv)|
|`ytdlplaylist <url>`|Download playlist (numbered, mkv)|
|`ytdlaudio <url>`|Extract audio as MP3|
|`ytdlarchive <url>`|Archive channel/playlist with progress tracking|
|`cheat <topic>`|Fetch cheatsheet from cheat.sh|
|`trash-size`|Show trash folder size|
|`trash-clean [days]`|Empty trash older than N days (default 7)|
|`trash-status`|Show trash size and recent items|

**Additional Configurations**:

- **yt-dlp**: Archival-focused configuration in `.config/yt-dlp/config`
  - Firefox cookie integration
  - Metadata embedding and thumbnail downloads
  - Organized output by channel/date
  - Politeness/anti-throttle settings
- **tmux**: Minimal vim-style keybindings (Ctrl-a prefix)
- **Ghostty**: Terminal emulator with Berkeley Mono font fallbacks
- **Wallpaper**: Desktop wallpaper automatically set during setup
  - Stored in `.config/wallpapers/`
  - Manual command: `dot wallpaper set [path]`

### Included Tools

**CLI Essentials:**

- `starship` - Fast, customizable prompt
- `btop` - Modern system monitor
- `ripgrep` - Fast text search (rg)
- `fzf` - Fuzzy finder
- `bat` - Cat with syntax highlighting
- `eza` - Modern ls replacement (with git status integration)
- `fd` - Fast find alternative
- `zoxide` - Smart cd replacement
- `jq` - JSON processor
- `tree` - Directory tree view
- `ncdu` - Disk usage analyzer
- `tlrc` - Fast TL;DR client
- `fastfetch` - System info display
- `prettyping` - Better ping
- `diff-so-fancy` - Better git diff

**Development:**

- `rustup-init` - Rust toolchain installer
- `go` - Go programming language
- `deno` - JavaScript/TypeScript runtime
- `neovim` - Modern text editor (LazyVim)
- `tmux` - Terminal multiplexer
- `lazygit` - Terminal UI for git
- `yazi` - Terminal file manager
- `shellcheck` - Shell script analyzer
- `harper` - Local grammar checker
- `uv` - Fast Python package installer
- GNU utilities (`coreutils`, `gnu-sed`, `grep`, `findutils`, `moreutils`)

**DevOps:**

- `docker` - Container platform
- `awscli` - AWS CLI
- `opentofu` - Terraform alternative
- `ansible` - Configuration management
- `tailscale` - VPN mesh network

**Security & Authentication:**

- `1password` - Password manager (desktop app)
- `1password-cli` - 1Password CLI
- `openssh` - SSH with FIDO2 support
- `libfido2` - FIDO2 library for YubiKeys
- `ykman` - YubiKey manager
- `age` - File encryption tool

**Media & Download:**

- `yt-dlp` - Video downloader/archiver
- `gallery-dl` - Gallery downloader
- `ffmpeg` - Media processing
- `aria2` - Download manager

**System Utilities:**

- `mas` - Mac App Store CLI
- `terminal-notifier` - Terminal notifications
- `wifi-password` - WiFi password retrieval
- `trash-cli` - Safe trash management
- `speedtest-cli` - Internet speed test
- `telnet` - Telnet client
- `hugo` - Static site generator
- `gh` - GitHub CLI

**Backup:**

- `restic` - Fast, secure backup program
- `resticprofile` - Configuration manager for restic

## Customization

### Adding New Applications

1. Add configuration to `.config/`:

```bash
mkdir -p .config/newapp
# Add your config files
```

1. Update `.gitignore` if needed to track the files

2. Re-deploy with stow:

```bash
cd ~/.dotfiles
stow --restow .
```

The `--restow` flag ensures stow re-evaluates all symlinks and respects `.stow-local-ignore`.

### Local Overrides

Create `.zshrc.local` in your home directory for machine-specific settings:

```bash
# ~/.zshrc.local
export CUSTOM_VAR="value"
alias myalias="command"
```

## Updating

Use `dot update` to update everything:

```bash
dot update
```

This will:

- Check for macOS system updates
- Pull latest dotfiles changes (if remote has changes)
- Re-link configs for the active profile (only if dotfiles changed)
- Run Homebrew update/upgrade
- Run profile-aware package sync + retry failed manifests
- Run `dot doctor`

Firefox updates are explicit and separate: `dot firefox sync`

## Maintenance (Local-Only)

### Operational maintenance

Use one command for ongoing maintenance:

```bash
dot update
```

Use a profile override when needed:

```bash
dot update --profile <base|personal|work>
```

Preview changes first:

```bash
dot update --dry-run
```

Package removals are explicit and separate (can remove many packages):

```bash
dot packages cleanup --profile <base|personal|work>
```

Firefox updates are explicit and separate:

```bash
dot firefox sync
```

### Change validation (QA)

Run all local QA checks:

```bash
dot qa
```

`local-qa.sh` includes:

- Blocking checks: `shellcheck`, `bash -n`, `zsh -n`, `gitleaks detect --no-git --redact`
- Config sanity: AeroSpace TOML parse (`.config/aerospace/aerospace.toml`)
- Warn-only checks: `shfmt -d`, `markdownlint-cli2 README.md`, `./scripts/local-sast.sh` (opengrep)

Run security scans only:

```bash
# Working tree secrets + strict SAST
dot security

# Add git history secret scan
dot security --history

# Keep SAST non-blocking
dot security --warn-sast
```

Run SAST scan only:

```bash
# warn-only behavior inside local-qa
dot sast

# strict mode (non-zero exit on findings)
dot sast --strict
```

Install local pre-commit hook (runs the same QA script on every commit):

```bash
ln -sf ../../scripts/pre-commit .git/hooks/pre-commit
```

### Public repo hygiene (local)

- Secrets: `./scripts/local-security.sh` (add `--history` for deep scan)
- Lint/syntax: `shellcheck`, `bash -n`, `zsh -n`
- Docs drift: verify command examples against real `dot` command behavior

## Package Management

### macOS (Homebrew)

Packages are profile-aware and defined by these manifests:

- `Brewfile.base` (loads base package set)
- `Brewfile.personal` (personal overlay)
- `Brewfile.work` (work overlay)

Use `dot packages` as the primary interface:

```bash
# Install/update packages for active profile
dot packages sync

# Check package drift for active profile
dot packages check

# Remove packages no longer in active profile manifests
dot packages cleanup

# List package entries for active profile
dot packages list

# Add/remove package entries in profile manifest
dot packages add ripgrep --profile base
dot packages remove claude --cask --profile personal

# Retry failed sync manifests
dot retry-failed
```

### Adding New Packages

Edit the relevant manifest (`Brewfile` for base definitions, plus `Brewfile.personal` or `Brewfile.work` overlays):

```ruby
# Add a CLI tool
brew "newtool"

# Add a GUI application
cask "newapp"
```

Then run `dot packages sync` to install.

## Manual Setup

If you prefer manual installation:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install stow
git clone https://github.com/nsyout/sys-forbidden.git ~/.dotfiles
cd ~/.dotfiles
stow --restow .
dot packages sync
```

Note: Manual setup skips conflict handling. Back up existing dotfiles first if needed.

## Performance Notes

This configuration is optimized for speed:

- **Starship prompt**: Rust-based async rendering (10-50x faster than shell-based prompts)
- **Minimal plugin load**: Only essential plugins loaded
- **Consolidated configs**: No duplicate file sourcing
- **Cached completions**: Zsh completion cache enabled

Typical shell startup: ~100-200ms on modern hardware

## Troubleshooting

### Stow Conflicts

The setup command handles conflicts automatically by:

1. Detecting which files conflict
2. Showing you the list of conflicting files
3. Offering options: **[B]ackup and replace**, **[S]kip**, or **[A]bort**

If you choose backup, conflicting files are moved to `~/.dotfiles-backup-<timestamp>/` preserving their directory structure.

For manual stow operations:

```bash
cd ~/.dotfiles
stow --restow .
```

If you get conflicts manually, you can backup and remove the conflicting files, then retry.

### Stow Commands

|Command|What it does|
|---|---|
|`stow .`|Create symlinks (won't overwrite existing files)|
|`stow -R .`|Restow = unstow + stow (use after restructuring dotfiles)|
|`stow -D .`|Delete symlinks (unstow)|

**Important**: Stow silently skips paths where real files already exist. It won't overwrite or warn - it just does nothing for those paths. If `dot init` or a manual copy created real files, stow won't replace them with symlinks.

To find non-symlinked configs that should be symlinks:

```bash
# Check .config for real directories (not symlinks)
find ~/.config -maxdepth 1 -type d ! -type l -exec ls -la {} \;
```

To fix, remove the real file/directory and re-stow:

```bash
rm -rf ~/.config/someapp
cd ~/.dotfiles && stow .
```

### Missing Commands

If commands are missing after installation:

```bash
# Reload environment
source ~/.zshenv
source ~/.config/zsh/.zshrc

# Or restart shell
exec zsh

# Check PATH
echo $PATH | tr ':' '\n'
```

### Prompt Not Appearing

If you see a basic prompt instead of Starship:

```bash
# Check if Starship is installed
which starship

# If missing, install it
brew install starship

# Verify plugin loader
cat ~/.config/zsh/.zshrc.d/90-plugins.zsh
```

### Slow Prompt

If the prompt feels sluggish:

```bash
# Check if you're using Starship (should be fast)
ps aux | grep starship

# Time shell startup
time zsh -i -c exit

# Should be under 200ms
```

## Contributing

This repository is for personal use. Feel free to fork and adapt for your own needs.

Feel free to fork and customize for your needs. PRs welcome for:

- Additional platform support
- New tool configurations
- Bug fixes
- Documentation improvements

## Acknowledgments

- [GNU Stow](https://www.gnu.org/software/stow/) for symlink management
- [Homebrew](https://brew.sh/) for package management
- [OpenCode](https://opencode.ai) for AI assistance
- [dmmulroy/.dotfiles](https://github.com/dmmulroy/.dotfiles) for CLI and
  architecture inspiration

## License

MIT - See LICENSE file for details
