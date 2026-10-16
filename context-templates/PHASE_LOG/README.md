# PHASE_LOG/

The narrative of what is closed. **One file per unit** (per branch) and, when a whole phase
closes, a phase summary. Consulted with `grep` or when `CURRENT_PHASE.md` links to one; not
read by default.

## Why

`CURRENT_PHASE.md` is read in every session and has to fit on one screen. Everything that
explains *how* something was closed (what was verified, what was not, findings seen in
passing) grows without limit if it lives there — in the first real project it reached
38 KB. Here it bothers nobody: only whoever looks for it pays for it.

## Name

- Unit: `PHASE_LOG/<branch-with-dashes>.md` (e.g. `feat-ranking-top20.md`).
- Whole phase: `PHASE_LOG/0N-<phase>.md`, linking to its units' files.

## Format (unit)

```markdown
# <branch> — <what> (PR #N · changeset patch/minor/major or none)

## Status
<open / in review / merged on YYYY-MM-DD>

## What was done
- <2-5 bullets>

## Verified (and how)
- <what, at which widths/themes, with which tool>

## Not verified
- <what and why: no test account, no real device…>

## Decisions
- D0NN — <1 line> (detail in decisions/D0NN-<topic>.md)

## Provisional content
- CONTENT_CHECKLIST row #NN — <which text>

## Actions for César
- <SQL to run, dashboard to configure, deploy order>

## Seen in passing (not touched)
- <bugs outside the unit, for another branch>
```

## Rules

- Written by whoever closes the unit, before the PR / the local merge.
- If a worker did the unit in a worktree without write access to the main folder, it
  delivers it in its report and the orchestrator copies it here.
- `CURRENT_PHASE.md` only keeps the unit's row with the link to this file.
- It is local: `bun run context:backup` keeps it on the `context-state` branch.
