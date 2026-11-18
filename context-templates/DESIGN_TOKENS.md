# Design Tokens — {{PROJECT_NAME}}

> The single source of truth for reusable values that are neither color nor typography.
> Every component must consume these tokens instead of loose values in the code.

## Spacing

Base unit: {{8px}}

| Token | Value |
|---|---|
| spacing.xs | {{4px}} |
| spacing.sm | {{8px}} |
| spacing.md | {{16px}} |
| spacing.lg | {{24px}} |
| spacing.xl | {{32px}} |
| spacing.2xl | {{48px}} |

## Border radii

| Token | Value | Use |
|---|---|---|
| radius.sm | {{4px}} | {{inputs, chips}} |
| radius.md | {{8px}} | {{cards, buttons}} |
| radius.lg | {{16px}} | {{modals, featured sections}} |

## Shadows

| Token | Value | Use |
|---|---|---|
| shadow.sm | {{css value}} | {{card hover}} |
| shadow.md | {{css value}} | {{dropdown, popover}} |
| shadow.lg | {{css value}} | {{modal}} |

## Breakpoints

See `DESIGN_RULES.md` — they must match exactly; this file does not redefine them.

## Transitions / animation

| Token | Value |
|---|---|
| duration.fast | {{150ms}} |
| duration.normal | {{250ms}} |
| easing.default | {{cubic-bezier(...)}} |

A token built on a variable that changes per element (an animation whose duration a component
overrides) is declared in `@theme inline` (Tailwind v4): in plain `@theme` the override does
nothing — the kit's `reference/STACK-NEXTJS.md` › Tailwind.
