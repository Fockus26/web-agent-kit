# Phase 09 — Final QA (version QA)

## Goal

An independent audit before delivery. **Nothing new is designed** here: what exists gets
verified and fixed.

This is **the** full QA of a version. During development only the risk flows get
`functional-qa` (`git-flow` 5b, `wave-qa` in waves); `design-qa` runs here and nowhere
else. Why: a `design-qa` per page or per change re-audited the whole screen range for every
piece and was the most expensive QA in tokens; the visual defects it found were classes
that one sweep at the end fixes at once (César, 2026-10-23).

**Later versions** of a project already delivered run this same phase before César merges
the `chore(release): version` PR (or, without versioning, before he deploys to production),
with the scope of what changed: `git diff --name-only <sha>..origin/main`, where `<sha>` is in
the header of the previous `context/plans/qa-version-*.md`. Routes and flows whose files
did not change are not walked again, except a smoke pass.

## How it runs

1. **Launch `design-qa`** over every route (or the changed ones). It returns verified
   findings with screenshots, one reproduction script per finding.
2. **Launch `functional-qa`** over each functional flow, if the project has a backend — the
   whole adversarial list, including the flows that already passed a risk QA.
3. Save both reports to `context/plans/qa-version-<version>.md` with `main @ <sha>` in the
   header: it is the next version's starting point.
4. `frontend-build` and `backend-build` fix the findings by severity, from the top down.
   Each fix is its own unit of work, with its branch and its commit; a finding that is a
   class is swept whole (the `grep` pattern over `src/`, the measuring script versioned).
5. **Each fix is closed by its reproduction script** (FAIL on `main`, PASS on the branch),
   not by another QA: a second full QA of the fixes is what turned world-flags into four
   rounds.
6. Each class found here that the kit could have prevented → a row in
   `context/KIT_FEEDBACK.md` for `reference/QA-PREVENTION.md` (the QA reports bring it).

Both QA agents can run in parallel: they audit different things and do not overlap. Model
and effort per `TOKEN-ECONOMY.md` §12.

## Closing criteria

- [ ] Zero open **critical** findings, in both QAs.
- [ ] **High** findings fixed, or documented with the reason and accepted by César.
- [ ] Medium and low ones recorded in `decisions/` (one `D0NN-<topic>.md` per decision,
      category QA) even if not fixed — deciding not to fix is also a decision, and it is
      worth having it written.
- [ ] `functional-qa`'s "Actions for César" section is resolved or explicitly postponed.
- [ ] `CONTENT_CHECKLIST.md` reviewed: which real content is still pending for launch.
- [ ] Status screens and brand assets reviewed (`design-qa` §8b; OG card on the deployed URL).
- [ ] `context/plans/qa-version-<version>.md` saved with the sha.
- [ ] `CURRENT_PHASE.md` and `PHASE_LOG/09-qa.md` closed, and `bun run context:backup`.
- [ ] **Kit feedback** sent with `/kit-feedback` (PR on the kit's repo), if there are unsent
      rows in `context/KIT_FEEDBACK.md`.

## Delivery

When closing, produce a summary for César (in Spanish) with:

- What was audited and with which coverage (`design-qa`'s matrix).
- What was fixed.
- What remains open and why.
- What real content is missing to be able to launch.
- What manual actions remain on his side.
