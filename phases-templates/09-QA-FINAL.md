# Phase 09 — Final QA

## Goal

An independent audit before delivery. **Nothing new is designed** here: what exists gets
verified and fixed.

## How it runs

1. **Launch `design-qa`** over every route. It returns verified findings with screenshots.
2. **Launch `functional-qa`** over each functional flow, if the project has a backend.
3. `frontend-build` and `backend-build` fix the findings by severity, from the top down.
   Each fix is its own unit of work, with its branch and its commit.
4. The relevant QA is run again to confirm what was fixed stays fixed — and that nothing
   else broke along the way.

Both QA agents can run in parallel: they audit different things and do not overlap.

## Closing criteria

- [ ] Zero open **critical** findings, in both QAs.
- [ ] **High** findings fixed, or documented with the reason and accepted by César.
- [ ] Medium and low ones recorded in `decisions/` (one `D0NN-<topic>.md` per decision,
      category QA) even if not fixed — deciding not to fix is also a decision, and it is
      worth having it written.
- [ ] `functional-qa`'s "Actions for César" section is resolved or explicitly postponed.
- [ ] `CONTENT_CHECKLIST.md` reviewed: which real content is still pending for launch.
- [ ] Status screens and brand assets reviewed (`design-qa` §8b; OG card on the deployed URL).
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
