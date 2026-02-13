# vcs-detect

Detect repository VCS context and normalize workflows.

## Policy

- Detect VCS before running status/log/diff/commit/push commands.
- If `jj root` succeeds, prefer `jj` (including colocated `.jj` + `.git` repos).
- Otherwise use `git` + `gh`.

## Output

- VCS type: `jj` or `git`
- Repository root path
- Current branch/bookmark and working-tree state
- Recommended next command(s) using the detected VCS

## Detection

```bash
if jj root >/dev/null 2>&1; then
  echo "jj"
else
  echo "git"
fi
```
