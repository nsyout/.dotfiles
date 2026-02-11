# AGENTS.md - Neovim Subtree

Local guidance for `.config/nvim/**`.

## Scope

- Neovim configuration uses a generic `config` namespace.
- Entry point: `.config/nvim/init.lua` -> `require("config")`.

## Structure

- `lua/config/*.lua` = core bootstrap, options, keymaps.
- `lua/plugins/*.lua` = one plugin spec per file.

## Rules

- Keep plugin modules focused and small.
- Prefer git-first tooling; do not introduce `jj` integrations.
- Avoid TypeScript-specific plugin additions unless requested.

## Validation

- `nvim --headless "+lua print('nvim-config-ok')" +qa`
