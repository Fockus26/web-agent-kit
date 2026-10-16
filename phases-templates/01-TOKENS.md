# Phase 01 — Tokens

## Goal

Bring the handoff's value system into the code, so that from here on no component needs a
loose value.

## Scope

- Light and dark colors in the chosen library's theme system (`tailwind.config` / `@theme`
  with Tailwind; `createTheme()` with MUI).
- Type scale: size, line height, weight and tracking per role.
- Spacing scale, radii, shadows, durations and curves, z-index.
- Theme switching mechanism (if there is dark mode) and respect for `prefers-color-scheme`.
- Fonts loaded with `next/font`, `display: 'swap'`.

## Inputs

`design/HANDOFF.md` §1 · `context/COLORS.md` · `TYPOGRAPHY.md` · `DESIGN_TOKENS.md`

## Units of work

1. Colors + light/dark theme (including `selection` and `scrollbar`)
2. Typography + font loading
3. Spacing, radii, shadows, motion, z-index

## Closing criteria

- [ ] Every handoff token exists in the theme, with the same semantic name.
- [ ] The contrast ratios declared in the handoff are verified in the real theme.
- [ ] Dark mode switches correctly and without a flash on load.
- [ ] There is a reference page or route showing all the tokens together, to review them at
      a glance. Worth it: it is where inconsistencies get caught before they spread.
- [ ] `COLORS.md`, `TYPOGRAPHY.md` and `DESIGN_TOKENS.md` reflect what was implemented.

## Frequent ambiguity

A handoff token that does not reach AA. **The accessibility rule wins.** Propose the
adjustment (usually a darker shade for text, keeping the original for surfaces), escalate
it, and record it as a decision.
