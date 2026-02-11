# vcs-detect

Detect repository VCS context and normalize workflows.

## Policy

- This setup is git-only.
- Use `git` and `gh` for all VCS/GitHub operations.
- Do not route to alternate VCS CLIs.

## Output

- Current branch and working-tree state
- Recommended next git command(s)
