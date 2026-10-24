# Template — Brief for Claude Design

> **For the orchestrator:** fill each `{{...}}` with the project's real data and give César
> the result inside a code block, ready to copy and paste into Claude Design. Delete this box
> and every bracketed instruction before delivering it.
>
> Three rules when filling it:
> 1. **Self-contained.** Claude Design does not see `context/` or the repo. Zero references
>    to external files.
> 2. **Closed where it matters, open where it helps.** Palette, typography, breakpoints,
>    sections and their order are closed. Each section's visual treatment is open.
> 3. **Section 9 is not touched or summarized.** It is what makes a usable handoff come back
>    instead of just images.

---

```markdown
# Design brief — {{PROJECT_NAME}}

You are a senior product designer. You will design a complete {{PROJECT_TYPE}} for the
project described below, and you will also deliver a handoff document for development
(section 9 of this brief) that a frontend developer will use to implement it without
consulting you again. All the site's copy is in {{LANGUAGE}}.

## 1. The project

**What it is:** {{2_LINE_DESCRIPTION}}
**Type:** {{landing page | e-commerce | corporate site | dashboard/app | blog | portfolio}}
**Audience:** {{WHO_COMES_IN_AND_WHAT_THEY_LOOK_FOR}}
**Main action:** {{THE_ONE_THING_THE_VISITOR_MUST_DO}}
**Language / market:** {{e.g. Spanish, Venezuela}}

## 2. Visual personality

**Chosen direction:** {{e.g. "Sober editorial"}}
**Must convey:** {{3-4 adjectives}}
**Must NOT look like:** {{2-3 things to avoid — this guides as much as the above}}

**References:**
- {{URL_OR_BRAND}} — specifically for {{what exactly: the typography, the vertical rhythm,
  the photo treatment, the density}}
- {{REFERENCE_2}} — for {{...}}

[Be concrete about the "why" of each reference. "I like Stripe" says nothing; "I like
Stripe's information density without a feeling of clutter" does.]

## 3. Brand constraints

**Logo:** {{available / in progress / none / the client has it but has not delivered it (design a provisional one, section 7)}} — {{description or usage note}}
**Mandatory colors:** {{exact hex, or "none — propose the palette"}}
**Mandatory typography:** {{exact name, or "none — propose"}}
**Icon / isotype:** {{the client has it (attached) | design it derived from the logo (section 7) | does not apply}}
**Favicon, apple touch icon and Open Graph image:** {{the client has them | design them (section 7)}}
**Other:** {{e.g. "the client hates purple", "must live alongside an existing app that uses X"}}

## 4. Starting visual system

[If the orchestrator already closed palette and typography, they go here as closed. If it
was decided that Claude Design proposes them, write "PROPOSE" and give the direction.]

### Palette
| Role | Light | Dark | Use |
|---|---|---|---|
| primary | {{#______}} | {{#______}} | {{CTAs, active links}} |
| secondary | {{#______}} | {{#______}} | |
| background | {{#______}} | {{#______}} | |
| surface | {{#______}} | {{#______}} | {{cards, panels}} |
| text primary | {{#______}} | {{#______}} | |
| text secondary | {{#______}} | {{#______}} | |
| success / warning / error | {{...}} | {{...}} | |
| border / divider | {{#______}} | {{#______}} | |
| selection (background / text) | {{#______ / #______}} | {{#______ / #______}} | {{selected text; ratio noted; distinct from focus and links}} |
| scrollbar (thumb / track) | {{#______ / #______}} | {{#______ / #______}} | {{scrollbar; thumb ≥ 3:1 against the track; discreet, from the color system}} |

**Dark mode:** {{yes — mandatory / no / optional}}

### Typography
- **Headings:** {{FONT}} — {{available weights}}
- **Body:** {{FONT}} — {{weights}}
- **Mono (if it applies):** {{FONT}}
- **Scale:** {{e.g. 1.250 (major third), base 16px}}

### Spacing and shape
- Base unit: {{8px}} — every spacing is a multiple of this unit
- Radii: {{e.g. 6px inputs / 10px cards / 16px modals}} · {{or "no radii, all square"}}
- Shadows: {{e.g. "subtle, only on real elevation — no decorative shadows"}}

## 5. Non-negotiable constraints

These apply to **everything** you design. A design that breaks them cannot be implemented
and has to be redone.

- **WCAG 2.1 AA contrast.** Normal text ≥ 4.5:1, large text (≥24px or ≥19px bold) ≥ 3:1,
  input borders and informative icons ≥ 3:1. Check every pair you use and note the ratio.
- **No state is conveyed only by color.** Error, success, selected, active: always color +
  icon, text or shape.
- **No horizontal scroll at 320px width.**
- **Visible, designed focus states**, not the browser's default outline or its absence.
- **Implemented with {{COMPONENT_LIBRARY}}**. [The orchestrator pastes here the matching
  paragraph from `reference/UI-LIBRARIES.md` § "What the brief tells the design tool" — it
  changes what is reasonable to design, so do not omit it.]
- **Target breakpoints:** 360 · 768 · 1024 · 1440 · 1920 {{· 2560 if it applies}}.

## 6. Pages and sections

[One entry per page, with its sections in exact vertical order. This order is not a
suggestion: it is the structure the frontend will implement.]

### {{PAGE_1 — e.g. Home}}
| # | Section | Purpose | Content available | CTA |
|---|---|---|---|---|
| 1 | {{Hero}} | {{what it must achieve in 3 seconds}} | {{real / placeholder}} | {{which}} |
| 2 | {{...}} | | | |

### {{PAGE_2}}
{{...}}

## 7. States and cases that also need designing

[What is almost always forgotten and the frontend ends up inventing. Mark what applies.]

- [ ] Empty states (list without results, empty cart, no orders yet)
- [ ] Loading states (skeletons per section, not a global spinner)
- [ ] **Status screens**, as one visual family (minimal header with the logo, a label, a
      title in the brand's voice, one line about what happened, actions):
  - [ ] **404** — {{logged in: "Go home" + "<user's main destination>" · guest: "Go home" +
        "Log in"}} {{— or, without authentication, a single 404 with "Go home" + "<main action>"}}
  - [ ] **500 with a code** (the code visible and copyable to write to support; "Retry" +
        "Go home") and **500 without a code**
  - [ ] **Offline** (what to check, what is kept, "Retry")
  - [ ] **Maintenance with a time** ("Back around: <local date and time>") and **without a time**
- [ ] Error inside a screen (form rejected, network failure on save): not full screen
- [ ] Forms: rest, focus, filled, error with message, success, disabled, submitting
- [ ] Buttons: rest, hover, focus, active, loading, disabled
- [ ] Navigation open on mobile
- [ ] Text selection color and scrollbar, in light {{and dark}}
- [ ] {{Icon derived from the logo: legible at 16 px, SVG for light and dark backgrounds,
      apple touch icon 180×180 with an opaque background, maskable — only if the client does
      not have it. Provisional if the client has a logo but has not delivered it.}}
- [ ] {{Open Graph image template 1200×630 — only if the client does not have it}}
- [ ] {{Logged in vs. anonymous — only if there is authentication}}
- [ ] {{**Email templates** — only if the app sends emails. One family with a base template
      (header with logo, title, text, button + the link as text below it, a footer with why
      they receive it and a contact), and these emails: <closed list, e.g. "confirm account ·
      recover password · order received · contact form acknowledgment · contact form
      internal notice">. Each with subject and preview text (preheader). Constraints of the
      medium, non-negotiable: max width 600 px and one column; typography that works with
      the fallback stack (`Arial, Helvetica, sans-serif`), because Gmail and Outlook do not
      load web fonts; understandable with images blocked (no text in images); the logo
      reads if the client inverts colors to dark; HTML button ≥ 44 px tall; AA contrast.}}
- [ ] Extreme content: a 3-line title, a 40-character name, a list of 1 and of 50 items

## 8. Content

**Real content available:** {{which texts/photos already exist}}
**Pending:** {{what goes with a placeholder}}

For what is pending, use realistic text in {{LANGUAGE}} with the length the final content
will have — **never lorem ipsum**. A design validated with lorem breaks when the real copy
arrives, and the developer pays for that break.

---

## 9. Deliverable — MANDATORY

Deliver **two things**. The second is as important as the first.

### 9.1 The design

Every page of section 6 at {{desktop 1440 · mobile 390}}, with the states of section 7.

### 9.2 `HANDOFF.md` — the handoff document for development

A self-contained Markdown document, written for a senior frontend developer who **did not
see the design with you and cannot ask you anything**. Whatever is not here, they will have
to invent — and that is where the design drifts.

Exact structure:

**1. Tokens** — a complete table of final values, with token name, value and use: colors
(light and dark, with the verified contrast ratio of each pair used, including selection
and scrollbar), type scale (size / line height / weight / tracking per role: display,
h1-h6, body, small, caption), spacing, radii, shadows, animation durations and curves,
z-index.

**2. Components** — one by one, and for each:
   - Name, and if it maps to a {{COMPONENT_LIBRARY}} component, which one
   - Anatomy (which parts make it up)
   - Variants and sizes
   - **Every** state: rest, hover, focus, active, disabled, loading, error
   - Concrete measurements: padding, height, gap, icon size, border width
   - Responsive behavior
   - Accessibility notes: role, expected accessible name, keyboard behavior

**3. Sections** — one by one, in section 6's order, and for each:
   - Layout structure (grid or flex, columns, gaps, max width)
   - Which components it uses
   - Vertical spacing before and after
   - **How it reorders or collapses at each breakpoint** (explicit, not "it is responsive")
   - Content: what is real text and what is a placeholder

**4. Global grid and layout** — container max width, number of columns and gutters per
breakpoint, side padding per breakpoint, vertical rhythm between sections.

**5. Assets** — a list of everything to export or obtain: images (with dimensions and
format), icons (with the set they come from), illustrations, the logo in its variants, and
the brand assets: source icon (SVG), favicon, apple touch icon 180×180, maskable icon and
the Open Graph image template 1200×630 (which text it carries and which area is safe when
cropped).

**5b. Status screens** — for each variant in section 7: layout, copy, actions, what changes
between variants (with/without session, with/without a code, with/without a time) and how
it looks on mobile.

**5c. Emails** (if section 7 asks for them) — the base template (widths, colors with hex and
ratio, text sizes, padding, the button with its measurements, the fallback font stack) and,
for each email: subject, preheader, full copy, which variable data it carries (name, link,
code, order summary), the action and how it looks at 600 px, at 360 px, without images and
with inverted colors.

**6. Motion** — what animates, with which duration and curve, and what turns off under
`prefers-reduced-motion`. At least, how each of these opens, closes or switches:
accordion/FAQ, tabs and the active nav link indicator, select/dropdown, dialog/sheet, and
the scroll of in-page anchor links (smooth, and how far below the sticky header it lands).

**7. Implementation order** — the recommended sequence to build it, from tokens to base
components to sections to pages, with the dependencies between steps marked.

**8. Decisions and traps** — the design decisions you took and why (so the developer does
not "fix" them by accident), plus what is easy to implement wrong: what must look identical
between sections, which spacing is intentional even if it looks inconsistent, what must not
become a shared component even if it looks like another one.

**9. Open questions** — what you could not decide for lack of information, with your
recommendation for each.

Format of the whole handoff: concrete values, never adjectives. "24px", not "generous
spacing". "#1E293B on #F8FAFC, ratio 14.8:1", not "dark gray on light gray".
```

---

## Check before giving the brief to César

- [ ] Zero unfilled `{{placeholders}}`.
- [ ] Zero references to files Claude Design cannot see.
- [ ] The sections of each page are in real vertical order.
- [ ] Section 9 is complete and not summarized.
- [ ] It is inside a code block, ready to copy.
