# context-templates/

Copied into every new project as `context/`. It is the project's **living documentation**:
what lets a new Claude session start knowing exactly where everything stands, without César
having to rebuild the state by hand every time.

`project-kickoff` fills it at kickoff and `frontend-build` and `backend-build` keep it up to
date when each unit of work closes.

## What is here

| File | What it holds | Who maintains it | Where it lives |
|---|---|---|---|
| `PROJECT_CONTEXT.md` | What the project is, for whom, with which stack | `project-kickoff` | git |
| `DESIGN_RULES.md` | What is never negotiated | `project-kickoff` | git |
| `COLORS.md` | Light/dark palette with verified ratios | `project-kickoff`, then `frontend-build` | git |
| `TYPOGRAPHY.md` | Families and scale | same | git |
| `DESIGN_TOKENS.md` | Spacing, radii, shadows, motion, z-index | same | git |
| `decisions/` | One file per decision; its first line is the index row | whoever decides | git |
| `COMPONENTS_INVENTORY.md` | Which components exist and where | `frontend-build` | local |
| `SECTION_INVENTORY.md` | Which sections exist, on which page | `frontend-build` | local |
| `PAGE_INVENTORY.md` | Which routes exist | `frontend-build` | local |
| `CONTENT_CHECKLIST.md` | All pending real content | everyone | local |
| `CURRENT_PHASE.md` | Where we are now | whoever closes the phase | local |
| `PHASE_LOG/` | The narrative of each unit (per branch) and each closed phase | whoever closes the unit | local |
| `GIT_STATE.md` | Mode (`pr` / `local`) and base branch | `git-flow` | local |
| `KIT_FEEDBACK.md` | Corrections, repetitions, gaps and friction with the kit; sent with `/kit-feedback` | whoever closes the unit | local |
| `plans/` | Phase/wave plans, batch briefs, backlog, QA reports | `orchestrate` | local |

**git**: what a new session needs to know what was decided and how the site looks; losing
the local folder must not lose it. **local**: the working state — parallel workers would
collide on it in every PR — backed up to the orphan branch `context-state` with `bun run
context:backup` and restored with `bun run context:restore` (only on private repos: the
checklist may hold client data).

## How it is read (and what it costs)

| Level | Files | How |
|---|---|---|
| Always | `CURRENT_PHASE.md` (≤ 60 lines) | Read whole, in every session |
| Per task | `DESIGN_RULES`, `COLORS`, `TYPOGRAPHY`, `DESIGN_TOKENS`, `PROJECT_CONTEXT` | Only if the task touches that (table in `CLAUDE.md`) |
| Search | `decisions/`, `CONTENT_CHECKLIST`, inventories, `PHASE_LOG/`, `KIT_FEEDBACK` | `grep` by word or ID; open only what comes up |

That is why the "always" files have a cap and the "search" ones have one-line rows. Details
in the kit's `reference/TOKEN-ECONOMY.md`.

## The three rules that keep it useful

1. **It is updated when each unit closes, not "later".** Skipping this step feels efficient
   at the moment and costs half an hour of reconstruction in the next session.

2. **No `{{placeholder}}` survives kickoff.** If a value does not exist yet, an explicit
   `PENDING` is written and the row is added to `CONTENT_CHECKLIST.md`. A `{{TONE}}` that
   reaches phase 6 alive is an agent making decisions blind.

3. **What is always read gets pruned when each unit closes.** `CURRENT_PHASE.md` keeps what
   is open; what is closed goes to `PHASE_LOG/<branch>.md`. A board that turns into a diary
   is paid for in every session.

## Why it is split into so many files

A single monolithic `DESIGN_DECISIONS.md` grows without limit and halfway through a real
project can no longer be read. Split by category, each file stays short, decisions go one
per file (their header is the index, through `grep`, and two PRs do not collide), and
`CURRENT_PHASE.md` can stay on one screen because the narrative of what is closed goes to
`PHASE_LOG/`.

Projects created before kit 3.8.0 have these files in Spanish (same structure): they stay as
they are.
