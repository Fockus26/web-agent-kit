# Current Phase — {{PROJECT_NAME}}

> **A board, not a diary.** It is read in *every* session, so it fits on one screen:
> **≤ 60 lines / 4 KB**. Only what is open, what blocks and what comes next.
> When a unit closes, its narrative (what was done, what was verified and what was not,
> findings) goes to `PHASE_LOG/<branch>.md` and at most one line with the link stays here.
> Check when closing: `wc -c context/CURRENT_PHASE.md` → over 4000, prune.
> Local file: backed up with `bun run context:backup` (branch `context-state`).

## Now

**Phase:** {{0N — Name}} · **Track:** {{Landing | Site | Product}}
**Wave:** {{N of M · in progress | QA | closed → next N+1}} · plan: `plans/{{phase-0N-name}}.md`
(no waves: delete this line)

| Unit | Branch | Status | Log |
|---|---|---|---|
| {{Hero}} | `{{design/hero}}` | {{open · PR #N in review · merged}} | `PHASE_LOG/{{design-hero}}.md` |

## Blocked (actions for César or external)

- {{e.g. "run supabase/x.sql before deploying PR #N"}}

## Next

- {{the next unit or decision}}

## Phases

| # | Phase | Status |
|---|---|---|
| 01 | Tokens | {{pending}} |
| 02 | Base layout | {{pending}} |
| 03 | Components | {{pending}} |
| 04 | Sections | {{pending}} |
| 05 | Pages | {{pending / N/A}} |
| 06 | States | {{pending}} |
| 07 | Backend | {{pending / N/A}} |
| 08 | Responsive and polish | {{pending}} |
| 09 | Final QA | {{pending}} |

<!-- Loose backlog items that are not the current unit's: context/plans/backlog.md (one per
     block, with what/why/version), not here. -->
