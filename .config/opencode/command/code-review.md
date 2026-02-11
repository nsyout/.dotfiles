# /code-review

Review changes and report actionable findings.

## Inputs

- Diff/changed files, optional focus guidance

## Output

- Findings by severity (`high`, `medium`, `low`)
- File references and concrete fix suggestions

## Notes

- Use git + gh only.
- Default to uncommitted diff; if clean, review latest commit.
