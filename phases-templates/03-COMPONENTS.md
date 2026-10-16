# Phase 03 — Components

## Goal

The `components/ui/` primitives everything else will use.

## Scope

- Bring from the chosen library (`PROJECT_CONTEXT.md`) what applies and style it with the
  project's tokens.
- Implement the handoff's custom components that have no equivalent.
- **Every state** of each: rest, hover, focus, active, disabled, loading, error.
- Variants and sizes.
- Each component's responsive behavior.
- Document each one in `COMPONENTS_INVENTORY.md`.

## Inputs

`design/HANDOFF.md` §2 · phases 01-02 closed

## Units of work

Group by family, one branch per group. Do not do twelve components in one commit.

1. Buttons and links
2. Forms (input, textarea, select, checkbox, radio, switch, label, error message)
3. Containers (card, panel, separator)
4. Overlays (dialog, sheet, popover, tooltip, dropdown)
5. Navigation (navbar, mobile menu, tabs, breadcrumb, pagination)
6. Feedback (badge, alert, toast, skeleton, spinner, empty state)
7. The project-specific ones

## Closing criteria

- [ ] Every handoff component implemented, with all its states.
- [ ] Zero magic values: `grep -rnE '\[[0-9]+px\]|\[#[0-9a-fA-F]{3,8}\]' components/` clean.
- [ ] Visible focus with contrast ≥3:1 on all of them.
- [ ] Composite widgets follow the WAI-ARIA Authoring Practices pattern.
- [ ] There is a reference page with all the components and their states.
- [ ] `COMPONENTS_INVENTORY.md` complete.
- [ ] `a11y` gate green.

## Rule

**Before creating a new component, check the inventory.** Two components that do the same
thing under different names is the most expensive debt of a design system: it is found late
and fixing it touches every page.
