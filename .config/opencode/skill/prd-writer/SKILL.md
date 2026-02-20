---
name: prd-writer
description: Produces implementation-ready PRDs from rough ideas through a clarification-first workflow. Use when asked to write a PRD, formalize an idea, turn notes into requirements, or scope a feature before implementation spec planning.
references:
  - references/templates.md
  - references/checklist.md
  - references/question-bank.md
  - references/worked-example.md
---

# PRD Writer

Create high-quality PRDs at `workflow/PRD.md`, then hand off to `spec-planner`.

## Use This Skill When

- User asks to "write a PRD", "formalize this idea", "turn this into requirements", or "help scope this feature"
- Work is in Phase 0 (what/why/scope), before implementation planning
- Inputs are rough notes, links, docs, partial drafts, or mixed-quality materials

## Hard Rules

1. Clarification comes first. Do not draft a PRD before at least one question round.
2. Ingest all provided materials before writing.
3. Separate and preserve: Confirmed Facts, Assumptions, Open Questions.
4. Flag contradictions explicitly when sources conflict.
5. Focus on what and why before how; avoid premature solution design.
6. Always write output to `workflow/PRD.md` using deterministic heading order.
7. If critical info is missing, still write a draft with `TODO:` markers.
8. Do not generate task breakdown unless explicitly requested.

## Workflow

### Phase 1: Clarify (Mandatory)

- Ask 4-8 high-leverage questions using the `question` tool
- Cover problem, users, scope boundaries, constraints, success metrics, and risks
- If inputs are very complete, still ask at least 2 confirmation questions

### Phase 2: Ingest and Reconcile Inputs

- Extract facts from notes/docs/links/user messages
- Build three lists:
  - Confirmed Facts
  - Assumptions
  - Open Questions
- Build a contradiction list: `Source A` vs `Source B` + impact

### Phase 3: Draft PRD (Deterministic)

- Use template and exact heading order from `references/templates.md`
- Fill unknowns with `TODO:` and mirror those items in `Open Questions`
- Keep language concrete, concise, and testable

### Phase 4: Quality Gate

- Run checks in `references/checklist.md`
- Tighten ambiguous requirement language (replace "fast", "easy", "robust", etc.)
- Ensure acceptance criteria are pass/fail testable

### Phase 5: Write and Handoff

1. Write final markdown to `workflow/PRD.md`
2. Confirm path in response: `PRD written to workflow/PRD.md`
3. Add `Next Step` section instructing handoff to `spec-planner`
4. If user explicitly asks, include optional `Appendix: Candidate Deliverables` (short)

## Output Contract

The PRD must contain these sections in this order:

1. Title / Problem Statement
2. Users / Stakeholders
3. Goals and Non-Goals
4. Scope (In / Out)
5. Constraints (Technical, Org, Timeline)
6. Functional Requirements
7. Non-Functional Requirements
8. Acceptance Criteria (Testable)
9. Success Metrics
10. Risks and Mitigations
11. Dependencies
12. Rollout / Milestones (High Level)
13. Open Questions
14. Decision Log (Initial)
15. Next Step

## Usage Examples

### Greenfield idea from scratch

"Help me write a PRD for a self-serve data export feature."

### Existing messy notes to formal PRD

"Turn these meeting notes and docs into a PRD with clear requirements and acceptance criteria."

### Partial PRD refinement

"This PRD draft is incomplete. Fill gaps, resolve ambiguities, and rewrite it to implementation-ready quality."

## References

- `references/templates.md` - Canonical PRD template and deterministic heading order
- `references/checklist.md` - Completeness and quality checks
- `references/question-bank.md` - Clarification questions by category
- `references/worked-example.md` - End-to-end example
