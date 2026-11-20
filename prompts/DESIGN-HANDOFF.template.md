# Design handoff — expected structure and verification

This file has two uses:

1. **The orchestrator** uses it to check the `HANDOFF.md` that comes back from Claude
   Design, before letting a single line of code be written.
2. **`frontend-build`** uses it as a map: it knows where to look for each value while
   implementing.

The real handoff lives in `design/HANDOFF.md` inside the project.

---

## Completeness check

Go through this list against the `HANDOFF.md` received. Each ❌ is a question to send back
to Claude Design **now**, not in phase 5.

### 1. Tokens
- [ ] Light **and** dark colors, every role, with hex
- [ ] Contrast ratio noted on each text/background pair used
- [ ] Type scale with size, line height, weight and tracking per role
- [ ] Spacing scale
- [ ] Border radii
- [ ] Shadows with a real CSS value
- [ ] Animation durations and curves
- [ ] z-index scale
- [ ] Text selection color (background and text, light and dark) with its ratio
- [ ] Scrollbar (thumb and track, light and dark), thumb ≥ 3:1 against the track

### 2. Components
For each component:
- [ ] Name + mapping to the component library (or "new component")
- [ ] Anatomy
- [ ] Variants and sizes
- [ ] States: rest · hover · **focus** · active · disabled · loading · error
- [ ] Concrete measurements (padding, height, gap, icon, border)
- [ ] Responsive behavior
- [ ] Accessibility notes (role, accessible name, keyboard)

> The **focus** state is the one most often missing. Without it, the frontend improvises a
> ring that does not fit the system and `a11y` bounces it later.

### 3. Sections
For each section, in the page's vertical order:
- [ ] Layout (grid/flex, columns, gaps, max width)
- [ ] Components it uses
- [ ] Vertical spacing before and after
- [ ] **Behavior at each breakpoint**, explicit
- [ ] Which content is real and which is a placeholder

### 4. Global grid
- [ ] Container max width
- [ ] Columns and gutters per breakpoint
- [ ] Side padding per breakpoint
- [ ] Vertical rhythm between sections

### 5. Assets
- [ ] Complete list with dimensions and format
- [ ] Icon set identified
- [ ] Logo variants
- [ ] Source icon (SVG) and its derivatives: favicon, opaque apple touch icon 180×180,
      maskable — or confirmed that the client sends them (see `reference/BRAND-ASSETS.md`)
- [ ] Open Graph image template 1200×630 — or confirmed that the client sends it

### 5b. Status screens (`reference/STATUS-SCREENS.md`)
- [ ] 404 — logged in and guest if there is auth; a single one if not
- [ ] 500 with a code and without
- [ ] Offline
- [ ] Maintenance with a time and without
- [ ] Copy of each (real or marked as proposed) and its mobile version

### 5c. Emails (`reference/EMAIL-TEMPLATES.md`) — only if the app sends emails
- [ ] Base template with concrete values: width, colors with ratio, fallback typography,
      button with measurements
- [ ] One for each email in `PROJECT_CONTEXT.md` § "Emails", with subject, preheader and copy
- [ ] Each one's variable data identified (link, code, name, summary)
- [ ] How it looks without images and with inverted colors (logo legible in both)

### 6. Motion
- [ ] What animates, duration and curve
- [ ] Accordion/FAQ, tabs + active nav link, select/dropdown, dialog/sheet: how each opens,
      closes or switches
- [ ] Anchor links: smooth scroll and the offset under the sticky header
- [ ] What turns off under `prefers-reduced-motion`

### 7. Implementation order
- [ ] Sequence of steps with dependencies marked

### 8. Decisions and traps
- [ ] Decisions with their reason
- [ ] What is easy to implement wrong
- [ ] Each deliberate choice that looks like one of the brief's "AI defaults", with its
      reason (without it, `design-qa` reports it as a default)

### 9. Open questions
- [ ] Listed, with Claude Design's recommendation for each

---

## What to do when something is missing

| Situation | Action |
|---|---|
| A token or a concrete measurement is missing | Send the exact question back to Claude Design. **Do not estimate it from the mockup** — an invented value spreads through the whole system. |
| A component state is missing | Send the question back. Cheap to answer, expensive to guess. |
| The behavior at a breakpoint is missing | Send the question back. It is design QA's #1 finding. |
| An asset is missing | Log it in `CONTENT_CHECKLIST.md` and implement with a flagged placeholder. **This one does not block.** |
| A decision contradicts `context/DESIGN_RULES.md` (e.g. a color pair that does not reach AA) | The handoff does **not** override the accessibility rules. Escalate to César with the proposed correction. |
| A decision contradicts `COLORS.md` or `TYPOGRAPHY.md` without breaking any rule | The handoff wins. Update `context/` and record the decision with its reason. |

General rule: **a system value is missing → ask; content is missing → placeholder and log
it.** Confusing the two is what produces reimplementations.

---

## Reconciliation with `context/`

Before starting the frontend, the orchestrator syncs:

- `COLORS.md` ← the handoff's final color tokens, with their ratios
- `TYPOGRAPHY.md` ← final type scale
- `DESIGN_TOKENS.md` ← spacing, radii, shadows, motion, z-index
- `COMPONENTS_INVENTORY.md` ← one row per handoff component, status `pending`
- `SECTION_INVENTORY.md` ← one row per section, status `pending`
- `CONTENT_CHECKLIST.md` ← every placeholder and missing asset
- `PROJECT_CONTEXT.md` § "Emails" ← status `designed` on the ones the handoff brings
- `decisions/` ← one file per relevant decision the handoff brings or changes

From here, `context/` and `HANDOFF.md` must say the same thing. If they diverge, the
frontend will follow one of the two at random depending on which it read last.
