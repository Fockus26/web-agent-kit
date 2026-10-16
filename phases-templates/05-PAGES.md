# Phase 05 — Pages

## Goal

Assemble the sections into real routes, with their navigation and their metadata.

## Scope

- One route per unit of work.
- Composition of sections in the handoff's order.
- Navigation between pages, with an active state.
- Per-page metadata and JSON-LD of the matching type (`seo` skill).
- Dynamic routes with `generateMetadata` and `notFound()` when the resource does not exist.
- Entry in `sitemap.ts`.

## Inputs

`design/HANDOFF.md` · `context/PAGE_INVENTORY.md` · phase 04 closed

## Closing criteria

- [ ] Every route in the inventory exists and they link to each other.
- [ ] A single `<h1>` per page.
- [ ] Unique metadata per page; correct canonical.
- [ ] Pages that must not be indexed (thank-you, account, checkout) with
      `robots: { index: false }`.
- [ ] Zero broken links.
- [ ] `a11y` gate green · `seo` skill run in *page* mode.
- [ ] `PAGE_INVENTORY.md` updated.
