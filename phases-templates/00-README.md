# phases/

One phase per file. Each phase runs to completion before moving to the next, and is made of
**units of work** — each unit is one branch, one approval (the PR review, or the pause in
`local` mode) and one commit or PR.

## The full set

| # | Phase | Who runs it |
|---|---|---|
| 01 | Tokens | `frontend-build` |
| 02 | Base layout | `frontend-build` |
| 03 | Components | `frontend-build` |
| 04 | Sections | `frontend-build` |
| 05 | Pages | `frontend-build` |
| 06 | States | `frontend-build` |
| 07 | Backend | `backend-build` |
| 08 | Responsive and polish | `frontend-build` |
| 09 | Final QA (version QA: the only `design-qa`) | `design-qa` + `functional-qa` |

## Tracks

The orchestrator picks one at kickoff and writes it in `PROJECT_CONTEXT.md`.

| Track | Phases | When |
|---|---|---|
| **Landing** | 01 · 02 · 03 · 04 · 06 · 08 · 09 | A single page. Skips 05 (the page is assembled in 04) and 07 unless there is a form that really submits. |
| **Site** | 01 - 06 · 08 · 09 | Corporate or multi-page without a heavy backend. |
| **Product** | 01 - 09 | E-commerce, SaaS, dashboard: anything with auth, payments or user data. |

Choosing too much is as bad as choosing too little: an empty phase is ceremony without real work.

## A phase in waves

A phase with several independent units is done with `orchestrate` ("start phase 04"): it
splits it into **waves**, and each wave runs in its own session — parallel workers, PRs,
merge, wave QA (`wave-qa`, logged in with the test accounts) and a closing that says which
phase and wave we are in and which comes next. That way no session drags the whole phase's
context. A phase of one or two units is done by hand, unit by unit.

## Common rule for all

- Each phase closes by updating `context/`: the relevant inventory, `decisions/`,
  `CONTENT_CHECKLIST.md`, `PHASE_LOG/0N-<phase>.md` and `CURRENT_PHASE.md` — and backing up
  the local state (`bun run context:backup`).
- No phase closes with the `a11y` gate red.
- If something is ambiguous: exactly 3 options, with real advantage and disadvantage, and wait.
- If a handoff value is missing: ask, **do not estimate it from the mockup**.
