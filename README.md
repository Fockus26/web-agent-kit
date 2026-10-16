# Web Agent Kit

An agent system for producing websites end to end: from a half-formed idea to a site that is
implemented, accessible, optimized and audited.

It is built around a concrete premise: **the developer is strong at frontend and weak at
design.** That is why design is delegated to Claude Design with a rigorous brief, and
everything else relies on quality gates that do not depend on having a good eye.

> **How do I use it?** See [GUIDE.md](./GUIDE.md): installation, creating a project and the
> full flow with an example.

**Language:** the kit is written in English; its agents talk to César in Spanish (questions,
reports, PRs, commits). Projects created before 3.8.0 keep their `context/` in Spanish and
keep working.

---

## The flow

```
      César arrives with an idea
                │
                ▼
    ┌───────────────────────┐
    │  1. project-kickoff   │  interview → plan mode → context/ + brief
    │     (orchestrator)    │
    └───────────┬───────────┘
                │  delivers a self-contained brief
                ▼
    ┌───────────────────────┐
    │   2. CLAUDE DESIGN    │  ← César pastes the brief by hand (separate tool)
    │                       │
    └───────────┬───────────┘
                │  returns the design + HANDOFF.md
                ▼
    ┌───────────────────────┐        ┌──────────────────────┐
    │  3. frontend-build    │◄──────►│  4. backend-build    │
    │  tokens → components  │        │  auth · data · pay   │
    │  → sections → pages   │        └──────────┬───────────┘
    └───────────┬───────────┘                   │
                │                               │
                ▼                               ▼
    ┌───────────────────────┐        ┌──────────────────────┐
    │   5. design-qa        │        │  6. functional-qa    │
    │   screens · CVD ·     │        │  break flows ·       │
    │   zoom · consistency  │        │  security · limits   │
    └───────────────────────┘        └──────────────────────┘

  At every unit's close, always:   [a11y] → [seo if it applies] → [git-flow]

  A list of several things at once?  → [orchestrate] splits it into units, orders them in
  waves and launches a feature-worker per unit, each in a worktree pool slot (recyclable:
  no node_modules reinstall) and with its PR.
```

---

## Roster

### Skills — run in the main session

They activate on their own when they apply, or you invoke them with `/name`. They are the
ones that **can talk to you**: ask questions, present 3 options, wait for your approval.

| Skill | What it does | When it activates |
|---|---|---|
| **`project-kickoff`** | Interview, plan mode, generates `context/` and the brief for Claude Design | New project |
| **`frontend-build`** | Handoff → code, one unit at a time | Each UI unit |
| **`backend-build`** | Auth, sessions, data, payments, forms | Each functionality unit |
| **`git-flow`** | Branches, commits, verification, screenshots, pruning and backing up `context/`; closing through a PR (`pr` mode) or with a pause + local merge (`local` mode) | When opening and closing each unit |
| **`orchestrate`** | Maps a list of requests (or a phase) to the code, groups, orders into waves, reserves numbers, asks what blocks and launches a `feature-worker` per unit; with the wave merged it launches `wave-qa`, closes it stating phase, wave and what is next, and opens the next one in another session | When several things arrive at once · when doing a phase in waves |
| **`a11y`** | WCAG 2.1 AA gate | Whenever UI is touched, before review |
| **`seo`** | Metadata, JSON-LD, sitemap, Core Web Vitals | Repo init · section with content · page |
| **`kit-update`** | Compares the project's version with the kit's published one; checks for missing pieces; if behind, applies the path in `UPDATES.md` in a PR | `/kit-update` when a kit version comes out |
| **`kit-feedback`** | Sends `context/KIT_FEEDBACK.md` to the kit's repo as a PR | `/kit-feedback` whenever you want · when closing phase 09 |

### Agents — run isolated and return a report

The QA ones audit without interrupting and do not modify code. `feature-worker` does
implement: a whole unit, in its worktree pool slot, up to the PR.

| Agent | What it does | When you launch it |
|---|---|---|
| **`feature-worker`** | Implements a unit end to end (branch, code, tests, verification, screenshots, PR) with the prompt `orchestrate` prepares. Opus, medium effort | `orchestrate` launches it |
| **`wave-qa`** | With the wave merged, starts the server on `main` and walks its flows as a real user, against a local database (Supabase in Docker, `bun run qa:local`; `--offline` without Docker) and with the per-role test accounts of `.env.test.local` (`EMAIL_TEST`, `ADMIN_EMAIL_TEST`, `<ROLE>_EMAIL_TEST`…) | `orchestrate` launches it when closing each wave |
| **`design-qa`** | 320px to 3840px, color blindness, 400% zoom, reduced motion, high contrast, focus, token consistency. With Playwright + axe. | When closing a page or the whole integration |
| **`functional-qa`** | Tries to break the flow: edge-case inputs, double clicks, dropped network, expired session, tampered prices, duplicated webhooks | When closing a full flow |

### Why some are skills and others agents

It is not arbitrary: **a subagent cannot ask you questions while it runs.** It is launched,
does its work in isolation, and returns a result.

Everything that needs your approval — the orchestrator, the frontend, the backend — has to
live in the main session, and that is why they are skills. What audits and reports without
needing your decisions halfway gains from isolation: it does not pollute the development
session's context and can run in parallel. That is why the QAs are agents.

`orchestrate` is a skill because it has to ask you (once, at the start) what blocks.
`feature-worker` is an agent because it runs an already-decided prompt: what is missing it
resolves conservatively and explains in the PR, which is where you approve.

---

## Installation

### Skills and agents (once, for all your projects)

**Windows (PowerShell):**

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\install-kit.ps1"
```

**macOS / Linux:**

```bash
bash ~/Desktop/agents/web-agent-kit/install-kit.sh
```

It copies each skill and agent of the kit to `~/.claude/`, replacing the installed version
(without leaving old files) and without touching what is not the kit's. To update, the same
command with `-Pull` (`--pull` in bash): it runs `git pull` in the kit first.

Check with `/skills` and `/agents`. You should see the nine skills and the four agents.

> **Agents load when the session opens.** If you install or edit one with a session open,
> that session does not see it ("Agent type not found"): open a new session.

> If you prefer them per project instead of global, copy the whole `.claude/` folder to the
> project root. Global is more convenient when all your projects follow this same flow;
> local, when you want to version them with the client's repo.

### Context7

The Context7 MCP has to be connected: the frontend and backend agents check it before using
any library's API. If it is not, they will say so and flag that code as written without
checking current documentation.

---

## Starting a new project

A single command (PowerShell 7, `pwsh`) creates the app and leaves the whole kit copied:

```powershell
& "$env:USERPROFILE\Desktop\agents\web-agent-kit\new-project.ps1" -Path C:\path\my-project
```

- Creates the app with `bunx create-next-app@latest <name> --ts --tailwind --app --biome
  --react-compiler --import-alias "@/*" --use-bun` (Biome, not ESLint; React Compiler on).
- Copies `context/`, `phases/`, `CLAUDE.md` (keeping Next.js 16's `@AGENTS.md`), `scripts/`,
  `.github/`, `.changeset/` and creates `tests/unit/` and `design/`.
- Adds the `package.json` scripts (`test`, `test:related`, `shots`, `shots:publish`,
  `qa:local`, `context:backup`, `context:restore`), `@types/bun`, `@playwright/test`,
  `@axe-core/playwright` and `@changesets/cli`, and the `.gitignore` entries: `.pr-shots`,
  `.qa/`, `.claude/worktrees/` and the local files of `context/` (the fixed documents stay in git).
- Version and CHANGELOG with Changesets: each PR brings its `.changeset/*.md` and an Action
  keeps the version PR, so parallel PRs do not collide. `-NoVersion` skips it.
- It overwrites nothing that exists and **does not commit**.

Project already created with other options? `-Existing` adds only the kit's pieces (see
GUIDE.md). Windows PowerShell 5.1 blocks the script?
`powershell -ExecutionPolicy Bypass -File <kit>\new-project.ps1 -Path ...` (only for that run;
it does not change the system configuration).

Then, in Claude (in Spanish, as always):

**1. Kickoff.** Tell it about the project in your own words — what you are clear about and
what you are not. It does not need to be tidy.

```
/project-kickoff

Quiero una landing para una clínica dental en Valencia. Sé que quiero el azul de su logo
(#0F6E8C) y que use Inter. Secciones: hero, servicios, el equipo, testimonios y agendar cita.
El resto no lo tengo claro.
```

It will ask what only you know (business, content, scope) and **propose** the visual side
with judgment. It enters plan mode, and when you approve the plan it writes all of
`context/` and gives you the design brief in a block ready to copy.

**2. Design.** Paste that brief into Claude Design. Come back with two things: the design
and a `HANDOFF.md`. Save the handoff in `design/HANDOFF.md`.

**3. Handoff check.** Go back to Claude and ask it to review it. If something is missing — a
state, a measurement, the mobile behavior — it gives you the exact question to send back to
Claude Design. **This step looks optional and is not**: a value missing here costs minutes
to ask and hours to reimplement in phase 5.

**4. Implementation.** Phase by phase, unit by unit:

```
/frontend-build   fase 01, tokens
```

Each unit ends with a review on your side (the PR, or a pause in `local` mode).

**5. Functionality.** `/backend-build` when auth, data or payments come up.

**6. QA.** Launch `design-qa` and `functional-qa`. They can run in parallel.

---

## The git flow

Two modes, set in `context/GIT_STATE.md`:

**`pr` mode** (recommended as soon as the repo is on GitHub with protected `main`):

```
git switch -c <type>/<desc> origin/main → implement → test:related → [a11y] → [seo]
   → build + typecheck + lint + test → screenshots → prune and back up context/
   → commit(s) + push of the branch → gh pr create → César reviews and merges (squash)
```

On its branch the agent commits and pushes without asking: the approval is the PR review.
**Never** push to `main`, never `gh pr merge`. If César asks for changes: new commits on the
same branch.

**`local` mode** (no remote): approval pause → commit → `merge --no-ff` into the base → push
only if the base is not `main`. Parent branches for big blocks.

In both: **nothing destructive** (no `reset --hard`, no `push --force`, no deleting branches,
no rewriting history).

**What goes in git:** the code, `supabase/` (migrations, seed, templates) and the fixed
documents of `context/` (`PROJECT_CONTEXT`, `DESIGN_RULES`, `COLORS`, `DESIGN_TOKENS`,
`TYPOGRAPHY`, `decisions/`). **What is local:** the working state of `context/`
(`CURRENT_PHASE`, `CONTENT_CHECKLIST`, `PHASE_LOG/`, `plans/`…), backed up to the orphan
branch `context-state` (`bun run context:backup` / `context:restore`) so that losing the
folder does not lose where the project stood.

---

## The phases

| # | Phase | Who |
|---|---|---|
| 01 | Tokens | `frontend-build` |
| 02 | Base layout | `frontend-build` |
| 03 | Components | `frontend-build` |
| 04 | Sections | `frontend-build` |
| 05 | Pages | `frontend-build` |
| 06 | States (empty, loading, error) | `frontend-build` |
| 07 | Backend | `backend-build` |
| 08 | Responsive and polish | `frontend-build` |
| 09 | Final QA | `design-qa` + `functional-qa` |

**Tracks:** Landing (01·02·03·04·06·08·09) · Site (01–06·08·09) · Product (01–09). The
orchestrator picks one and justifies it.

---

## Kit structure

```
web-agent-kit/
├── README.md                      this file
├── VERSION                        the kit's current version (each project keeps its own in .kit-version)
├── UPDATES.md                     what changed in each version and the steps to migrate a project
├── CLAUDE.md                      how the kit is maintained (processing feedback, versioning)
├── feedback/                      the projects' reports (kit-feedback PRs); goes to no project
├── CLAUDE.md.template             goes to each project's root (≤ 8 KB: a map, not a manual)
├── install-kit.ps1 / .sh          installs or reinstalls skills and agents in ~/.claude/ (-Pull: git pull first)
│                                    and leaves ~/.claude/web-agent-kit.json (path + version) for kit-update
├── new-project.ps1                creates the app and copies the kit (-Existing: adds what is missing)
├── instalar-kit.* / nuevo-proyecto.ps1   pre-3.8.0 names, forward to the ones above
├── .claude/
│   ├── skills/                    the 9 skills → ~/.claude/skills/
│   │   └── orchestrate/           + brief-, unit-prompt- and phase-plan-template.md and
│   │                                scripts/wt.ps1 (recyclable worktree pool)
│   └── agents/                    design-qa, functional-qa, feature-worker, wave-qa → ~/.claude/agents/
├── prompts/
│   ├── CLAUDE-DESIGN-BRIEF.template.md      what gets pasted into Claude Design
│   ├── DESIGN-HANDOFF.template.md           what must come back, and its check
│   ├── CLAUDE-DESIGN-ADDENDUM.template.md   pieces missing from an existing design (states, icon, OG, emails…)
│   ├── ACTUALIZAR-KIT.md                    notice: since 3.6.0 the kit-update skill does it
│   ├── MIGRATE-3.1-WORKTREES-CHANGESETS.md  step 3.0 → 3.1 (cited by UPDATES.md)
│   └── MIGRATE-3.2-DECISIONS-CI.md          step 3.1 → 3.2 (cited by UPDATES.md)
├── context-templates/             → copied as context/ in each project
├── phases-templates/              → copied as phases/
├── sections-template/             content brief, one per section
├── github-templates/              → copied as .github/ (PR template, CI and release.yml)
├── changeset-templates/           → copied as .changeset/ (version and CHANGELOG without conflicts)
└── reference/
    ├── STACK-NEXTJS.md            Next.js + bun + Context7 + conventions
    ├── UI-LIBRARIES.md            shadcn/ui · Hero UI · MUI — criteria and what changes
    ├── TOKEN-ECONOMY.md           reading by levels, context/ caps, tests, screenshots
    ├── STATUS-SCREENS.md          404 · 500 · offline · maintenance: catalog and implementation
    ├── BRAND-ASSETS.md            logo, icon, favicon, touch icon, OG: what is asked and what is generated
    ├── EMAIL-TEMPLATES.md         the app's emails: catalog, design constraints, React Email, Supabase, Firebase, provider
    ├── DEPLOY.md                  GitHub repo, Vercel deployment (or adopting one) and where the environment variables live
    └── scripts/
        ├── design-qa.ts           Playwright sweep (with node)
        ├── test-related.ts        → scripts/: tests affected by the import graph
        ├── pr-screenshots.ts      → scripts/: PR screenshots (with node)
        ├── publish-pr-shots.sh    → scripts/: uploads them to the pr-shots branch
        ├── qa-local.ts            → scripts/: QA server against local Supabase (Docker) with test accounts
        └── context-backup.sh      → scripts/: local context/ ↔ the context-state branch
```

---

## Cross-cutting rules

They apply to every agent, at all times:

- **Zero invented content.** No copy, no real `alt`, no prices, no contact details, no
  testimonials. A flagged placeholder + a row in `CONTENT_CHECKLIST.md`. Invented content
  that looks final gets published without anyone reviewing it.
- **Zero lorem ipsum.** A realistic placeholder, in the project's language, with the final
  text's length. A layout validated with lorem breaks when the real copy arrives.
- **Zero magic values.** Everything comes from the tokens. A `text-[#3a7bd5]` means a token
  is missing or a decision has not been recorded.
- **Zero secrets in the code.** Environment variables always.
- **Ambiguity → exactly 3 options**, with real advantage and disadvantage, and wait.
- **A handoff value is missing → ask**, do not estimate it from the mockup.
- **A problem in already-closed code → report it**, do not fix it along the way inside
  another unit.
- **Unused file → point it out**, do not delete it.
- **Accessibility wins over the handoff.** If a design color does not reach AA, the design
  gets corrected; it is not overlooked.
- **You start the dev server.** When an agent needs the site running, it asks and waits.
  Only exception: an `orchestrate` batch in which you authorize each worker to start its
  own, in the background and on its port. See `reference/TOKEN-ECONOMY.md`.
- **Playwright runs with `node`, not `bun`.** On Windows, Playwright launched from a Bun
  script hangs starting Chromium.

---

## Token economy

Details in `reference/TOKEN-ECONOMY.md`. What weighs most:

| Rule | Why |
|---|---|
| **Reading by levels:** always `CLAUDE.md` + `CURRENT_PHASE.md`; the rest per task or with `grep` | "Read these 5 files before starting" cost ~20,000 tokens per session in the first real project |
| **Caps:** `CLAUDE.md` ≤ 8 KB, `CURRENT_PHASE.md` ≤ 60 lines, indexes with one-line rows | What is always read is always paid for; what is closed goes to `PHASE_LOG/<branch>.md` |
| **Affected tests in the loop, all of them in CI** (`test:related`, `--dots`) | Less time and less output while iterating, without losing the safety net |
| **Screenshots to disk, not to the context** | They are for whoever reviews the PR; the agent verifies by measuring the DOM |
| **Subagents for what is noisy**, with prompts that bring paths and lines | Their noise stays in their context; they start cold, so the prompt gives the minimal sufficient context |
| **Effort by role:** orchestrator high, workers medium | Planning well once makes executing many cheaper |
| César starts the server (or each worker its own, in the background, if he authorizes it) | Compilation logs in the context; orphaned servers |

---

## Versions and updating projects

The kit is versioned (`VERSION`, now **3.8.0**) and each project keeps in `.kit-version`
which one it is aligned with. To bring it up to date: `/kit-update` in a project session. It
compares with the published version (`origin/main` of the kit's clone); if behind, it
computes the path with `UPDATES.md` and applies each version in order, in a PR.

And the way back: each project logs in `context/KIT_FEEDBACK.md` what César had to correct
or repeat and what the kit did not cover. `/kit-feedback` uploads it to this repo as a PR
(`feedback/`, `kit-feedback` label); in a session opened here, "revisa el feedback" triages
all the PRs together (`CLAUDE.md` says how).

### 3.8.0

| Before | Now |
|---|---|
| The kit in Spanish | The kit in English; the agents still talk to César in Spanish |
| Losing the local folder lost where the project stood (phase, wave, pending content, plans) | `context:backup` / `context:restore` with the orphan branch `context-state`; the fixed documents of `context/` and `supabase/` always in git |
| `instalar-kit`, `nuevo-proyecto`, `GUIA`, `ACTUALIZACIONES` | `install-kit`, `new-project`, `GUIDE`, `UPDATES` (the old script names forward) |

### 3.7.0 (feedback from four projects)

| Before | Now |
|---|---|
| Each worker rediscovered the environment: broken heredocs, hanging suites, orphaned servers, Playwright not resolving | Environment rules in the brief; `wt` clears the slot's port; scripts in `.qa/` |
| Without Docker, the wave QA was blocked | `qa:local -- --offline`: guest QA, the logged-in one pending |
| A project "up to date" could lack `test:related`, `shots` or axe | `kit-update` checks the pieces and adds what is missing |
| Auth emails without a decided provider; Firebase not covered | Brevo over SMTP by default, in a decision; sending them yourself with Firebase if the console is locked |
| The browser's scrollbar over the brand background | `scrollbar` tokens next to `::selection` |

### 3.6.0

| Before | Now |
|---|---|
| `ACTUALIZAR-KIT.md`: copy the skills by hand, change the path in the block and paste it | `/kit-update`: compares versions, reinstalls the skills if needed, says whether it is up to date |
| The feedback report was pasted into the kit's chat, one at a time | `/kit-feedback` opens a PR per report; the triage gathers them all and adds up what repeats across projects |

### 3.3.0

| Before | Now |
|---|---|
| "Error states (404, 500…)" as a checkbox in the brief | A catalog of status screens: logged-in/guest 404 (only with auth), 500 with/without a code, offline picked by the network, maintenance with/without a time — designed, with a real HTTP status and an `/estados` gallery |
| Selection color undefined | `selection` token with verified contrast, light and dark |
| Favicon and OG were generated without asking | The kickoff asks which assets the client has and which have to be created |
| Creating the repo and adjusting GitHub were manual actions | The kickoff asks; with the yes, the agent creates the repo, configures it and connects Vercel |
| Old projects: a loose prompt per change | `.kit-version` + `UPDATES.md` + a single update path |
| Corrections got lost in the chat | `KIT_FEEDBACK.md` per project → report → kit improvement |

## What changed in v3 (learned on World Flags)

| v2 | v3 |
|---|---|
| "Read these 5 files before starting" | Reading by levels: always `CLAUDE.md` + `CURRENT_PHASE`; the rest per task or with `grep` |
| A "light" `CURRENT_PHASE.md` without a cap (it reached 38 KB) | 60-line cap; the narrative goes to `PHASE_LOG/<branch>.md`; pruned when each unit closes |
| Only local merge with an approval pause | `pr` mode (PR César reviews and merges) besides `local` |
| One session does everything, unit by unit | `orchestrate` + `feature-worker`: parallel batches in a recyclable worktree pool, in waves, with reserved numbers |
| The whole test suite on every iteration | `test:related` (import graph) in the loop; full suite before the PR and in CI |
| PRs without screenshots | `shots` + `shots:publish`: screenshots to the `pr-shots` branch, linked in the PR, without the agent opening them |
| Playwright scripts with `bun` (they hung on Windows) | With `node` |
| Example templates cited that did not exist (`01-colores.md`) | An example inside `decisions/README.md` |

## What changed from v1

| v1 | v2 |
|---|---|
| 6 text agents to paste into a chat | 6 skills that activate on their own + 2 isolated QA agents |
| The `WEB_DESIGNER` agent invented the palette and the system | Claude Design designs; the orchestrator prepares the brief and checks the handoff |
| The handoff to development was implicit | `HANDOFF.md` with a mandatory structure and a verification checklist |
| Git as a text recommendation | An executable flow with parent branches, approval pause and push rule |
| Accessibility as a later audit | A mandatory gate before every commit |
| No device or functionality QA | `design-qa` (320–3840px, color blindness, zoom) and `functional-qa` (adversarial) |
| Generic stack | Next.js + TS, **bun**, **Context7**; the component library is decided per project |
| 10 design phases | 9 implementation phases, with 3 tracks depending on the project |

v1 remains valid for ChatGPT or for Claude without skills available: its agents are pasteable
prompts. v2 assumes Claude Code or Cowork with file access.
