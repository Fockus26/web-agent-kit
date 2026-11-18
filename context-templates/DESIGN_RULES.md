# Design Rules — {{PROJECT_NAME}}

> Non-negotiable rules. Every agent and every skill follows them without exception.
>
> If a specific case needs to break a rule, **it is a new decision** that goes through César
> and gets recorded in `decisions/` — not a silent exception inside a component.

## Accessibility — WCAG 2.1 AA

- Normal text: contrast ≥ **4.5:1** against its real background.
- Large text (≥24px, or ≥19px bold): ≥ **3:1**.
- Input borders, informative icons and focus rings: ≥ **3:1**.
- **No state is conveyed only by color.** Error, success, selected, active: color **+**
  icon, text or shape.
- Focus always visible, designed — not the default outline or its absence. The ring takes
  the ink color of the component it surrounds (through `--ring`), ≥ 3:1 against what is
  around it: one primary ring everywhere reads as foreign on a red button.
- Placeholder text ≥ **4.5:1**: the default (the text color at 50 %) gave 3.25:1 in light,
  and axe does not check it.
- An action inside a notice (a toast's "Reintentar") uses that notice's color, not primary.
- No horizontal scroll at **320px** width.
- At 400% zoom the content reflows into one column.
- `prefers-reduced-motion` respected.
- Every control has an accessible name.
- Selected text (`::selection`) with the `selection` tokens, ≥ 4.5:1, in light and dark.
  Inside a component with its own background (a primary button, a colored notice), its
  inverted pair: the global pair got lost there.
- Scrollbar with the `scrollbar` tokens, thumb ≥ 3:1 against the track, in light and dark.
- Status screens (404, 500, offline, maintenance) with the site's design and their real
  HTTP status — see the kit's `reference/STATUS-SCREENS.md`.

Cases that fail again and again, check them explicitly: the brand's `main` or `light` shade
used as text on a light background · status chips and badges · input placeholders · text
over an image or gradient · disabled text.

## Breakpoints

| Name | Width | Notes |
|---|---|---|
| xs | 0 | base, mobile first |
| sm | {{640px}} | |
| md | {{768px}} | the one that breaks layouts most: neither mobile nor desktop |
| lg | {{1024px}} | |
| xl | {{1280px}} | |
| 2xl | {{1536px}} | |
| {{3xl}} | {{1920px}} | {{if the project has it}} |

**QA verification widths** (different from the breakpoints — they are real devices):
320 · 360 · 390 · 430 · 768 · 1024 · 1280 · 1440 · 1920 · 2560 · 3840

## Tokens

- **Zero magic values.** Every color, spacing, radius, shadow and font size comes from the
  tokens. If `mt-[13px]` or `text-[#3a7bd5]` shows up, either the token exists and was not
  used, or a token is missing and that is a decision to record.
- Base spacing unit: {{4px}} — every spacing is a multiple.
- See `DESIGN_TOKENS.md`, `COLORS.md`, `TYPOGRAPHY.md`.

## Components

- Before creating a new one, check `COMPONENTS_INVENTORY.md`. Two components that do the
  same thing under different names is the system's most expensive debt.
- **The project's library before reimplementing** a primitive by hand: the keyboard and
  focus behavior is already solved there.
- Composite widgets follow the matching WAI-ARIA Authoring Practices pattern.

## Code

- **bun** as manager and runner. Never npm, yarn or pnpm.
- **Context7** checked before using any library's API.
- Server Components by default; `'use client'` as low in the tree as possible.
- Strict TypeScript, zero `any`.
- **Component library:** {{shadcn/ui | Hero UI | MUI}} — see `PROJECT_CONTEXT.md`.
- **Styling system:** {{Tailwind | MUI sx/styled}}. Only one, never both.
- **Nobody starts the dev server.** César starts it. Agents ask for it to be running and
  wait for confirmation.

## Content

- **No agent invents final content**: no copy, no real `alt`, no prices, no contact details,
  no testimonials. A flagged placeholder + a row in `CONTENT_CHECKLIST.md`.
- **Zero lorem ipsum.** A realistic placeholder, in the project's language, with the length
  of the final text. A layout validated with lorem breaks when the real copy arrives.

## Git

- Nothing gets committed without César's explicit approval (in `pr` mode, his approval is
  the PR review).
- Automatic push only when the base branch is **not** `main`.
- Nothing destructive: no `reset --hard`, no `push --force`, no deleting branches, no
  rewriting history.

## This project's specific rules

- {{ADDITIONAL_RULE_1}}
