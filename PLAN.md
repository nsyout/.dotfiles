# PLAN.md

## Goal

Rewrite this dotfiles repo from multiple disjoint scripts into a single profile-aware `dot` CLI, while keeping Zsh and supporting reusable personal/work setups from one repository.

## Decisions Locked

- Profile source of truth: **local state file** (not hostname inference)
- Work profile behavior: **auto-skip personal-only steps**
- Work `.config` exclusion (initial): **skip `.config/claude` only**
- Keep shell: **Zsh** (no Fish migration)
- Adopt `just`; do **not** adopt `doppler`
- Import OpenCode command/skill framework from source repo
- Exclude Cloudflare-specific OpenCode content (`skill/cloudflare/**`, `command/cloudflare.md`)
- VCS policy for imported OpenCode workflows: **git-only** (no jj routing)

## Scope

### In Scope

- Introduce a single user-facing `dot` command
- Add profile system: `base`, `personal`, `work`
- Refactor setup/update/bootstrap flows into modular commands
- Split package management by profile
- Standardize stow deployment model
- Use `dot` as the single supported command surface (no legacy wrappers)
- Add diagnostics (`dot doctor`) with severity model and profile drift checks

### Out of Scope (for this rewrite)

- Fish shell configuration/completions/benchmarks
- Full rewrite of all Zsh custom functions unrelated to install/update lifecycle
- Aggressive app/config pruning beyond explicitly agreed profile gates
- Cloudflare OpenCode skill/command pack
- jj-first workflow assumptions in imported AI configs

## Target UX

### Core Commands

- `dot profile set|get|show`
- `dot bootstrap`
- `dot init`
- `dot update`
- `dot stow`
- `dot packages sync|check|cleanup`
- `dot doctor`
- `dot edit`
- `dot git setup`
- `dot ssh configure|sync-yubikey-keys|status`
- `dot restic setup` (personal-only)
- `dot wallpaper set [path]`

### Global Flags

- `--yes` (non-interactive)
- `--dry-run`
- `--verbose`
- command-specific skips: `--no-firefox`, `--no-fonts`, etc.

## Profile Model

### `base` (always)

Shared essentials safe for both personal and work:
- core shell setup
- common CLI tools
- generic editor/tmux/git baseline
- common stow packages

### `personal` overlay

Personal-only:
- restic setup and configs
- private/personal font flow
- personal identity/signing overlays
- personal-only app/config modules

### `work` overlay

Work-safe:
- work identity/signing overlays
- work package additions
- excludes personal-only modules
- excludes stowing `.config/claude`

## Architecture

### Entry Point

- Add root-level `dot` Bash script as dispatcher (single command surface)

### Internal Libraries

- `scripts/lib/common.sh` (logging, prompt helpers, guards, shared utils)
- `scripts/lib/profile.sh` (local profile state read/write + resolution)
- `scripts/lib/stow.sh`
- `scripts/lib/packages.sh`
- `scripts/lib/cmd_bootstrap.sh`
- `scripts/lib/cmd_init.sh`
- `scripts/lib/cmd_update.sh`
- `scripts/lib/cmd_git.sh`
- `scripts/lib/cmd_restic.sh`
- `scripts/lib/cmd_ssh.sh`
- `scripts/lib/cmd_doctor.sh`
- `scripts/lib/cmd_wallpaper.sh`

### Compatibility Layer

- No legacy wrapper scripts retained.
- `dot` is the only supported command surface for bootstrap/init/update flows.

## Stow Strategy

Current broad stow behavior is inconsistent across setup/update flows. Replace with explicit package groups.

### Proposed package groups

- `stow/base-shell`
- `stow/base-dev`
- `stow/base-ui`
- `stow/personal-*`
- `stow/work-*`

Profile manifests decide which groups are applied.

## Package Strategy

Split Brewfile by profile:

- `Brewfile.base`
- `Brewfile.personal`
- `Brewfile.work`

`dot packages sync` installs base + active overlay.

## Personal-Only Tagging Policy

Any module/step must declare one of:

- `base`
- `personal_only`
- `work_only`

`dot` runner enforces profile gating automatically.

Initial personal-only modules:
- restic setup/config
- private fonts flow
- stow of `.config/claude`

## Interactivity Policy

Default behavior: minimally interactive and automation-friendly.

Prompt only for:
- physical security device actions (YubiKey insert/switch)
- secrets/token entry
- destructive overwrite when `--yes` is not passed

All other choices should be flag/config driven.

## Severity Model (`dot doctor` and runtime checks)

- `fatal` -> non-zero exit (missing core dependencies, critical stow failure, invalid profile state)
- `warn` -> continue (optional components unavailable, macOS updates available, minor drift)
- `info` -> status only

macOS updates are warnings, not fatal.

## Source-Material Features to Adopt (Non-Fish)

From the reference `dot` design, adopt/adapt:

1. Single `dot` command with subcommands
2. `link` / `unlink` for globally available `dot`
3. `packages` subcommands: add/remove/list/update with `base|work` targets
4. `check-packages` for installed vs manifest drift
5. `retry-failed` package installs
6. `doctor` with actionable diagnostics
7. `ssh` command for YubiKey resident-key workflows (`configure`, `sync-yubikey-keys`, `status`)

Optional later:
- `summary` command using OpenCode for commit summaries
- advanced install-source diagnostics (if OpenCode install methods diverge)

## Suggested Tool Imports from Reference Repo

Useful candidates to consider adding to this repo (if aligned):
- `just` (adopt)
- `ast-grep` (consider)
- `doggo` (consider)
- `watchman` (optional, later)

Not adopting:
- Fish-specific tooling and benchmark/completion machinery
- `doppler`
- `gnupg` (for now)

## Package Adoption Decisions

Do not adopt (explicit):
- `cmake`, `fish`, `fisher`, `fnm`, `gnupg`, `stylua`
- casks: `arc`, `cleanshot`, `datagrip`, `discord`, `elgato-*`, `scroll-reverser`, `yaak@beta`, `spotify`

Adopt now:
- `just`

Defer for later review:
- `ast-grep`, `doggo`, `jj`

## OpenCode Integration Plan

Import commands:
- `/plan-spec`
- `/code-review`
- `/index-knowledge`
- `/opensrc`
- `/overseer`
- `/overseer-plan`
- `/complete-next-task` (optional)

Import skills:
- `spec-planner`
- `index-knowledge`
- `librarian`
- `overseer`
- `overseer-plan`
- `build-skill` (optional)
- `vcs-detect` (patched to git-only behavior)

Remove from imported set:
- `skill/cloudflare/**`
- `command/cloudflare.md`

Patch imported docs/prompts:
- strip jj references and command mappings
- enforce git + gh usage
- keep existing opensrc workflow behavior

## Migration Phases

### Phase 0: Contract and Inventory

- freeze command names, profile semantics, and module tags
- map existing scripts/steps to `base|personal_only|work_only`

### Phase 1: `dot` Skeleton

- implement dispatcher + `help`
- add `profile set|get|show` with local state file
- add `link/unlink/edit`

### Phase 2: `dot update` + `dot stow` + `dot packages`

- move update path first (lower risk)
- unify stow behavior under one implementation
- wire profile-aware package sync/check/cleanup

### Phase 3: `dot init`

- migrate setup flow with modular steps + flags
- preserve behavior parity while reducing prompts

### Phase 4: `dot bootstrap`

- convert bootstrap to base/system-first orchestration
- enforce profile gating for personal-only steps

### Phase 5: Specialized Modules

- migrate restic/firefox/fonts/wallpaper/git setup to modular commands
- enforce `personal_only` for restic and `.config/claude`

### Phase 6: OpenCode Import + Policy Alignment

- import selected OpenCode commands/skills
- prune Cloudflare command/skill content
- patch imported workflows to git-only assumptions
- validate OpenCode command discovery/loading
- document command set in README + AGENTS

### Phase 7: Docs + Cleanup

- update README + AGENTS docs for dot-only workflows
- remove any stale references to legacy script entrypoints

## Validation Gates (every phase)

- `shellcheck dot scripts/lib/*.sh`
- `bash -n dot scripts/lib/*.sh`
- `zsh -n .config/zsh/.zshrc .config/zsh/.zshrc.d/*.zsh .config/zsh/*.zsh`
- smoke checks:
  - `dot profile set work && dot init --dry-run`
  - `dot profile set personal && dot init --dry-run`
  - `dot update --dry-run`
  - `dot doctor`

## Acceptance Criteria

- One command surface (`dot`) replaces direct user use of setup/update/bootstrap scripts
- Work profile never applies personal-only modules by default
- `.config/claude` is excluded on work profile
- Restic is personal-only and blocked/skipped on work profile
- Profile-aware package + stow behavior is deterministic
- Core shell scripts pass lint/syntax checks (or have documented intentional exceptions)
- Existing workflows preserved with clear, documented behavior changes
- OpenCode command set is available without Cloudflare content
- Imported OpenCode workflows operate with git-only assumptions
- `just` is included in package strategy

## Risks and Mitigations

- Risk: behavior regression during migration
  - Mitigation: phase-by-phase parity checks with targeted smoke validation
- Risk: hidden personal/work coupling
  - Mitigation: explicit module tagging and doctor drift checks
- Risk: stow conflicts and user-state drift
  - Mitigation: consistent stow engine + backup/conflict strategy
