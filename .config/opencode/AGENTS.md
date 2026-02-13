# AGENTS.md - OpenCode Subtree

Local guidance for `.config/opencode/**`.

## Scope

- User custom commands/skills for OpenCode.
- Keep content practical and coding-focused.

## Policy

- VCS workflows are git-first and use `gh` for GitHub operations.
- Use `gh` for GitHub operations.
- Exclude Cloudflare-specific skill/command content.
- Keep prompts concise with explicit input/output.

## Structure

- `command/*.md` = slash command prompts/docs.
- `skill/*/SKILL.md` = skill instructions.

## Change Guidance

- Keep command behavior deterministic and tool-safe.
- Preserve intent when editing imported prompts.
- Add usage examples for new commands/skills.
