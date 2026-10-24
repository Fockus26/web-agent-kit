# Phase 02 — Base layout

## Goal

The skeleton everything else is mounted on: container, grid, vertical rhythm, providers and
global styles.

## Scope

- `app/layout.tsx`: html/body, language, fonts, theme providers.
- Container and max widths per breakpoint, per the handoff's §4.
- Global grid: columns, gutters and side padding per breakpoint.
- Vertical rhythm between sections.
- Minimal global styles: reset, default `focus-visible`, and **smooth scroll only with
  motion allowed** (`motion-safe:scroll-smooth` on `<html>`, or `scroll-behavior: smooth`
  inside `@media (prefers-reduced-motion: no-preference)`), plus `scroll-margin-top` on
  anchor targets equal to the sticky header's height token, so a link does not land under
  the header.
- **Text selection:** `::selection` with the `selection` tokens (background and text) in light
  and dark — never the system blue on a site with its own identity.
- **Scrollbar:** `scrollbar` tokens (thumb and track) in light and dark, with
  `scrollbar-color` and `::-webkit-scrollbar` as a fallback where it is not supported.
  Without it, the browser's gray sits on top of a brand background (a project asked for it
  separately).
- **Brand assets** from the `seo` init: favicon, `icon.svg`, `apple-icon.png`, manifest and
  default OG, per what was decided at kickoff (`reference/BRAND-ASSETS.md`).
- Structural header and footer (even if their content comes later).
- Skip link to `main`.
- Landmarks: `<header>`, `<nav>`, `<main>`, `<footer>`.

## Inputs

`design/HANDOFF.md` §4 · phase 01 closed

## Closing criteria

- [ ] The container behaves the same at every breakpoint of the project.
- [ ] Correct landmarks and a single `<main>`.
- [ ] Working skip link, visible when focused.
- [ ] An anchor link scrolls smoothly and lands below the sticky header; with reduced motion,
      it jumps.
- [ ] No horizontal scroll at 320px on the empty page.
- [ ] Selected text with the system's color and ratio ≥ 4.5:1, in light and dark.
- [ ] Scrollbar with the `scrollbar` tokens, thumb ≥ 3:1 against the track, in light and dark.
- [ ] Favicon visible in the tab; what the client still owes, in `CONTENT_CHECKLIST.md`.
- [ ] `a11y` gate green.
- [ ] `seo` skill run in *init* mode: base metadata, `robots.ts`, `sitemap.ts`, favicons,
      default OG.

## Frequent ambiguity

How the container behaves above 1920px: does it lock to a max, or keep growing? If the
handoff does not say, ask — it is the most common reason a site looks empty on a big monitor.
