# Worked Example: Messy Notes to PRD

## Input Snippets (Condensed)

- "Users keep asking for CSV export of invoice history."
- "Need enterprise admin controls, maybe later."
- "Sales promised top account by end of Q2."
- "Finance says exports must include tax fields."
- "Current export takes 2-3 minutes and times out sometimes."

## Extraction Pass

### Confirmed Facts

- Users request invoice history export.
- Finance requires tax fields in exports.
- Current export performance is unreliable.

### Assumptions

- v1 targets CSV only (not PDF/XLSX).
- Enterprise admin controls are out of scope for v1.

### Open Questions

- Which user roles can initiate exports?
- Maximum date range allowed per export?
- Is Q2 commitment contractual or best-effort?

### Contradictions

- Sales promises Q2 delivery, but engineering notes show unresolved timeout issues.
- Impact: schedule risk; requires milestone realism and mitigation.

## Example PRD Skeleton (Abbreviated)

```markdown
# Invoice History CSV Export

## Title / Problem Statement
Finance and operations users need reliable invoice history exports for reconciliation. Current exports are slow and unreliable, causing manual work and support escalations.

## Users / Stakeholders
- Primary users: Finance analysts, operations managers
- Stakeholders: Finance, Support, Sales, Backend team

## Goals and Non-Goals
### Goals
- Provide reliable CSV export for invoice history with tax fields.
- Reduce export failure rate for supported date ranges.

### Non-Goals
- Role redesign and enterprise admin control panel in v1.

## Scope (In / Out)
### In Scope
- CSV export from invoice history screen for authorized users.

### Out of Scope
- PDF/XLSX formats.

## Constraints (Technical, Org, Timeline)
- Technical: Existing export service has timeout risk.
- Org: Finance sign-off required for tax field coverage.
- Timeline: TODO: confirm whether Q2 target is contractual.

## Functional Requirements
FR-1: System must allow authorized users to export invoice history as CSV.
FR-2: System must include required tax fields defined by Finance.

## Non-Functional Requirements
NFR-1: 95% of exports for <= 12 months complete within 30 seconds.
NFR-2: Export job failure rate must be <1% weekly.

## Acceptance Criteria (Testable)
- [ ] AC-1: Given authorized user and <=12-month range, export completes within 30 seconds.
- [ ] AC-2: CSV includes all required tax fields from Finance schema.

## Success Metrics
- Export success rate baseline: TODO: collect; target: >=99% weekly within 30 days post-launch.

## Risks and Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Timeout regressions | Med | High | Load test + staged rollout |

## Dependencies
- Finance field schema approval - owner: Finance lead - status: in progress

## Rollout / Milestones (High Level)
- M1: Schema alignment
- M2: Reliability fixes
- M3: Limited customer rollout

## Open Questions
- [ ] OQ-1: Is Q2 deadline contractual? owner: Sales ops

## Decision Log (Initial)
- [2026-02-19] Chose CSV-only v1 to reduce scope and hit reliability target.

## Next Step
Hand off to `spec-planner` for implementation strategy and sequencing.
```

## Why This Passes

- Distinguishes facts vs assumptions vs unknowns.
- Uses measurable NFRs and testable acceptance criteria.
- Flags schedule contradiction without inventing details.
