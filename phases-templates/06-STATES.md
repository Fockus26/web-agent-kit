# Phase 06 — States

## Goal

What happens when things do not go as in the mockup. It is the most skipped phase and the
one whose absence shows the most.

## Scope

- **Status screens** (full guide: the kit's `reference/STATUS-SCREENS.md`):
  - 404 — logged-in and guest **only if there is authentication**; otherwise, a single one.
  - 500 with a code (`error.digest`) and without.
  - Offline, chosen in the same `error.tsx` **based on the network** (`navigator.onLine`).
  - Maintenance with a time (in the visitor's zone) and without, through an environment
    variable, with 503 + `Retry-After`.
  - `global-error.tsx` with its own html/body.
  - `/estados?screen=…` gallery in development (blocked in production) to review and
    capture them.
- **Empty:** list with no results, search with no matches, empty cart, no data yet. Each
  with its explanation and its way out.
- **Loading:** skeletons per section (not one global spinner), with Next's `loading.tsx`.
- **Error inside a screen:** form submission failure, network failure on save.
- **Forms:** live validation, per-field error, general error, submitting, success.
- Announcing state changes to screen readers (`aria-live`, `role="alert"`).

Typical units: `feat/screens-404`, `feat/screens-error-offline`, `feat/maintenance`, and one
per family of empty/loading states.

## Inputs

`design/HANDOFF.md` §5b and §7 (designed states) · phases 01-05 closed

## Closing criteria

- [ ] Every list has a designed empty state, not a blank screen.
- [ ] Every load has a skeleton or an indicator; nothing jumps from empty to full.
- [ ] Every error says **what happened and what to do**, not just a code.
- [ ] State changes are announced non-visually.
- [ ] 404, 500, offline and maintenance use the site's design, not the framework's default
      page, and answer with their HTTP status (404 / 500 / 503).
- [ ] Closing criteria of `reference/STATUS-SCREENS.md` met.
- [ ] `a11y` gate green.

## Note

If the handoff did not design these states, do not invent them silently: they are visual
decisions. Ask Claude Design for them with the kit's
`prompts/CLAUDE-DESIGN-ADDENDUM.template.md`; if César prefers not to wait, present 3
options for the general pattern and apply it consistently once chosen.
