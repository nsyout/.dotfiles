# AGENTS.md

Repository guide for agentic coding assistants working in this dotfiles repo.

## Project Type and Scope

- This is a macOS-focused dotfiles repository, not a traditional app/library.
- Primary languages are Bash and Zsh.
- Primary executable entrypoint is root `dot`; supporting scripts live in `scripts/`.
- Interactive shell behavior is in `.config/zsh/`.
- Neovim config is minimal (`.config/nvim/init.lua`).
- Some directories under `.config/zsh/plugins/` are third-party plugin code.

## Source of Truth Layout

- `dot` = single command surface and dispatcher for bootstrap/init/update/profile workflows.
- `scripts/lib/cmd_bootstrap.sh` = bootstrap command implementation.
- `scripts/lib/cmd_init.sh` = init/setup command implementation.
- `scripts/lib/cmd_update.sh` = update command implementation.
- `scripts/lib/cmd_ssh.sh` = SSH/YubiKey resident-key command implementation.
- `scripts/lib/stow.sh` = profile-aware stow package selection + deployment.
- `scripts/lib/packages.sh` = profile-aware package manifest sync/check/cleanup.
- `stow-manifest.base` + `stow-manifest.personal` + `stow-manifest.work` = profile stow manifests.
- `.zshenv` = exported environment defaults and PATH base.
- `.config/zsh/.zshrc` = modular loader for `.zshrc.d/*.zsh`.
- `.config/zsh/.zshrc.d/` = ordered config modules by numeric prefix.
- `.config/zsh/aliases.zsh` and `.config/zsh/scripts.zsh` = user-facing shell UX.
- `Brewfile` + `Brewfile.base` + `Brewfile.personal` + `Brewfile.work` = package manifests.
- `.stow-local-ignore` = what stow should not link.

## Build / Install Commands

Use repo root unless otherwise noted.

- Full setup on existing machine: `./dot init`
- Fresh macOS bootstrap: `./dot bootstrap`
- Update workflow: `./dot update`
- SSH resident key sync: `./dot ssh sync-yubikey-keys --slot primary`
- Install/update packages for active profile: `./dot packages sync`
- Remove packages no longer in active manifests: `./dot packages cleanup`
- Retry failed package manifest installs: `./dot retry-failed`
- Re-link dotfiles manually: `stow --restow .`

## Lint / Validation Commands

There is no single CI pipeline file in this repo currently.
Use targeted checks based on files changed.

- Lint command + libraries: `shellcheck dot scripts/lib/*.sh`
- Lint one command module: `shellcheck scripts/lib/cmd_init.sh`
- Bash syntax check command + libraries: `bash -n dot scripts/lib/*.sh`
- Bash syntax check one command module: `bash -n scripts/lib/cmd_update.sh`
- Zsh syntax check modular config: `zsh -n .config/zsh/.zshrc .config/zsh/.zshrc.d/*.zsh .config/zsh/*.zsh`
- Quick smoke run for update flow: `./dot update --dry-run`

## Test Commands (Including Single-Test)

Repo-level note:
- There is no formal first-party unit test suite for dotfiles scripts.
- Validation is mostly lint + syntax + targeted smoke runs.

Third-party plugin tests (only when editing that plugin code):
- Run all zsh-syntax-highlighting tests:
  `make -C .config/zsh/plugins/zsh-syntax-highlighting test`
- Quiet mode:
  `make -C .config/zsh/plugins/zsh-syntax-highlighting quiet-test`
- Performance tests:
  `make -C .config/zsh/plugins/zsh-syntax-highlighting perf`
- Run a single highlighter test set (closest single-test equivalent):
  `zsh -f .config/zsh/plugins/zsh-syntax-highlighting/tests/test-highlighting.zsh main`
- Run a single highlighter perf test:
  `zsh -f .config/zsh/plugins/zsh-syntax-highlighting/tests/test-perfs.zsh main`

## Code Style Guidelines

Follow existing style in touched files. Prefer minimal, surgical edits.

### Shell Script Baseline (Bash)

- Use shebang: `#!/usr/bin/env bash`
- Start scripts with `set -e` (current repo convention).
- Keep helper logging functions near top: `info`, `warn`, `error`, `step`.
- Use uppercase constants for global config (`DOTFILES_DIR`, `BACKUP_DIR`).
- Use lowercase snake_case for function names (`install_packages`).
- Prefer `local` for function-scoped variables.
- Quote variable expansions unless deliberate word-splitting is needed.
- Prefer `[[ ... ]]` tests over `[` in Bash files.
- Return early on guard checks; fail loudly for unrecoverable states.

### Zsh Config and Functions

- Use shebang: `#!/usr/bin/env zsh` for standalone zsh files.
- Keep modular load order via numeric files in `.zshrc.d/`.
- Source files through `safe_source` where available.
- In functions, use `local` variables and explicit `return 1` on errors.
- Keep user-facing function names concise (`nsy`, `extract`, `trash-size`).
- Use internal helper prefixes for private helpers when present (`_nsy_*`, `_ex`).

### Imports / Sourcing Conventions

- Do not add ad-hoc `source` calls in random files.
- Wire new startup behavior via `.config/zsh/.zshrc.d/<nn>-name.zsh`.
- Keep loader behavior centralized in `.config/zsh/.zshrc`.
- If adding plugins, preserve the order-sensitive loading in `90-plugins.zsh`.

### Formatting and Structure

- Match existing indentation per file (repo commonly uses 2 or 4 spaces).
- Keep long command invocations split with continuation where readability improves.
- Group related logic into small functions rather than large inline blocks.
- Keep comments practical and sparse; prefer self-explanatory code.

### Naming

- Environment/global constants: uppercase (`FZF_DEFAULT_COMMAND`).
- Local temps and loop vars: short lowercase (`file`, `choice`, `count`).
- Functions: lowercase snake_case in Bash; existing style in Zsh.
- Keep aliases short but meaningful; avoid collisions unless intentional override.

### Types and Data Handling

- Shell has no static types: emulate clarity with naming and narrow variable scope.
- For lists, use arrays where already used in file (`files_to_backup`, `key_options`).
- Preserve current data formats (e.g., TOML frontmatter edits in `scripts.zsh`).

### Error Handling

- Use `error "..."` helper for fatal failures in Bash scripts.
- Use `warn "..."` for recoverable issues and continue when safe.
- For optional tooling, gate with `command -v ...` checks.
- For external commands that may fail but are non-critical, follow existing `|| true` patterns sparingly.
- In interactive functions, print clear cancellation/error messages before returning non-zero.

## Safety and Change Policy for Agents

- Do not weaken macOS/security-sensitive defaults without explicit request.
- Keep destructive operations opt-in and prompt-driven in interactive flows.
- Preserve backup behavior and conflict handling in `dot init` / `dot update` flows.
- Avoid editing vendored third-party plugin code unless task explicitly targets it.
- If touching both user code and vendored code, separate rationale clearly in commit/PR notes.

## Cursor / Copilot Rules

Checked paths:
- `.cursor/rules/`
- `.cursorrules`
- `.github/copilot-instructions.md`

Current status:
- No Cursor rules or Copilot instruction file were found in this repository.
- If these files are added later, treat them as authoritative and merge their guidance into this document.

## Agent Workflow Recommendations

- For multi-step tasks, split independent checks and run them in parallel when safe.
- Typical parallelizable checks: `shellcheck`, `bash -n`, and `zsh -n` on touched files.
- Identify dependency order explicitly when steps are not independent.
- After edits, run the narrowest relevant validation first, then broader checks if needed.
