# Template — Addendum for Claude Design (pieces missing from an existing design)

> **For the agent:** use it when the project already has a design and a handoff, but pieces
> are missing (status screens, selection color, scrollbar, icon, OG image, emails…) —
> typically after updating the kit. Include **only** the blocks for what is missing, fill the
> `{{...}}` and hand it to César in a code block, because he pastes it by hand into the same
> Claude Design project (which already knows the visual system). Delete this box.

---

```markdown
# Design addendum — {{PROJECT_NAME}}

On top of the design you already made for this project, these pieces are missing. Use the
same system (tokens, typography, components) — no new styles unless you justify them in the
handoff. Same constraints: WCAG 2.1 AA, no state conveyed only by color, no horizontal
scroll at 320px, light {{and dark}}. All copy in {{LANGUAGE}}.

## Status screens

One visual family: minimal header with the logo, a label, a title in the brand's voice, one
line explaining what happened, and actions. Desktop 1440 and mobile 390.

- **404**{{ · logged in: actions "Go home" + "{{USER_MAIN_DESTINATION}}" · guest: "Go home" + "Log in"}}{{ · no auth: "Go home" + "{{MAIN_ACTION}}"}}
- **500 with a code**: "Retry" + "Go home", and the error code visible and copyable to write
  to support. **500 without a code**: the same, without the code.
- **Offline**: what to check and what is kept; "Retry".
- **Maintenance with a time** ("Back around: <local date and time>") and **without a time**.
  No actions.

Copy: {{real: ... | propose one in {{LANGUAGE}} with the brand's voice, understandable without the wordplay}}.

## Text selection

Background and text color of `::selection` in light and dark, with its ratio (≥ 4.5:1 of the
selected text over the selection background), distinguishable from focus and links.

## Scrollbar

Thumb and track colors in light and dark, from the site's color system (not the browser's
gray on top of a brand background). Thumb ≥ 3:1 against the track, also on hover.
Thickness: {{thin | normal}}. Applies to the page and to areas with their own scroll
(modals, lists, tables).

## Icon and favicon

{{The client has a logo but no icon | there is no logo | the client has a logo but has not
delivered it yet: design a provisional one (monogram or the name in the site's typeface)
that can be swapped for the real one without redoing the icon or the OG}}. Design a square
icon derived from {{the brand / the attached logo}}, legible at 16 px, in SVG, with a version
for light and dark backgrounds, and its apple touch icon variant (180×180, opaque
background) and maskable one (symbol within the central 80%).

## Open Graph image

A 1200×630 template for sharing: logo, page title (≥ 60 px), the system's background, a
safety margin for crops. One default for the site {{and a variant for <page type>}}.

## Email templates

The app sends these emails: {{list, e.g. "confirm account · recover password · order
received"}}. One family with a base template: header with the logo, title, one or two
paragraphs, a button and below it the link as text, a footer with why they receive it and
a contact. Each email with subject and preview text (preheader), copy {{real: ... | proposed
in {{LANGUAGE}} with the brand's voice}}.

Constraints of the medium: max width 600 px, one column; typography that works with
`Arial, Helvetica, sans-serif` (Gmail and Outlook do not load web fonts); understandable
with images blocked; the logo reads if the client inverts to dark; HTML button ≥ 44 px tall;
AA contrast. Show them at 600 px and 360 px.

## Deliverable

The pieces in the design and a **new section of HANDOFF.md** with, for each one: the tokens
it uses (or new ones, with value and ratio), measurements, responsive behavior, states,
accessibility notes and, for icon and OG, the exported files with their sizes.
```
