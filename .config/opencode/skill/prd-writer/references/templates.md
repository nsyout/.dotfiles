# PRD Template (Deterministic)

Use this template exactly. Keep heading order stable.

```markdown
# [Feature / Initiative Title]

## Title / Problem Statement
[One paragraph: who has what problem, why now, and expected business/user impact.]

## Users / Stakeholders
- Primary users: [roles/personas]
- Secondary users: [roles/personas]
- Stakeholders: [teams/owners]

## Goals and Non-Goals
### Goals
- [Outcome-focused goal]
- [Outcome-focused goal]

### Non-Goals
- [Explicitly out of scope]
- [Explicitly out of scope]

## Scope (In / Out)
### In Scope
- [Included capability/process]

### Out of Scope
- [Excluded capability/process]

## Constraints (Technical, Org, Timeline)
- Technical: [platform limits, architecture boundaries, compliance constraints]
- Org: [staffing, ownership, cross-team dependencies]
- Timeline: [target dates, immovable deadlines]

## Functional Requirements
FR-1: [System must ...]  
FR-2: [System must ...]  
FR-3: [System must ...]

## Non-Functional Requirements
NFR-1: [Performance/reliability/security/usability requirement with measurable target]
NFR-2: [Measurable target]

## Acceptance Criteria (Testable)
- [ ] AC-1: [Given/When/Then or clear pass/fail condition]
- [ ] AC-2: [Given/When/Then or clear pass/fail condition]
- [ ] AC-3: [Given/When/Then or clear pass/fail condition]

## Success Metrics
- Metric 1: [definition] | Baseline: [value] | Target: [value] | Window: [time]
- Metric 2: [definition] | Baseline: [value] | Target: [value] | Window: [time]

## Risks and Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk] | [Low/Med/High] | [Low/Med/High] | [Plan] |

## Dependencies
- [Dependency] - owner: [team/person] - status: [not started/in progress/confirmed]

## Rollout / Milestones (High Level)
- M1: [milestone name] - [target window]
- M2: [milestone name] - [target window]
- M3: [milestone name] - [target window]

## Open Questions
- [ ] OQ-1: [question] - owner: [team/person] - needed by: [date]
- [ ] OQ-2: [question] - owner: [team/person] - needed by: [date]

## Decision Log (Initial)
- [YYYY-MM-DD] [Decision summary] - rationale: [why]

## Next Step
Hand off this PRD to `spec-planner` to produce the implementation strategy and sequencing. Do not produce task breakdown unless explicitly requested.

<!-- Optional; include only when user asks -->
## Appendix: Candidate Deliverables
- [Deliverable 1]
- [Deliverable 2]
```

## Authoring Rules

- If required data is missing, use `TODO:` inline and mirror it in `Open Questions`.
- Requirements must be specific and verifiable.
- Prefer "must" over weak language like "should" unless truly optional.
- Call out contradictions with source references before finalizing.
