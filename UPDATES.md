# Kit updates — versions and migration path

Each project keeps in **`.kit-version`** (repo root, in git, one line) the kit version it is
aligned with. The kit's current version is in [`VERSION`](./VERSION).

To update a project you do not pick a migration by hand: in a session opened in the
project, the [`kit-update`](./.claude/skills/kit-update/SKILL.md) skill (`/kit-update`). It
compares `.kit-version` with the kit's published version (`origin/main`), computes the path
(every later version, in order) and applies each step of this list on a single branch, one
commit per version.

**Projects created before 3.8.0 have their `context/` in Spanish.** The steps below are
written in English; when a step copies a section from a template into such a project, it is
written with the project's language and headings (e.g. `pendientes.md`, "Correos"), not
translated. Nothing in an older project gets translated by a migration.

---

## How to tell a project's version without `.kit-version`

Projects before 3.3.0 do not have the file. It is deduced from signals, newest to oldest
(the first one that holds wins):

| If the project… | It is on |
|---|---|
| has `scripts/cloud-setup.sh` and the kit's skills in `.claude/skills/` | **3.10.0** |
| has `context/decisions/D0NN-*.md` (one file per decision) and no `context/DECISIONS_INDEX.md` | **3.2.0** |
| its `CLAUDE.md` talks about the worktree pool (`..\<repo>-wt`, `wt take`) | **3.1.0** |
| has `context/PHASE_LOG/` and `context/CURRENT_PHASE.md` | **3.0.0** |
| has no `context/PHASE_LOG/` | **2.x or earlier**: no automatic path. `new-project.ps1 -Existing` adds what is missing without overwriting anything and you go on from 3.0.0 |

The signals do not depend on Changesets on purpose: a project **without versioning**
(created with `-NoVersion` / `-SinVersion`, or its `CLAUDE.md` says so) has no `.changeset/`
or `release.yml` and is not older because of it. In that project, the Changesets steps of
any version are skipped: they are not a pending migration. If the signals contradict each
other, the agent shows them and asks before choosing.

---

## 3.11.0 — 2026-10-20 · Feedback round 2 (inversiones-js, world-flags)

**What changed**

- **`new-project.ps1 -OnlyPieces`** (implies `-Existing`): only the pieces the skills take
  for granted — scripts, `package.json` scripts and devDependencies, `.gitignore`, Biome, the
  kit copy in `.claude/`. No `phases/`, `design/`, `.github/`, `.changeset/`, `context/`,
  `CLAUDE.md` or `.kit-version`. `kit-update`'s piece check uses it. It adds `typecheck`
  (`next typegen`) only in Next.js projects, and rewrites `package.json` only if it added a
  script. Why: two projects got phases and CI they did not need, and an Astro one a Next
  typecheck.
- **`test-related.ts --dir=<folder>`** (repeatable) replaces the default `tests/` and `src/`.
  Why: integration tests needing an emulator (Firebase `tests/rules`) ran — and failed — on
  every `package.json` change.
- **`qa-local.ts`** installs Playwright's Chromium if it is missing (with node and the
  project's Playwright; not in the cloud), and starts Supabase without Studio and analytics
  and with `health_timeout` 5m through env overrides (the project's `config.toml` is not
  touched). Why: the QA stopped twice for the browser, and on a slow machine the stack's
  2-minute health check ran out.
- **`git-flow`**: a PR that will still get commits (QA in progress) is opened as a draft
  and marked ready when done. Why: César merged a PR while its QA commit was being pushed
  (world-flags #95 → #100).
- **`orchestrate`**: an environment check before §0 (bun, gh, pwsh, agents, local
  `context/`, `context:restore` if it is missing). Why: on a new machine a wave failed for
  everything that was missing.
- **`CLAUDE.md.template`**: no absolute path to the main folder (it was another PC's), and
  from any worktree — pool slot or `.claude/worktrees/` — `context/` changes go back in the
  report. Why: a session worktree's hook blocked writing to the main `context/`.
- `UPDATES.md` 3.8.0 step 4: if a decision fixed the ignore of `supabase/`, a new decision
  supersedes it.

**Not taken in:** stopping Astro 7's daemonized `astro dev` from `qa-local` (world-flags):
specific to a stack the kit does not cover end to end, and not verifiable here. A project
on Astro ≥ 7 adds `astro dev stop` to its own `qa-local` exit.

**Steps for a project on 3.10.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session).
2. `scripts/test-related.ts` and `scripts/qa-local.ts` ← `<kit>/reference/scripts/`. If the
   project had edited them (`ENV_MAP`, `ROLE_BY_ENV`, `assignRole`, its own globs), carry
   those edits over instead of overwriting. If it has tests that need an emulator or a
   database, its `test:related` script gets `--dir=<the unit tests' folder>`.
3. `CLAUDE.md`, section on what goes in the repo: replace the absolute path of the main
   folder and the sentence about the subagent in a slot with: "it is read in the main folder
   (first line of `git worktree list`). From a worktree (pool slot or `.claude/worktrees/`)
   you may lack write permission there: return the `context/` changes in your report." (in
   the project's language).

---

## 3.10.0 — 2026-10-20 · Cloud sessions

**What changed**

- **Each project carries its copy of the kit's skills and agents** in `.claude/skills/` and
  `.claude/agents/`, committed. Why: a Claude Code cloud session (claude.ai/code, the mobile
  app) clones only the repo; `~/.claude/` does not exist there, so the kit's skills and
  agents were missing. `install-kit.ps1 -Project <path>` / `install-kit.sh --project <path>`
  copies them (replacing only the kit's); `new-project.ps1` runs it, and `kit-update`
  refreshes the copy after every update. On César's machine the global skills win over the
  project's (same version after `kit-update`).
- **New skill `cloud-session`**: at the start, checks `node_modules` and the local
  `context/`; maps what the cloud lacks (`gh` → GitHub MCP, no `pwsh` so no worktree pool,
  no Docker, no `.env.local`); and **closes each unit with a PR that the agent merges into
  `main` (squash) once CI is green**. Why: the container is deleted when the session ends,
  and work left in open cloud PRs was being forgotten (César's decision, 2026-10-20, over
  auto-merge — needs protection with required checks — and pushing straight to `main` —
  skips CI). It never merges red, never bypasses protection, never merges the version PR.
- **`scripts/cloud-setup.sh` + `SessionStart` hook** in `.claude/settings.json`
  (`reference/claude/settings.json`): in the cloud only (`CLAUDE_CODE_REMOTE=true`) it runs
  `bun install` and `bun run context:restore`; on the machine it does nothing.
- `CLAUDE.md.template` (one line: cloud sessions use `cloud-session`, which overrides "never
  push to main / never merge"), `git-flow` and `orchestrate` point to it; its piece check
  covers the copy and the hook.
- **`kit-update` runs in the cloud too**: it clones the kit into the scratchpad, downloads
  PowerShell there for the `new-project.ps1` steps, skips the global install and closes per
  `cloud-session`. A project without the copy yet gets it the first time by asking the
  session to follow the cloned kit's `kit-update` (GUIDE.md, "Working from the cloud").

**Steps for a project on 3.9.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (already done if `kit-update`
   runs it; skipped in a cloud session).
2. `pwsh -File "<kit>/new-project.ps1" -Path . -OnlyPieces` (plus `-NoVersion` if the project is
   without versioning): it adds `scripts/cloud-setup.sh`, `.claude/settings.json` and the
   copy of the skills and agents, and overwrites nothing else. If `.claude/settings.json`
   already existed without the hook, merge the `SessionStart` of
   `<kit>/reference/claude/settings.json` into it, keeping what it had.
3. Check that `.claude/skills`, `.claude/agents` and `.claude/settings.json` are not
   gitignored (`git check-ignore -v .claude/skills .claude/settings.json`); if a rule ignores
   all of `.claude/`, replace it with `.claude/worktrees/` and `.claude/settings.local.json`.
4. `CLAUDE.md`, section "How work is done here" / "Cómo se trabaja aquí": after the bullet of
   `pr` mode, one bullet (in the project's language): "**Cloud session**
   (`CLAUDE_CODE_REMOTE=true`): `cloud-session` skill at start and close. It overrides both
   rules above: each unit ends merged into `main` (PR + green CI)." Check `wc -c CLAUDE.md`
   ≤ 8 KB.
5. **Manual action for César** in the PR: for the cloud, the repo has to be connected to
   Claude's GitHub app, and the variables the build needs go in the cloud environment's
   settings (claude.ai/code › environment), never in the repo.

---

## 3.9.0 — 2026-10-16 · Environment variables: Vercel is the source

**What changed**

- **`reference/DEPLOY.md` §2c**: the real values live in Vercel, per environment;
  `.env.local` is pulled from there (`bunx vercel env pull .env.local --yes`, Development)
  and never edited by hand; this machine's overrides go to `.env.development.local` (it wins
  over `.env.local` in `next dev`); `.env.test.local` stays local. A new variable: name in
  `.env.example`, values in Vercel as an action for César (Production/Preview secrets with
  `--sensitive`), pull. GitHub Secrets only for the variable a workflow needs, one by one.
  Why: the `.env*` files were gitignored and not in any backup — losing the folder lost the
  keys — and GitHub Secrets, the usual suggestion, is write-only: it can receive a `.env`
  but never give it back.
- `backend-build` (Secrets), `project-kickoff` (Step 4b: the first pull), `GUIDE.md` §5–6 and
  the comment in `ci.yml` follow it. `CLAUDE.md.template` no longer lists `.env*` among the
  files backed up to `context-state` (they never were).

**Steps for a project on 3.8.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (already done if `kit-update`
   runs it).
2. `CLAUDE.md`, section on what goes in the repo ("What goes in the repo and what is local" /
   "Qué va al repo y qué es local"): take `.env*` out of the local list backed up to
   `context-state`, and in its place one line: "`.env.local` is pulled from Vercel, never
   hand-edited (`vercel env pull`; kit `reference/DEPLOY.md` §2c)." (in the project's
   language). It replaces, the size barely grows.
3. **If the project is linked to Vercel** (`.vercel/project.json`): the "First pull" of
   DEPLOY §2c — compare the names of `.env.local` with `bunx vercel env ls development`
   (names only, never values) and list in the PR, as an **action for César**, the variables
   that are only local (upload them to Development) and the ones that are this machine's
   (move them to `.env.development.local`). The agent **does not** run the pull in the
   migration: it would erase what is only local. César runs it once he has uploaded them.
4. **If it is not linked to Vercel:** nothing; `.env.local` stays as it is and the first
   pull comes with the deployment (DEPLOY §2).
5. If a workflow in `.github/workflows/` reads `secrets.*` other than `GITHUB_TOKEN`: list
   them in `PROJECT_CONTEXT.md` › Repo and deployment as duplicated in GitHub (they are set
   again when they change in Vercel).

---

## 3.8.0 — 2026-10-16 · The kit in English, `context/` backup, git rules for `context/` and `supabase/`

**What changed**

- **The kit is written in English** (skills, agents, templates, guides, scripts' comments and
  messages). The agents still talk to César in Spanish — questions, reports, PR titles and
  bodies, commit descriptions — and site copy stays in the site's language. New projects get
  English `context/` templates; **existing projects keep their Spanish `context/`** and the
  skills read both. Why: César asked for it; the language he talks in did not change.
- **Renamed:** `GUIA.md` → `GUIDE.md`, `ACTUALIZACIONES.md` → `UPDATES.md`,
  `instalar-kit.*` → `install-kit.*`, `nuevo-proyecto.ps1` → `new-project.ps1` (parameters
  `-Path`, `-Existing`, `-NoVersion`), `reference/qa-scripts/` → `reference/scripts/`,
  `CLAUDE-DESIGN-ADENDA` → `CLAUDE-DESIGN-ADDENDUM`, the 3.1/3.2 migration prompts →
  `prompts/MIGRATE-3.1-…` / `MIGRATE-3.2-…`, `fase-plan-template` → `phase-plan-template`. The
  old script names stay as forwarding files: the `kit-update` installed from 3.6/3.7 calls
  `instalar-kit.ps1`. `~/.claude/web-agent-kit.json` now writes `path`/`installed` (the skill
  also reads the old `ruta`/`instalado`). New projects' plan files are `backlog.md`,
  `phase-0N-*.md`, `orchestration-*.md`.
- **Backup of the local `context/`**: `scripts/context-backup.sh` (`bun run context:backup` /
  `context:restore`) copies the gitignored files of `context/` to the orphan branch
  `context-state` (only commits if something changed; `--restore` never overwrites a local
  file; refuses on public repos). `git-flow` runs it when closing each unit, `orchestrate`
  when closing each wave. Why: the working state (phase, wave, pending content, plans) is
  local on purpose so parallel workers do not collide, but losing the folder meant a new
  session started blind.
- **What goes in git, explicitly:** `supabase/` (except `.temp/`, `.branches/`, `.env`) and
  the fixed documents of `context/` (`PROJECT_CONTEXT`, `DESIGN_RULES`, `COLORS`,
  `DESIGN_TOKENS`, `TYPOGRAPHY`, `decisions/`). `new-project.ps1` writes the `.gitignore`
  with only the local files of `context/`, plus `.qa/`. `kit-update`'s piece check flags a
  project that ignores all of `context/` or `supabase/`. Why: a project had both ignored —
  with the folder lost, neither the schema nor the decisions would have survived, and the
  pool slots and `wave-qa` never saw the migrations.
- The orphan branches `pr-shots` and `context-state` carry a `vercel.json` with deployments
  disabled (pushing them used to trigger a failing Vercel build).
- `design-qa.ts` writes to `.qa/design-qa/` and waits for `load` instead of `networkidle`
  (which may never arrive in dev).

**Steps for a project on 3.7.0**

1. Global pieces: `powershell -ExecutionPolicy Bypass -File <kit>\install-kit.ps1 -Pull`
   (or the old `instalar-kit.ps1`, which forwards) and a new session. If `kit-update` runs
   the update, it is already done.
2. **Do not translate anything** in the project: its `context/`, `CLAUDE.md` and decisions
   stay in Spanish.
3. **Diagnosis** (changing nothing), in a table:
   - `git check-ignore -v supabase/migrations context/PROJECT_CONTEXT.md context/decisions context/CURRENT_PHASE.md`:
     which are ignored and by which rule;
   - repo visibility: `gh repo view --json visibility -q .visibility`;
   - whether `.qa/` is ignored.
4. **If `supabase/` or the fixed documents of `context/` are ignored:** a question for César
   in the single round, with the recommendation and its reason (losing the folder loses the
   schema and the decisions; the pool and `wave-qa` do not see the migrations; if the reason
   was privacy, the answer is a private repo). With his yes: in `.gitignore`, replace the
   rule that ignores them with the explicit local list (`context/CURRENT_PHASE.md`,
   `context/CONTENT_CHECKLIST.md`, `context/KIT_FEEDBACK.md`, `context/GIT_STATE.md`,
   `context/*_INVENTORY.md`, `context/PHASE_LOG/`, `context/plans/`, and for Supabase only
   `supabase/.temp/`, `supabase/.branches/`, `supabase/.env*`); check there are no secrets
   in what gets added (`grep -rniE "password|secret|service_role|sk_live" supabase context`);
   `git add` them in this PR. If a decision in `context/decisions/` fixed that ignore (e.g.
   `/supabase/*`), record a new one that supersedes it and mark the old one
   `Obsolete → D0NN`. Without his yes, leave it and note it in the report.
5. `scripts/context-backup.sh` ← `<kit>\reference\scripts\context-backup.sh`, and in
   `package.json`: `"context:backup": "bash scripts/context-backup.sh"`,
   `"context:restore": "bash scripts/context-backup.sh --restore"`. `.gitignore`: `.qa/` if
   it is not there.
6. `scripts/publish-pr-shots.sh` ← `<kit>\reference\scripts\publish-pr-shots.sh` (no
   project-specific parts; adds the `vercel.json` to `pr-shots`).
7. `CLAUDE.md`, section on what goes in the repo ("Qué va al repo y qué es local"): add to
   the local line "— respaldo: `bun run context:backup`" and make sure the git line includes
   `supabase/`. It replaces words in existing lines; the size does not grow.
8. **First backup:** if the repo is private, run `bun run context:backup` in the main folder
   at the end of the migration (it only pushes the `context-state` branch). If it is public,
   it is a question for César: make the repo private, or no backup (or
   `CONTEXT_BACKUP_PUBLIC=1` if he accepts the checklist being public).
9. `scripts/qa-local.ts` does not need to change (the kit's is the same, translated). If it
   is replaced anyway, its project-specific parts are now named `ENV_MAP`, `ROLE_BY_ENV` and
   `assignRole`.

---

## 3.7.0 — 2026-10-16 · Feedback from inversiones-js, Melao, Maranatha and World Flags

**What changed** (each point, with the incident that prompted it, in the piece it changes)

- **Batch brief and `feature-worker`**: environment rules the workers kept rediscovering.
  Files with Write/Edit, not through the shell (heredoc, `node -e` with backticks and Python
  on Windows broke files 6 times). Full suite alone, in the background and to a file (Bun
  hung or PGlite ran out of memory with several workers). Server: a free port or nothing,
  stop by PID with the tree, never `<framework> stop`; `.next/dev` for Turbopack's 500.
  Playwright scripts in the slot's `.qa/` (from the scratchpad they cannot find the
  package). Waits in the background (`sleep` is blocked). Commit per stage and `git status`
  when resuming after a 429. `test:related` falls back to `bun test`.
- **`orchestrate`**: maps and reserves numbers against `origin/main` (a D that already
  existed got reserved, and an already-applied migration was requested); compares the
  requested values with the implemented decision, checks there is a DOM test environment
  and opens the image before proposing its alt. Optional range of custom error codes.
  Without a local database, the wave closes with guest QA (`--offline`) instead of staying
  blocked. The prompt template suggests measuring before/after on `main` and on the branch
  for fixes.
- **`wt.ps1`**: `take` and `free` stop whatever still listens on the slot's port (orphaned
  servers that made the next one jump ports); `.qa/` is ignored in every slot
  (`.git/info/exclude`).
- **`qa-local.ts`**: `--offline` (no database: variables to a dead address, guest only);
  aborts if the port is taken (also IPv6-only); on Windows it kills the server's tree; every
  error ends the process with a message. The env map covers `PUBLIC_*` and `VITE_*`. Roles by
  a list in a variable (`ADMIN_EMAILS`) and an example of access through a subscription.
- **`publish-pr-shots.sh`** also leaves the markdown in `.pr-shots/README.md` (a `tail` cut
  it). `git-flow`: rewrite `.pr-shots.json` on every unit (other units' screenshots got
  published), the field is `base`, `shots:publish` in the background.
- **`new-project.ps1`**: `@axe-core/playwright` as a devDependency (a worker cannot add it
  and ended up loading axe from a CDN); `.claude/worktrees/` out of git and out of Biome
  (Claude Desktop's worktree brought another `biome.json` and broke the lint).
- **`kit-update`**: piece check even when the version is up to date (a project on 3.5.0 had
  no `test:related` or `shots`); it adds them with `new-project.ps1 -Existing`.
- **No versioning** is an official path: a line in `CLAUDE.md`, `git-flow` without
  changesets, and the deduction table no longer uses Changesets as a signal.
- **Emails**: default sending provider (Brevo over SMTP) in a decision and a question at
  kickoff; without custom SMTP Supabase only delivers to the team. Firebase Auth: check
  before designing whether the console lets you edit the templates; if not, send them
  yourself with the Admin SDK.
- **Design**: scrollbar (`scrollbar` tokens, ≥ 3:1) next to `::selection` in the brief,
  handoff, addendum, `COLORS.md`, phase 02 and `design-qa`. A provisional logo swapped for
  the real one without redoing the icon or the OG (`BRAND-ASSETS.md` and addendum).
- **Skills**: `frontend-build` (a `'use client'` module exports only components), `a11y`
  (focus by state, not by a mount `useRef`, because of StrictMode), `seo` (headings counted
  on the DOM by accessible name, not with grep). `DEPLOY.md`: adopting an existing Vercel
  project. 3.2.0 migration: grouped decision sections.
- **When publishing a version**: each step says which `CLAUDE.md` paragraph it replaces, and
  what to do if the file it edits is missing.

**Steps for a project on 3.6.0**

1. Global pieces: `powershell -ExecutionPolicy Bypass -File <kit>\install-kit.ps1 -Pull` and
   a new session. If `kit-update` runs the update, it is already done.
2. **Piece check** of `kit-update` (axe as a devDependency, `.claude/worktrees/` in
   `.gitignore` and `biome.json`, the kit's scripts): what is missing, with
   `new-project.ps1 -Path . -Existing`.
3. `scripts/publish-pr-shots.sh` ← `<kit>\reference\scripts\publish-pr-shots.sh` (no
   project-specific parts).
4. `scripts/qa-local.ts`: it has project-specific parts (what was added to the env map, the
   role assignment). Copy the kit's and put those project parts back on top (`git diff` of
   the file to see them). If the role is decided by a list in a variable, move it to the
   role-by-env map. Check: `bun run qa:local -- --port 4399 --offline` starts and the site loads.
5. `CLAUDE.md`: only if the project is **without versioning**, its "Version" line takes the
   "no versioning" alternative of `<kit>\CLAUDE.md.template` (it replaces, it does not add).
6. `context/COLORS.md`: `scrollbar.thumb / scrollbar.track` rows in light and dark. If the
   file does not exist, create it with only those rows and `selection`. If the base layout
   is already done and the design has no scrollbar: the addendum's "Scrollbar" block to
   César and the unit (tokens + CSS) to the backlog (`context/plans/pendientes.md` in older
   projects); it is not implemented in this PR.
7. **Diagnosis** (changing nothing): if the app sends emails and there is no decision about
   the sending provider (`grep -rli "smtp\|brevo\|resend" context/decisions/`), ask which it
   is and record it. With Firebase Auth, an action for César: check whether the console lets
   him edit the templates. If the site is on Vercel without `.vercel/project.json`, an
   action: `reference/DEPLOY.md` § 2b.

---

## 3.6.0 — 2026-10-16 · `kit-update` and `kit-feedback` skills

**What changed**

- **`kit-update`** replaces `prompts/ACTUALIZAR-KIT.md` (which stays as a notice). It
  compares three versions: the project's (`.kit-version`), the installed skills' and the
  published one (`origin/main` of the kit's clone, after `git fetch`). If they match, it says
  it is up to date and finishes; if the installed skills are old, it reinstalls them and
  asks for a new session (before, migrations ran with the old skills loaded); if the project
  is behind, it applies the path as the prompt did. It always reads the kit as it is on
  `origin/main`, even if the clone is on another branch. Why: the prompt asked to copy the
  skills by hand, change the path in the block and paste it, and did not say whether the
  project was already up to date.
- **`kit-feedback`** sends `context/KIT_FEEDBACK.md` as a PR on the kit's repo
  (`feedback/<date>-<project>.md`, `kit-feedback` label) with `gh api`, without cloning. In
  the kit, "revisa el feedback" runs a consolidated triage of every open PR (see the kit's
  `CLAUDE.md`). Why: reports pasted into the chat arrived one at a time and got lost; what
  repeated across projects was not visible.
- **The installer** writes `~/.claude/web-agent-kit.json` (clone path and installed
  version), which is what `kit-update` reads.

**Steps for a project on 3.5.0**

1. Global pieces: `powershell -ExecutionPolicy Bypass -File <kit>\install-kit.ps1 -Pull` and
   a new session (new skills, and the installer leaves `web-agent-kit.json`). If `kit-update`
   runs the update, this step is already done.
2. The project's `CLAUDE.md`, from `<kit>\CLAUDE.md.template`: the **Kit:** line (updated
   with `/kit-update`) and the last sentence of the kit feedback section (sent with
   `/kit-feedback`). They replace the previous ones; the size does not change.
3. `context/KIT_FEEDBACK.md` (local): the "Informe para el kit" section is replaced by the
   template's "Sending it to the kit" section, and the bold sentence of "If a row for the
   same problem already exists…". Rows marked `→ informe <date>` count as sent.
4. `phases/09-QA-FINAL.md`, if it exists and phase 09 is not closed: the "Kit feedback"
   checkbox of `<kit>\phases-templates\09-QA-FINAL.md`.

---

## 3.5.0 — 2026-10-02 · Email templates in the design

**What changed**

- **The emails the app sends are designed with the site.** The kickoff deduces the list
  (confirm account, recover password, transactional, form acknowledgment and notice…) and
  closes it in the plan (6e) and in `PROJECT_CONTEXT.md` § "Emails"; the brief asks for it
  in §7 with the medium's constraints (600 px, fallback typography, blocked images, forced
  dark mode) and the handoff returns it in § 5c. Why: without a design, the backend sent the
  provider's default template (not in the site's language, no brand) or invented one in
  phase 07.
- **Implementation in phase 07** (`backend-build`): a shared base template, React Email for
  the app's emails (HTML + plain text), and the auth ones in `supabase/templates/` +
  `config.toml`, so the local database sends them with the real design to Mailpit. Guide:
  `reference/EMAIL-TEMPLATES.md`.
- The addendum for Claude Design has an emails block.

**Steps for a project on 3.4.0**

1. Global pieces: `powershell -ExecutionPolicy Bypass -File <kit>\install-kit.ps1` and a new
   session (`project-kickoff` and `backend-build` changed).
2. **Diagnosis** (changing nothing): which emails the app already sends
   (`grep -rniE "resend|sendmail|nodemailer|postmark|emails\.send|resetPasswordForEmail|signUp|signInWithOtp|inviteUserByEmail" --include=*.ts --include=*.tsx app src lib`),
   whether `emails/` and `supabase/templates/` exist, and whether `design/HANDOFF.md` has
   emails. If the app sends none and will not, `PROJECT_CONTEXT.md` § "Emails" = "Does not
   apply" and it ends here.
3. `context/PROJECT_CONTEXT.md`: the "Emails" section of
   `<kit>\context-templates\PROJECT_CONTEXT.md`, filled with the diagnosis (and the "Emails
   the app sends" checkbox under "Functionality").
4. **What is missing from the design is not implemented in this PR.** César gets the
   "Email templates" block of `<kit>\prompts\CLAUDE-DESIGN-ADDENDUM.template.md`, filled with
   the list, and the emails go to the backlog as phase 07 units (the base template + auth
   first).
5. If the project is in phase 07 or past it, those units follow
   `reference/EMAIL-TEMPLATES.md` when the design comes back. Missing copy: rows in
   `CONTENT_CHECKLIST.md`.

---

## 3.4.0 — 2026-10-02 · Wave QA against a local database, phases in waves, one wave per session

**What changed**

- **New `wave-qa` agent.** When all of a wave's PRs are merged, `orchestrate` launches it in
  a pool slot on `main`: it starts the server, walks the wave's flows (and the seams between
  PRs) logged in, per role, and returns reproducible findings. Critical and high move to the
  next wave. Why: each worker tested its unit as a guest and on its branch; nobody tested
  the units together or with login.
- **QA against a local database.** `scripts/qa-local.ts` (`bun run qa:local -- --port <p>`)
  starts Supabase in Docker, applies migrations + seed, creates the test accounts and starts
  the server with the Supabase variables pointing at the local stack (through
  `process.env`, without writing files). It aborts if any variable still points at
  `*.supabase.co`. Why: testing with real data against the production database risks
  clients' data; locally QA can create and break whatever it wants.
- **Test accounts** in `.env.test.local`, one pair per role: `EMAIL_TEST`/`PASSWORD_TEST`,
  `ADMIN_EMAIL_TEST`/`ADMIN_PASSWORD_TEST`, `<ROLE>_EMAIL_TEST`/`<ROLE>_PASSWORD_TEST`. They
  only exist in the local database (the script creates them on every run); the values do
  not go through the agent's context (`node --env-file=.env.test.local`). Only an external
  service without a local equivalent is tested remotely, with data marked, logged and
  deleted. `functional-qa` follows the same rules and now starts its own server.
- **`backend-build`**: the whole schema as migrations in `supabase/migrations/`, a minimal
  `seed.sql`, and the test accounts as an action for César.
- **Phases in waves, one wave per session.** `orchestrate` can split a phase into waves
  (`context/plans/phase-0N-<name>.md`, template `phase-plan-template.md`). Each wave closes
  with: phase, wave closed, the QA result, what comes next; and with "start the wave in
  another session" it opens a new session with the start prompt (or gives it to paste).
  Why: a session that chains waves drags every wave's mapping and reports on each message.
- **The installer** (`install-kit.ps1` / `.sh`): installs or reinstalls skills and agents
  (`-Pull` / `--pull` runs `git pull` first).

**Steps for a project on 3.3.0**

1. Global pieces: `powershell -ExecutionPolicy Bypass -File <kit>\install-kit.ps1` and a new
   session, or `wave-qa` does not exist ("Agent type not found").
2. `scripts/qa-local.ts` from `<kit>\reference\scripts\`, and in `package.json` the script
   `"qa:local": "node scripts/qa-local.ts"`.
3. `.gitignore`: check it covers `.env.test.local` (`git check-ignore .env.test.local`); if
   not, add `.env*.local`.
4. The project's `CLAUDE.md`, from `<kit>\CLAUDE.md.template`: the "Dev server" paragraph,
   the "QA against a local database" one below it, and the `orchestrate` and `wave-qa` rows
   of "Quality gates". Cap 8 KB.
5. `context/CURRENT_PHASE.md`: the **Wave** line under "Phase" (or nothing if waves are not
   used).
6. **If the project uses Supabase:** that `supabase/config.toml` exists and the migrations
   reproduce the production schema. If the schema was made in the dashboard, pull it with
   `supabase db pull` (linked project) into a migration, and a minimal `supabase/seed.sql`
   without personal data. Adapt in `scripts/qa-local.ts` the env map (if the app uses
   variables with other names) and the role assignment (if the role does not live in
   `app_metadata.role`). Check with `bun run qa:local -- --port 4399` (Docker Desktop
   running): it starts and the site loads.
7. **If the project has login:** in `.env.example`, under `# QA → .env.test.local`, the
   empty `*_EMAIL_TEST` / `*_PASSWORD_TEST` pairs, one per role existing in the code (find
   them: `grep -rniE "role|rol|isAdmin" --include=*.ts --include=*.tsx src app lib`).
   **Action for César** in the PR: fill `.env.test.local` (made-up values: they only exist in
   the local database).
8. If there is a batch in progress, it finishes with the old flow; the next one already
   closes with `wave-qa`.

---

## 3.3.0 — 2026-10-01 · States, brand assets, repo and deployment, feedback

**What changed**

- **Status screens** as part of the design and of phase 06: 404 (logged in / guest, only if
  there is auth), 500 (with / without a code), offline, error by network, maintenance (with
  / without a time). Guide: `reference/STATUS-SCREENS.md`.
- **Text selection color** (`::selection`) as a token, with verified contrast, in light and
  dark. Phase 02.
- **Brand assets**: the kickoff asks what the client has (logo, icon, favicon, touch icon,
  OG) and what has to be created. Guide: `reference/BRAND-ASSETS.md`.
- **GitHub repo and Vercel deployment**: the kickoff asks whether they get created, and with
  the yes the agent creates and configures them (including the settings that used to be
  manual actions). Guide: `reference/DEPLOY.md`.
- **Kit feedback**: `context/KIT_FEEDBACK.md` logs corrections, repetitions, gaps and
  friction; on request, a report comes out for the kit.
- **Versioning**: `.kit-version` in each project, this file and the update path.

**Steps for a project on 3.2.0**

1. **Diagnosis** (changing nothing), in a table:
   - status screens: whether `app/**/not-found.tsx`, `error.tsx`, `global-error.tsx`, a
     maintenance page, offline handling and a status gallery exist; whether the site has auth;
   - `::selection` in the global styles (`grep -rn "::selection\|selection:" app/ styles/ src/`);
   - assets: `app/favicon.ico`, `icon.*`, `apple-icon.*`, `manifest.*`, `opengraph-image.*`,
     and whether there is a source logo/icon in `public/` or `design/`;
   - GitHub remote (`git remote -v`), repo settings
     (`gh api repos/<owner>/<repo> -q .delete_branch_on_merge`), and the Vercel link
     (`.vercel/project.json`).
2. **Kit files** (without overwriting what belongs to the project):
   - `.kit-version` with `3.3.0` (`kit-update` writes it when closing each version).
   - `context/KIT_FEEDBACK.md` from `<kit>\context-templates\KIT_FEEDBACK.md`, local like the
     rest of the non-fixed `context/` (add it to `.gitignore` if the project ignores
     `CURRENT_PHASE.md`).
   - `CLAUDE.md`: the **Kit** line of the header and the feedback rule, copied from
     `<kit>\CLAUDE.md.template`. Cap 8 KB.
   - `context/PROJECT_CONTEXT.md`: the template's "Brand assets" and "Repo and deployment"
     sections, filled with the diagnosis.
   - `context/COLORS.md`: `selection` rows in light and dark (empty if there is no value yet).
3. **Questions for César** (one round, `AskUserQuestion`): for each missing asset, does the
   client have it or does it have to be created?; if there is no remote, is the repo
   created?; if there is no Vercel, is it deployed? With the yes, run `reference/DEPLOY.md`
   (outside this PR if the repo does not exist yet: first it is created and `main` pushed,
   then the PR goes).
4. **What is missing from the design is not implemented in this PR.** It goes to the backlog
   as units (one per missing status screen, selection, assets), and César gets the text for
   Claude Design with `<kit>\prompts\CLAUDE-DESIGN-ADDENDUM.template.md`, filled with only what
   is missing.
5. Missing content (the screens' copy, the client's logo/icon): rows in `CONTENT_CHECKLIST.md`.

---

## 3.2.0 — 2026-09-28 · Decisions per file and CI on the version PR

**What changed:** `context/DECISIONS_INDEX.md` disappears; each decision is
`context/decisions/D0NN-<topic>.md` and its first line is the index row. `release.yml`
triggers `ci.yml` (with `workflow_dispatch`) on the version PR.

**Steps for a project on 3.1.0:** the block of
[`prompts/MIGRATE-3.2-DECISIONS-CI.md`](./prompts/MIGRATE-3.2-DECISIONS-CI.md), steps 1 and 3
to 6 (`kit-update` does the branch, the verification and the closing; the "manual actions"
of its step 8 go to the PR). Without Changesets, only the decisions part.

---

## 3.1.0 — 2026-09-26 · Worktree pool and versioning with Changesets

**What changed:** `orchestrate` uses a fixed pool of worktrees (`wt.ps1`) instead of creating
and deleting one per unit. Version and CHANGELOG with Changesets: each PR brings its
`.changeset/*.md` and an Action keeps the version PR.

**Steps for a project on 3.0.0:** the block of
[`prompts/MIGRATE-3.1-WORKTREES-CHANGESETS.md`](./prompts/MIGRATE-3.1-WORKTREES-CHANGESETS.md),
steps 1, 3, 4, 5 and 8 (`kit-update` does the branch, the verification and the closing; the
"manual actions" of its step 7 go to the PR).

---

## 3.0.0 — 2026-09-24 · v3 base (learned on World Flags)

Reading by levels, `CURRENT_PHASE.md` with a cap and `PHASE_LOG/`, `pr` mode, `orchestrate` +
`feature-worker`, `test:related`, screenshots in the PR. See "What changed in v3" in the README.

---

## When publishing a new kit version (for whoever maintains the kit)

1. Bump [`VERSION`](./VERSION) (semver: **minor** if a project needs migration steps or there
   are new pieces; **patch** if only texts or script bugs get fixed with no change in the
   projects; **major** if it breaks the flow and the migration is not automatic).
2. Add the entry **at the top** of this list: what changed and **the steps for a project on
   the previous version**, self-contained (the migrating agent only reads this and what is
   cited).
3. If the new version adds a detectable signal, add it to the deduction table (not dependent
   on Changesets: there are projects without versioning).
4. **The project's `CLAUDE.md` does not grow without a cap.** A step that adds text to it
   says which old paragraph it replaces; if it is truly new, it is one line that cites the
   detail in the kit. Two projects had to trim their own rules by hand after adding up
   versions (8.8 KB and 8.1 KB).
5. If a step edits a `context/` file a project may not have (it started short), it says what
   to do if it is missing (usually: create it with only the step's sections).
6. Steps are written for both kinds of project: new ones (English `context/`) and those
   created before 3.8.0 (Spanish `context/`, left as they are).
