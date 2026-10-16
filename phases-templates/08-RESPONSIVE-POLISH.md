# Phase 08 — Responsive and polish

## Goal

Go over everything built and fix the drift. Unlike phase 09, here things **do get fixed**,
not just reported.

## Scope

- Each page at each breakpoint of the project: 320 · 360 · 390 · 768 · 1024 · 1440 · 1920
  {{· 2560 · 3840}}.
- Mobile in landscape and short-height screens.
- Zoom at 200% and 400%.
- Token consistency: zero magic values, spacings from the scale, consistent radii.
- Consistency across pages: the same elements look the same on all of them.
- Consistent hover and focus across equivalent elements.
- Dark mode reviewed everywhere, not just where it was tested.
- `prefers-reduced-motion` respected.

## Inputs

Everything implemented · `design/HANDOFF.md` · `context/DESIGN_RULES.md`

## Closing criteria

- [ ] No horizontal scroll at any width, on any page.
- [ ] No cut or overlapping text at any breakpoint.
- [ ] `grep -rnE '\[[0-9]+px\]|\[#[0-9a-fA-F]{3,8}\]' components/ app/` clean or justified.
- [ ] Consistent vertical rhythm between equivalent sections.
- [ ] Touch targets ≥44px on mobile.
- [ ] Dark mode reviewed on every page.
- [ ] Fixes recorded in `decisions/` (one `D0NN-<topic>.md` per decision, category Responsive).

## Frequent ambiguity

A responsive fix with more than one reasonable path (how a 4-column grid collapses, where a
wide table gets cut): 3 options and wait.
