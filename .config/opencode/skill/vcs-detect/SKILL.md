# vcs-detect

Normalize git repository context and workflows.

## Policy

- Use `git` + `gh` for status/log/diff/commit/push operations.

## Output

- VCS type: `git`
- Repository root path
- Current branch/bookmark and working-tree state
- Recommended next command(s) using the detected VCS

## Detection

```bash
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo "git"
```
