# /complete-next-task

Complete the next highest-priority pending task end-to-end.

## Process

1. Find next ready task from active plan state.
2. Implement minimal safe change.
3. Run required validation (tests/lint/typecheck as applicable).
4. Update task state and progress notes.
5. Commit using git when work is verified.

## Notes

- Use git + gh only.
- Prefer one task at a time.
