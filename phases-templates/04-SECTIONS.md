# Phase 04 — Sections

## Goal

The page sections, in the vertical order the handoff defines.

## Scope

- One section per unit of work, in order.
- Each one's layout per the handoff's §3: grid, columns, gaps, max width.
- Explicit responsive behavior at each breakpoint — not "it is responsive".
- Real content where it exists; a flagged, logged placeholder where it does not.
- Correct heading hierarchy within the page.

## Inputs

`design/HANDOFF.md` §3 · `sections-template/TEMPLATE-SECTION.md` for the content brief ·
phases 01-03 closed

## Closing criteria per section

- [ ] Matches the handoff in structure, spacing and responsive behavior.
- [ ] Uses components from the inventory; if it created a new one, it is registered.
- [ ] Heading of the right level, no skips.
- [ ] Images with explicit dimensions and a real `alt` or a logged placeholder.
- [ ] No horizontal scroll at 320px.
- [ ] `a11y` gate green.
- [ ] `seo` skill run if the section brings real content.
- [ ] Row in `SECTION_INVENTORY.md`.

## Frequent ambiguity

How a multi-column layout collapses on mobile: do they stack in the same order, reorder, or
does something get hidden? If the handoff does not say, it is a mandatory question — hiding
content on mobile is a product decision, not an implementation one.
