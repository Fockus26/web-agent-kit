# User guide — Web Agent Kit

How the kit is used day to day, with a full example. `README.md` explains **what** each
piece is; this guide explains **what you do** and in which order.

You talk to Claude in Spanish, as always: the kit's files are in English, but its agents
answer, ask, and write PRs and commits in Spanish.

---

## 1. The idea in 30 seconds

You do not hand the kit to Claude in every conversation. The kit has two parts:

| Part | Installed | What it is |
|---|---|---|
| **Skills and agents** (`.claude/`) | Once, in `~/.claude/` | "How work is done": interviewing, implementing, checking accessibility, opening PRs, orchestrating |
| **Templates** (`context-templates/`, `CLAUDE.md.template`, `scripts/`, `github-templates/`) | In each new project, with `new-project.ps1` | The project's memory: what it is, what was decided, where everything stands |

Then you open Claude Code in the project's folder and talk normally. `CLAUDE.md` loads by
itself in every session and tells Claude what to read per task; the skills activate on
their own (or you call them with `/name`).

Your role is four moments: **telling the project**, **taking the brief to Claude Design**,
**choosing between options when they are presented to you** and **reviewing and merging the
PRs**.

---

## 2. Installation (once per machine)

```powershell
git clone https://github.com/Fockus26/web-agent-kit.git "$env:USERPROFILE\Desktop\agents\web-agent-kit"
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\install-kit.ps1"
```

`install-kit.ps1` copies the skills and agents to `~\.claude\`, replacing whatever version
was there (without leaving old files) and without touching what is not the kit's.

Then:

1. **Open a new Claude Code session.** Agents load at startup; a session that was already
   open does not see them.
2. Check with `/skills` (10) and `/agents` (4: `feature-worker`, `wave-qa`, `design-qa`,
   `functional-qa`).
3. Connect the **Context7** MCP (up-to-date library documentation).
4. Requirements: **bun**, **Node ≥ 23.6** (for the Playwright scripts), **git**, an
   authenticated **gh**, **PowerShell 7** (`pwsh`). If the project uses Supabase: **Docker
   Desktop** running and the **Supabase CLI**; if it uses Firebase: **Java (a JDK)** and
   `firebase-tools`, no Docker (QA runs against a local database). The `vercel` and
   `supabase` CLIs installed globally: the agents call them by name, not through `bun x`.

### Updating the kit

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\install-kit.ps1" -Pull
```

`-Pull` runs `git pull` in the kit before reinstalling. Then, a new session. The installer
leaves in `~\.claude\web-agent-kit.json` the clone's path and the installed version
(`kit-update` reads it).

Projects already created do not change on their own: each keeps in `.kit-version` the
version it was left on, and gets brought up to date with `/kit-update` (see §3, "Project
that followed an earlier kit version").

---

## 3. Creating a project

### New project

```powershell
& "$env:USERPROFILE\Desktop\agents\web-agent-kit\new-project.ps1" -Path C:\Users\Admin\Documents\Work\clinica-dental
```

It does, in this order:

1. `bun x create-next-app@latest clinica-dental --ts --tailwind --app --biome --react-compiler --import-alias "@/*" --use-bun`
   — **Biome** (not ESLint), **React Compiler** on, bun. Next already initializes git.
2. Copies `context/`, `phases/`, `scripts/`, `.github/` (PR template, CI and `release.yml`)
   and `.changeset/`, creates `design/` and `tests/unit/`. If the project has no version or
   CHANGELOG, `-NoVersion` skips the Changesets part.
3. Writes `CLAUDE.md` with the kit's template, **keeping the `@AGENTS.md` line** Next.js 16
   adds (so Claude reads that Next version's rules).
4. Adds to `package.json`: `test`, `test:related`, `shots`, `shots:publish`, `qa:local`,
   `context:backup`, `context:restore`, and the devDependencies `@types/bun`,
   `@playwright/test`, `@axe-core/playwright` and `@changesets/cli`.
5. `.gitignore`: screenshots, `.qa/`, Claude Desktop worktrees and the local working files
   of `context/` (the fixed documents stay in git — see §6).
6. Writes `.kit-version` with the kit's current version.
7. Formats what was copied with the project's Biome.

It overwrites nothing that exists and **does not commit**. The GitHub repo and the Vercel
deployment are asked by `/project-kickoff`: if you say yes, it makes the first commit,
creates the repo, applies the settings below and connects Vercel (`reference/DEPLOY.md`). It
only needs you to have a session:

```powershell
gh auth login
vercel login
```

If you prefer doing it by hand, or the agent could not (a 403, no session), this is what it
does:

```powershell
cd C:\Users\Admin\Documents\Work\clinica-dental
git add -A; git commit -m "chore: inicializa proyecto con web-agent-kit"
gh repo create <user>/clinica-dental --private --source . --push   # pr mode
```

On GitHub, protect `main`: require a PR (0 approvals, because you work alone), require the
`ci` check, no force-push or deletion. It is World Flags' configuration:

```bash
gh api -X PUT repos/<user>/<repo>/branches/main/protection --input - <<'EOF'
{"required_status_checks":{"strict":false,"contexts":["ci"]},"enforce_admins":false,
 "required_pull_request_reviews":{"required_approving_review_count":0},
 "restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
EOF
```

> **Private repos on GitHub's free plan do not support branch protection** (or rulesets):
> the API answers 403 "Upgrade to GitHub Pro". Options: a public repo, GitHub Pro, or going
> on without technical protection (the rules in `CLAUDE.md` still forbid agents from pushing
> to `main` or merging; what is lost is the block if someone skips that, and CI being
> mandatory before merging). A client's site is usually better private: the `context/`
> backup only runs on private repos.

Two more settings in the GitHub repo, once:

- *Settings › Actions › General › Allow GitHub Actions to create and approve pull requests*:
  without it, the Changesets Action cannot open the version PR. That PR is opened by
  `GITHUB_TOKEN`, which does not fire `pull_request`; that is why `release.yml` itself
  triggers `ci.yml` on the PR's branch and the `ci` check shows up without bypassing protection.
- *Settings › General › Automatically delete head branches*: the remote branch is deleted
  when the PR is merged.

And on Windows, if you will use `orchestrate`: exclude from Windows Defender the working
folder, the worktree pool's (`..\<repo>-wt`) and `%USERPROFILE%\.bun\install\cache`. With the
antivirus scanning every file in `node_modules`, installing and deleting takes three times as
long.

You can open Claude Code in the folder now.

### Project that followed an earlier kit version

Open a session in the project and type `/kit-update`, whichever version it comes from. It
does this:

0. Runs `git fetch` in the kit's clone and compares three versions: the project's, the
   installed skills' and the published one (`origin/main`). If the project is already on the
   published one, it says so and checks for missing pieces (scripts, devDependencies,
   `.gitignore`, the `context/` backup). If the installed skills are older, it reinstalls
   them and asks you to open another session and repeat `/kit-update` (skills load at startup).
1. Reads the project's `.kit-version`. If it does not exist (projects before 3.3.0), it
   deduces the version from signals (`decisions/`, `DECISIONS_INDEX.md`, `PHASE_LOG/`…) and
   shows them to you.
2. Computes the path with `UPDATES.md` (e.g. 3.5.0 → 3.6.0 → 3.7.0 → 3.8.0) and shows it
   before touching anything.
3. Diagnoses the whole path and asks you **a single round** of questions (for instance, if
   you had `context/` or `supabase/` entirely in `.gitignore`, it recommends putting the
   fixed part back in git and asks).
4. Applies each version in order, on a `chore/kit-<version>` branch, one commit per version,
   updating `.kit-version` at each step. One PR at the end.
5. What needs design (e.g. 3.3.0's status screens) it does not implement: it leaves it in
   `context/plans/backlog.md` and gives you the text for Claude Design
   (`prompts/CLAUDE-DESIGN-ADDENDUM.template.md`).

Projects created before 3.8.0 keep their `context/` in Spanish; nothing gets translated and
everything keeps working.

### Project you already created (or created with other options)

```powershell
& "...\web-agent-kit\new-project.ps1" -Path C:\path\to\project -Existing
```

Adds only the kit's pieces; does not touch the app. For a project already under way that
only lacks scripts, dependencies or `.gitignore` entries, `-OnlyPieces` instead: it does not
copy `phases/`, `context/`, `.github/` or `CLAUDE.md` (it is what `/kit-update` uses). If you also created it **with ESLint and
without React Compiler** (it happened with `melao`: `--biome` and `--react-compiler` were
missing; `--typescript` was valid, it is an alias of `--ts`), this leaves the app as if you
had created it right:

```powershell
bun remove eslint eslint-config-next
bun add -d @biomejs/biome babel-plugin-react-compiler
Remove-Item eslint.config.mjs
bun x biome init                 # or copy the biome.json create-next-app --biome generates
```

- In `next.config.ts`: `reactCompiler: true` inside `nextConfig`.
- In `package.json`: `"lint": "biome check"` and `"format": "biome format --write"`.
- Check: `bun run lint` and `bun run build`.

The `biome.json` Next 16 generates enables the `next` and `react` domains, Tailwind
directive support and import sorting; it is better than `biome init`'s.

### If PowerShell blocks the script

Windows PowerShell 5.1 ships with a policy that does not let `.ps1` files run. Use
PowerShell 7 (`pwsh`), or bypass the policy **only for that run**:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\new-project.ps1" -Path C:\path\project
```

---

## 4. The flow, with a full example

Example: a **landing page for a dental clinic** in Valencia.

### Step 1 — Kickoff (`/project-kickoff`)

You open Claude Code in the folder and write, in your own words:

```
/project-kickoff

Quiero una landing para una clínica dental en Valencia. Tienen logo azul (#0F6E8C) y usan
Inter. Secciones: hero, servicios, equipo, testimonios y agendar cita. Quiero que la cita
llegue por correo. El resto no lo tengo claro.
```

What happens:

1. It gives back what it already understood and **a single round of questions**: what only
   you know (what the site must achieve, audience, real content available, git mode
   `pr`/`local`, component library: shadcn/ui, Hero UI or MUI). Also: which **brand assets**
   the client has (logo, icon, favicon, OG) and which have to be created, whether to **create
   the GitHub repo and deploy on Vercel**, whether the site will need **maintenance mode**,
   whether it is versioned, and which **email provider** (Brevo by default).
2. The visual side **it proposes** with 3 directions (e.g. "editorial sobrio / técnico /
   cálido"), with the advantage and risk of each. You choose or let it choose.
3. It enters **plan mode**: summary, phase track (here *Landing*), sections, palette with
   measured contrasts, architecture, risks. **You approve the plan.**
4. It fills `context/` and `CLAUDE.md` with the real data (no `{{...}}`; what is missing
   stays `PENDING` + a row in `CONTENT_CHECKLIST.md`).
5. If you authorized repo and deployment, it creates and configures them
   (`reference/DEPLOY.md`), and makes the first `context/` backup.
6. It gives you **the brief for Claude Design** in a block ready to copy. Besides the pages,
   it asks for the status screens (404, 500, offline, maintenance), the text selection and
   scrollbar colors, the brand assets to create and, if the app sends emails, their
   templates (confirm account, recover password, order, form acknowledgment…).

### Step 2 — Design (you, in Claude Design)

You paste the brief into Claude Design. You come back with the design and a
**`HANDOFF.md`**, which you save in `design/HANDOFF.md`.

### Step 3 — Handoff review

```
Revisa design/HANDOFF.md
```

If something is missing (an error state, the mobile behavior, a measurement), it gives you
**the exact question** to send back to Claude Design. Do not skip it: an invented value here
is paid for by redoing sections later.

### Step 4 — Building, unit by unit

You follow the track's phases. Each unit is something you review in two minutes:

```
/frontend-build fase 01, tokens
```

What each unit does, without you asking:

```
branch feat/tokens  →  code  →  affected tests  →  a11y  →  build + typecheck + lint + tests
   →  screenshots (if something visible changed)  →  context/ up to date and backed up  →  PR
```

In **`pr` mode** you get a Pull Request (in Spanish) with: what changes, how to test it,
**screenshots** on mobile and desktop, light and dark, how it was verified and what was not,
decisions taken and manual actions. **You review it and merge it** (squash). If you ask for
changes, they are made on the same branch.

Next units: `fase 02, layout base`, `fase 03, componentes: botón y tarjeta`,
`fase 04, sección hero`… For the booking form:

```
/backend-build formulario de agendar cita con envío por correo
```

It proposes the email provider if it is not decided (Brevo by default), validates on the
server, and at the end lists **what you have to do** (create the provider account, set the
environment variable on Vercel…).

### Step 5 — QA

While building, the agent launches `functional-qa` by itself when a risk flow closes (auth,
data that is saved, payments). The full QA is once per version — phase 09, or before you
merge a later version's `chore(release)` PR:

```
Haz el QA de versión
Lanza functional-qa sobre el formulario de cita
```

They run isolated (their noise does not fill your session) and give you back a report with
verified findings. The fixes are new units, each closed by its reproduction script. Before
each task the agent also tells you `Modelo recomendado: …`: if it is not the session's,
switch with `/model` and `/effort` before it goes on.

### Step 6 — Batches: when you come with a list

Weeks later you come back with several things at once:

```
/orchestrate

- El formulario de cita debería dejar elegir el tratamiento
- Añadir la sección de precios
- Los testimonios en móvil se ven apretados
- Que el botón de WhatsApp flote en móvil
```

What happens:

1. It maps each point to the code (against `origin/main`) and asks you **at once** the
   questions that block (e.g. "¿los precios son reales o placeholder?", "¿pueden los workers
   levantar el servidor?").
2. It groups (what touches the same files goes together), orders into **waves** and
   reserves numbers (decisions, checklist rows) so they do not collide.
3. It leaves the plan and the prompts in `context/plans/` and launches one
   **`feature-worker`** per unit, in parallel, each in a **worktree pool** slot
   (`..\<repo>-wt\wt1..wtN`, with its port 4301, 4302…). Slots are not deleted:
   `node_modules` is already there and each unit only installs if `bun.lock` changed. The
   first time in a project, the orchestrator runs `wt init`.
4. You get **one PR per unit**, each with its changeset (without touching `version` or
   `CHANGELOG.md`: they do not collide). Merge them in any order; after each merge the
   orchestrator frees the slot (`wt free`).
5. When you tell it you merged all the wave's PRs, it launches **`wave-qa`**: it starts the
   server on `main` and walks the wave's flows as a real user, logged in (see "Test
   accounts" below). Critical and high findings move to the next wave.
6. It closes the wave with a short summary: **which phase and wave you are in, what QA left
   and which wave is next**, and backs up `context/`. You say *"inicia la ola en otra
   sesión"* and it opens a new session with the start prompt (or gives it to you to paste,
   if it cannot open one). Each wave in its own session: none drags the previous ones'
   context, and that saves tokens on every message.
7. When you want to publish, you merge the **`chore(release): versión`** PR the Action keeps:
   it gathers the changesets, bumps the version and writes the CHANGELOG.

Meanwhile you can carry on with something else. Whatever occurs to you later goes to
`context/plans/backlog.md`, not into the running batch.

**A whole phase in waves.** The same works for building: `/orchestrate arranca la fase 04`
splits the phase into waves (`context/plans/phase-04-sections.md`) and launches the first.
Each closing tells you "Fase 04 · ola 2 de 3 cerrada · sigue ola 3"; after the last one, the
next phase follows.

**QA against a local database.** QA never touches the real database. `bun run qa:local`
starts Supabase in **Docker Desktop** (keep it running), applies `main`'s migrations and seed,
creates the test accounts and starts the server pointing at that database. There QA can
create, break and change whatever it wants: each run starts from scratch, and the emails the
app sends stay in Mailpit. That is why the local database is **disposable**: keep nothing of
yours in it. With **Firebase** it is the same with the emulators (they need Java, not
Docker; the emails stay in the emulator's UI). `--preview` serves the build instead of the
dev server.

**What happens with the QA's findings.** The Critical and High ones are fixed **in the same
wave**: each fix closes when the finding's reproduction script goes from FAIL on `main` to
PASS on its branch; there is no second QA of the fixes. The next QA only tests what changed
since the last one (and what was never tested). When you work without waves (a loose unit,
a cloud session), closing a risk flow (auth, saved data, payments) launches `functional-qa`,
or leaves "QA pendiente" in "Blocked" so it is never forgotten. `design-qa` runs only at
the version QA: phase 09, and before you merge a later version's `chore(release)` PR. A
wave of sections or styles gets no `wave-qa`.

Without Docker on the machine (or without a local database yet), the wave is not blocked: QA
runs with `bun run qa:local -- --offline`, guest only, and the wave's closing tells you the
logged-in test is pending.

**Test accounts.** As soon as the site has login, `backend-build` asks you to fill
`.env.test.local` with one pair per role:

```
EMAIL_TEST=…            PASSWORD_TEST=…            # regular user
ADMIN_EMAIL_TEST=…      ADMIN_PASSWORD_TEST=…      # administrator
EDITOR_EMAIL_TEST=…     EDITOR_PASSWORD_TEST=…     # any other role: <ROLE>_…
```

You make up the values: those accounts only exist in the local database; the script creates
them on every run. QA logs in with them only on localhost and without seeing the values (the
scripts read them from the environment).

The only thing the project has to meet: the whole schema as migrations in
`supabase/migrations/`, in git (a change made only in the dashboard does not exist locally)
and a `supabase/seed.sql` with the minimum to walk through the flows. `backend-build` already
does it that way.

### Step 7 — Giving what was learned back to the kit

Throughout the project, every time you correct something the agent did following the kit,
ask it for the same thing a second time, do by hand a step it could do, or the kit did not
say what to do, the agent logs it in `context/KIT_FEEDBACK.md` (if it was already there, it
adds a "time"). You do not have to ask.

Whenever you want (and always when closing phase 09), in the project:

```
/kit-feedback
```

It builds the report with what had not been sent (grouped by kit piece, most repeated first)
and opens a PR on the kit's repo with the `kit-feedback` label. It does not clone the kit or
touch your local copy.

PRs from several projects pile up there. When you want to process them, open a Claude Code
session in the kit's folder and write:

```
Revisa el feedback
```

Its `CLAUDE.md` tells it how: a triage of all the PRs at once (what repeats across projects
adds up, what is already solved, what is specific to one project), it lets you choose what
goes in, implements it, bumps the version, writes in `UPDATES.md` the steps for the other
projects and comments on each feedback PR what went in. You merge: the improvement's and the
feedback ones (they stay in `feedback/` as history). Then, `/kit-update` in each project.

### Working from the cloud (claude.ai/code, the mobile app)

A cloud session clones the project's repo into a fresh container and deletes it when the
session ends. The kit works there because the project carries its own copy of the skills and
agents in `.claude/` (the global `~/.claude/` does not exist there). What changes for you:

- **Each unit ends merged into `main`.** The agent opens the PR, waits for CI and, when it
  is green, merges it itself (squash). That way nothing is left in a branch of a container
  that no longer exists. If CI is red it fixes it; if `main`'s protection demands a human
  review, the PR stays open and it tells you. The version PR (`chore(release)`) is still
  yours. If you want to review a cloud unit before it merges, say so when you ask for it.
- **The local `context/` comes back by itself**: the project's `SessionStart` hook
  (`scripts/cloud-setup.sh`) runs `bun install` and `bun run context:restore` before your
  first message, and the agent backs it up when closing each unit. Without a
  `context-state` branch (public repo, never backed up) it starts without the phase state.
- **What the cloud does not have:** PowerShell (so no worktree pool: `orchestrate` runs the
  wave's units one after another), Docker (`qa:local --offline`). `.env.local` comes from Vercel
  if you set up the environment once (`reference/DEPLOY.md` §2d): `VERCEL_TOKEN`,
  `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID` in its settings and `api.vercel.com` allowed. Never
  paste keys into the chat.
- **Requirement:** the project on kit 3.10.0 or later and the repo connected to Claude's
  GitHub app. `/kit-update` also runs in the cloud: it clones the kit and downloads
  PowerShell for the session; what needs your machine (Vercel, Docker) goes to the PR's
  manual actions.
- **A project that does not have the kit copy yet** (on a version before 3.10.0) does not
  have `/kit-update` in the cloud either. The first time, open a cloud session of the
  project and write: *"Agrega el repo Fockus26/web-agent-kit a la sesión, clónalo y sigue su
  `.claude/skills/kit-update/SKILL.md` para actualizar este proyecto."* When it finishes,
  open a **new** session: that is where the skills are loaded.

---

## 5. Day-to-day commands

| Command | For |
|---|---|
| `bun run test:related` | Only the tests affected by what changed (by real imports) |
| `bun run test` | The whole suite (before the PR; CI always runs it) |
| `bun run lint` / `bun run format` | Biome |
| `bun run shots` | Screenshots of the states defined in `.pr-shots.json` (uses node + Playwright) |
| `bun run shots:publish` | Uploads the screenshots to the `pr-shots` branch; markdown in `.pr-shots/README.md` |
| `bun run qa:local -- --port <p>` | Server against the local database (Supabase or Firebase emulators) with the test accounts (`--offline` without one, `--preview` for the build) |
| `bun run context:backup` | Copies the local `context/` to the `context-state` branch |
| `bun run context:restore` | Brings it back after losing the folder (never overwrites a local file) |
| `vercel env pull .env.local --yes` | Brings the environment variables from Vercel (Development) to `.env.local` |
| `bun x playwright install chromium` | Once per machine, before the first screenshot or audit |
| `ssh kit-vps kit-db list` | The databases on your VPS (only once you set it up: `reference/VPS-POSTGRES.md`) |

Normally you do not run them: the skills do. They are there for when you want to check
something.

---

## 6. What to keep and what not to touch

- **What goes in git and what is local.** In git: the code, `supabase/` (migrations, seed,
  templates) and the fixed documents of `context/` (`PROJECT_CONTEXT`, `DESIGN_RULES`,
  `COLORS`, `DESIGN_TOKENS`, `TYPOGRAPHY`, `decisions/`) — they are what a new session needs
  to know what was decided. Local: the working state (`CURRENT_PHASE`, `CONTENT_CHECKLIST`,
  `KIT_FEEDBACK`, inventories, `PHASE_LOG/`, `plans/`), because parallel workers would
  collide on it in every PR. **Never ignore the whole of `context/` or `supabase/`.**
- **Environment variables: Vercel is where they live.** `.env.local` is a copy pulled from
  there (`vercel env pull`), not a file you edit: a new variable goes in Vercel (`vercel env
  add`, or the dashboard) and is pulled again. Your machine's overrides, in
  `.env.development.local`. GitHub Secrets only receives the variable a workflow needs: it
  cannot be read back, so it is never the source. Detail: `reference/DEPLOY.md` §2c.
- **If you lose the folder:** clone the repo, run `bun run context:restore` and
  `vercel env pull .env.local --yes`. The local state comes back from the
  `context-state` branch as of the last backup (the agents make one when closing each unit
  and each wave; only on private repos), and the variables from Vercel.
- **`context/CURRENT_PHASE.md`** is a board (≤ 60 lines): what is open, what blocks, what is
  next. If it grows, what is closed moves to `PHASE_LOG/<branch>.md`. The agents prune it
  when closing each unit; if you see they do not, ask them.
- **`context/decisions/`**: one file per decision; its first line is the index row
  (`grep -rh "^# D" context/decisions/`). What was decided is not re-litigated; if you change
  your mind, a new decision is recorded and the old one becomes `Obsolete → D0NN`.
- **`context/CONTENT_CHECKLIST.md`**: all the provisional text/images. It is your list of
  what the client has to send before publishing.
- **The `pr-shots` and `context-state` branches** are orphan branches the scripts maintain.
  Deleting `pr-shots` when it gets heavy is your call (`git push origin --delete pr-shots`);
  the agents never delete branches. Do not delete `context-state`: it is the backup.

---

## 7. Known problems

| Symptom | Cause | What to do |
|---|---|---|
| "Agent type 'feature-worker' not found" | The session opened before installing/editing the agent | New session |
| In a cloud session the kit's skills/agents do not exist | The project has no copy in `.claude/` (kit < 3.10.0), or it is gitignored | The first-time message of "Working from the cloud" (§4), then a new session |
| Playwright hangs launching Chromium | Playwright script run with `bun` on Windows | With `node` (the kit's scripts already do) |
| A measuring script cannot find `@playwright/test` | It was saved in the scratchpad or `$TEMP` | Save it in `.qa/` inside the project |
| `bun test` fails without tests | There are no test files yet | The `test` script uses `./tests/unit --pass-with-no-tests` |
| The full suite hangs or crashes with several workers | Bun with piped output on Windows / PGlite out of memory / at the same time as the build | Alone, in the background, to a file: `bun run test > .qa/test.log 2>&1` |
| `tsc`/`next build` fails in `scripts/*.ts` | `@types/bun` or `@playwright/test` missing | `bun add -d @types/bun @playwright/test` (the kickoff script already does) |
| The `.ps1` does not run | PowerShell 5.1's execution policy | `pwsh`, or `-ExecutionPolicy Bypass -File` just for that run |
| `next dev` rewrites `AGENTS.md` again | Next.js 16 regenerates it | Normal: committed with the rest; `CLAUDE.md` imports it with `@AGENTS.md` |
| `tsc` in CI: "Cannot find name LayoutProps" | Next 16 generates those types in `.next/` on dev/build | `bun run typecheck` = `next typegen && tsc --noEmit` (already in the kickoff script and CI) |
| A 500 that survives restarts in dev | Turbopack left it cached in `.next/dev` after a subprocess timeout | Shut down, delete `.next/dev`, restart |
| A worker could not write in the local `context/` | Sandboxed worktrees do not write in the main folder | It delivers it in its report and the orchestrator copies it |
| `wt take`: "No free slots" | Every pool folder has an open unit | Wait for one to be merged (`wt free`) or grow it: `wt init -Count 6` |
| `wt free` aborts | The slot has uncommitted changes | See what they are (`wt status`); they are never discarded on their own |
| The pool is slow (install, deletes) | Windows Defender scans every file in `node_modules` | Exclude the working folder, `..\<repo>-wt` and `%USERPROFILE%\.bun\install\cache` |
| A server lands on another slot's port | A previous server was left orphaned on its port | `wt take`/`free` now stop it; by hand: `taskkill /PID <pid> /T /F` |
| The version PR does not show up | The Action has no permission to open PRs | Settings › Actions › General › "Allow GitHub Actions to create and approve pull requests" |
| The version PR has no `ci` check | PRs opened with `GITHUB_TOKEN` do not fire `pull_request` | `ci.yml` with `workflow_dispatch` and `release.yml` with the "CI for the version PR" step and `actions: write` (kit templates). Meanwhile: Actions › CI › Run workflow on `changeset-release/main` |
| `changeset version` does not bump the version | `private: true` app without `privatePackages.version: true` | Use the kit's `config.json` (`changeset-templates/`) |
| `context:backup` refuses | The repo is public (the checklist may hold client data) | Make the repo private, or `CONTEXT_BACKUP_PUBLIC=1` if you accept it |
