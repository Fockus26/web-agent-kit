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
| is a WordPress with `scripts/pull-site.sh` | **3.19.0** |
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

## 3.21.0 — 2026-11-08 · KREA's first report: prompts checked, Cache Components, build in CI

KREA's report on kit 3.14.0 (feedback PR #25), merged without triage at the time and
processed now; what 3.20.0 had already covered is left out. Decisions by César, 2026-11-08.

**What changed**

- **`orchestrate`:** everything the prompt cites is checked first (it exists, counts and
  texts copied from the canvas, demo data that match, the API of components the unit may not
  edit, a11y traps at the same breakpoint), and what was already verified is stated once;
  the tests that watch the unit's files and all the state combinations go in the prompt;
  the heading levels in the unit prompt; "Missing tokens" in the report and one PR at the
  wave's close; one more decision ID for the phase's closing; `QA: al final` in the
  project's `CLAUDE.md` skips `wave-qa` and the workers' server in every wave.
- **Brief:** Read before Edit (`cat` does not count); `sed` only over the unit's file list;
  `git diff --cached --stat` before each commit; the build only when the unit touches the
  build setup.
- **`git-flow` §2.1 gate 3: the build runs in CI**, not locally per unit (109–309 s locally
  against 44 s in CI), plus opening the deploy preview once. A project without CI keeps it.
- **`STACK-NEXTJS.md`:** Cache Components (`generateStaticParams` with one real param,
  `[state]` instead of `?state=`, fonts in `opengraph-image`, a `loading.tsx` test and a
  console-error pass), `server-only` vs `bun test`, custom utilities in `extendTailwindMerge`.
- `UI-LIBRARIES.md`: `shadcn init` over own tokens. `seo`: a page's `openGraph` replaces the
  layout's — spread a shared base. `STATUS-SCREENS.md`: 200 under `loading.tsx` is expected.
- **`QA-PREVENTION.md`:** fields validated apart before joining, forms before hydration,
  "no network" vs "the service failed", 200 % text at 390 px, `scroll-padding` for fixed bars,
  `forced-colors` for the selected state and masked drawings.
- **`a11y`:** live regions for changes of state, not progress values; axe without a server
  over the build's HTML. **`design-qa.ts`:** browser font through CDP (it failed on Windows
  with the profile), and also 200 % at 390. `design-qa` and `functional-qa` write their
  report as they go; Server Action ids read from the manifest on every run.
- **`cloud-session`:** after a squash with the remote branch alive, merge its old tip and a
  normal push, never force; Chromium in `/opt/pw-browsers` via `executablePath`.
- **`qa-local.ts` (Firebase):** `NO_UPDATE_NOTIFIER=1`, one retry when the CLI exits on a
  cold start, a message with the real cause. `tech/firebase.md`: `firebase-tools` pinned.
- **`backend-build`:** the agent writes `.env.test.local` itself; César is never asked to
  log in for QA. `CURRENT_PHASE` template: check an install before repeating it.
- **`new-project.ps1`:** `.gitattributes` with `* text=auto eol=lf` (with `autocrlf=true`,
  Biome failed locally while CI passed).

**Steps for a project on 3.20.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session).
   Then refresh the kit copy (`install-kit --project .`) and commit it.
2. `new-project.ps1 -Path . -OnlyPieces`: it sets `* text=auto eol=lf` in `.gitattributes`
   (left alone if a global rule already forces LF). Commit it, and then, **on a clean tree**,
   rewrite the working copy: `git rm -rq --cached . && git reset -q --hard`. Check: `git
   ls-files --eol | grep -c "w/crlf"` gives 0.
3. Replace `scripts/qa-local.ts` with the kit's (LF and the project's Biome; `kit-update` ›
   Piece check). A Firebase project adds `firebase-tools` as a pinned devDependency if it
   is not there.
4. `CLAUDE.md`, the **QA:** line: after "with the `.env.test.local` accounts" add "(you write
   it; never ask César to log in for QA)". If the line is not there (a trimmed `CLAUDE.md`),
   do not add it: `backend-build` already says it. At 8 KB, shorten the line itself
   (`(--offline: guest only)` can go).
5. If César wants no QA until the end of the project: a line `QA: al final` in `CLAUDE.md`
   (`orchestrate` §8). Only if he says so.
6. Nothing in `context/`.

---

## 3.20.0 — 2026-11-08 · Slot hygiene, emulators in parallel, Better Auth (KREA)

KREA's feedback (kit 3.17.0, three waves of ≈40 PRs in three days, mid-migration from
Firebase to the VPS). Decisions by César, 2026-11-08.

**What changed**

- **`wt take` clears what the previous unit left** when the slot gets a different branch
  (`.qa/.branch` records whose they are): `.qa/pr-body.md`, `progress.md`, `*.log`, and
  `.next/dev`, `.next/types`. The measuring and repro scripts stay. One PR went out with
  another's body and the stale types gave false `typecheck` errors (KREA ×14 and ×5).
- **`orchestrate`:** "Test services yes/no" reserved like Docker (at most one unit per wave
  runs fixed-port emulators; the rest verify through CI); `CONTENT_CHECKLIST` rows reserved
  against the file's real last row, with one spare per unit; the orchestrator checks a shape
  or trap before stating it as exact; the scope of an ambiguous rule is asked in the single
  round; with visual QA suppressed, a new color comes with its contrast pairs in light and
  dark.
- **Brief rules:** Python only with `newline=""`, `sed -i` for mechanical renames, format at
  stage close; `git grep` to search; never `npx biome`.
- **`tech/firebase.md` § Emulators in parallel:** start in the background and wait for the
  ready line, one emulator per run, a port that does not collide with Docker/WSL, a
  `rejects()` helper for the Admin SDK hang, `emulators:stop`.
- **`tech/vps-postgres.md`:** allowlist in `/api/auth/[...all]`; rate limit by account that
  counts only failures, on top of a loose one by IP (a classroom behind a NAT was locked out).
- **`tech/migrate-firebase-vps.md`:** `runTransaction` → `SELECT … FOR UPDATE`; emulator tests
  → PGlite with a `DocumentSnapshot` shim.
- **`qa-local.ts` / `qa-roles.ts`:** `existingAccount` hook (any backend: an account the
  project's seed creates is not created again) and `scripts/seed-db.ts` in the Postgres
  backend (an app with `disableSignUp` has no sign-up route).
- **`new-project.ps1`:** `.claude/kit-reference` (and `.claude/worktrees`) out of `biome.json`
  and `tsconfig.json › exclude`; each `.pr-shots` line of `.gitignore` checked on its own.
- `QA-PREVENTION.md` §3: the proxy only redirects `GET`/`HEAD`. `STACK-NEXTJS.md`: no
  functions as props from a Server Component; stale `.next` types; Biome range suppressions.

**Steps for a project on 3.19.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session).
   Then refresh the kit copy (`install-kit --project .`) and commit it.
2. `new-project.ps1 -Path . -OnlyPieces`: it adds the `biome.json` / `tsconfig.json`
   exclusions and the missing `.gitignore` lines. Check: `bun run lint` and `bun run
   typecheck` do not mention `.claude/kit-reference`; `git check-ignore -q .pr-shots/x`
   passes. (A WordPress project: skipped, it has neither file.)
3. Replace `scripts/qa-local.ts` with the kit's (LF and the project's Biome; `kit-update` ›
   Piece check). `scripts/qa-roles.ts` is **not** replaced: if the project creates test
   accounts in its own seed, add the `existingAccount` function from the kit's
   `qa-roles.ts`. If it had patched `qa-local.ts` to skip them, that patch moves there.
4. A pool already initialized needs nothing: the next `wt take` of each slot clears it.
5. Nothing in `CLAUDE.md` or `context/`.

---

## 3.19.0 — 2026-11-07 · WordPress as an official stack (InspecChile)

InspecChile (cPanel without SSH, deploy by FTPS, ACF Pro and Elementor Pro, adopted on 3.15.0)
was the first WordPress on the kit, and showed it was Next.js-first: the agent translated or
invented almost every step. Decisions by César, 2026-11-07.

**What changed**

- **`tech/wordpress.md` rewritten:** all the code in the site plugin, snippet plugins retired
  with no "one-off" exception; ACF in the plugin's `acf-json/`; two local environments (Docker
  copy from the backup for sites with premium plugins, wp-env for the rest) with versions
  pinned; data changes as **migrations by version** in the plugin (they run with `wp
  <client>-site migrate` over SSH, or on the first wp-admin visit without SSH — the activation
  hook does not fire when a deploy replaces files); §4 extended with `frontend-build`,
  `backend-build`, `git-flow`, CI and **page builders in `a11y`**; deploy **SSH first, then FTPS,
  never plain FTP**, instead of WP Pusher; §6 traps: PHP versions, shared hosting (`zip`
  dropped, `uploads` owned by root), Elementor (cloned popups, `add_error`, CSS after a
  search-replace), email in the copy.
- **`tech/wordpress-adopt.md`** (new): access by host type, the common base with two entries
  (migrate snippets / from scratch), the inventory of what is code in the database, the
  multi-database dump, the full walk-through before the first deploy, and the lines recorded in
  `PROJECT_CONTEXT.md` § Stack.
- **`tech/wordpress/`** (new templates): `pull-site.sh` (ssh, ftps, archive, dbs, import:
  resumable, verified by a dry run, escaped URLs), `php-lint.sh`, `docker-compose.yml` with
  Mailpit, `deploy-ssh.yml`, `deploy-ftps.yml` (upload aside and swap by rename), `ci.yml` (PHP
  matrix and committed compiled CSS), WordPress variants of `CLAUDE.md.template` and the PR
  template, and the site plugin skeleton (`filemtime()` asset versions, `acf-json`, migrations).
- **`new-project.ps1 -Stack wordpress -Client <slug>`:** copies those pieces and none of the
  Next/bun ones (`test:related`, `qa:local`, `@types/bun`, Changesets).
- **`kit-update`:** case e) a WordPress with no kit is an adoption; a WordPress piece check;
  version steps about Next.js, Biome, Changesets, `qa:local` or `test:related` are skipped there.
- **`project-kickoff`** question 13 points WordPress to `-Stack wordpress` and the adoption order.

**Steps for a project on 3.18.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session). Then
   refresh the kit copy (`install-kit --project .`) and commit it.
2. **Not WordPress** (its `CLAUDE.md` has no `wordpress` in `Tech refs`): nothing else.
3. **WordPress project:**
   a. Pieces: `pwsh -File "<kit>/new-project.ps1" -Path . -Stack wordpress -OnlyPieces` (adds
      the scripts, `docker-compose.yml`, `.env.example` and the `.gitignore` lines it lacks;
      overwrites nothing). If `-OnlyPieces` of an earlier version added `test:related`,
      `qa:local`, `scripts/test-related.ts`, `scripts/qa-local.ts`, `scripts/qa-roles.ts` or
      `@types/bun`, propose removing them in the single round (they cannot run in WordPress).
   b. CI: if `.github/workflows/ci.yml` is the kit's bun CI, replace it with
      `<kit>/reference/tech/wordpress/ci.yml` (adjust the PHP matrix); the PR template with
      `<kit>/reference/tech/wordpress/pull_request_template.md`.
   c. Diagnosis for the single round, changing nothing: snippet plugins still active (they are
      retired: a plan of moving them, `wordpress-adopt.md` § 4A), ACF groups outside
      `acf-json/`, assets versioned with the plugin's constant instead of `filemtime()`, data
      fixes in an activation hook or in `bin/` scripts a host without SSH cannot run (they move
      to `migrations/`), a deploy by WP Pusher or plain FTP (it moves to `deploy-ssh.yml` /
      `deploy-ftps.yml`). Each one César accepts goes to `context/plans/backlog.md`
      (`pendientes.md` in older projects) as its own unit, not into this PR.
   d. `context/PROJECT_CONTEXT.md` § Stack (Spanish `context/`: its "Stack"): add the lines of
      `wordpress-adopt.md` § "Recorded in the project" that are missing (access type, PHP,
      premium plugins, deploy). If the section is missing, create it with only those lines.
   e. `CLAUDE.md`: if the project's says Next.js, `bun run typecheck` or `qa:local`, replace those
      lines with the WordPress template's (`<kit>/reference/tech/wordpress/CLAUDE.md.template`,
      § Stack and the commands block), not appended; ≤ 8 KB measured with LF.

---

## 3.18.0 — 2026-11-07 · Clocks and tabs in QA prevention, steps for a missing line

**What changed**

- **`QA-PREVENTION.md` §6 "Clocks, dates and tabs"** and new rows in §3 and §5: one clock per
  measurement, metrics only over the time a timer ran, client dates in the future, `storage`
  writes that are complete states, announcing only changes made here, session changes told to
  the other tabs, a notice that outlives its operation, a count and its action from the same
  data, timeouts in crons, strict date parsing, a service worker that intercepts new routes.
  They are the classes `functional-qa` found in world-flags and no builder had checked.
- **Steps that replace a line the project lacks:** the rule for writing them (end of this
  file) and, for old steps that do not say, what `kit-update` does: add it only if it is not
  there in other words, and propose which line to shorten if it goes over 8 KB. 3.15.0 step 5
  and 3.16.0 step 2 had no answer (world-flags). Size is measured with LF: on Windows the
  working copy counts the CRs.
- **3.16.0 step 4 corrected:** `vps-env.ts` is added if missing, and with real users it is
  run with `<project>_dev`, never the production database (as written, it left world-flags'
  dev on the real database).
- **`kit-update`:** a clone on a branch already merged and clean switches to `main` and
  installs, instead of stopping as if César were editing the kit.
- **`new-project.ps1 -OnlyPieces`:** a `.gitignore` rule `.claude/` is replaced by
  `.claude/worktrees/` + `.claude/settings.local.json`. Appended under it, the kit copy stayed
  out of git (world-flags).
- **`qa-local.ts --preview`** uses the project's `qa:serve` script if it has one, and runs with
  `NODE_ENV=production`: `@astrojs/vercel` has no `astro preview` (`tech/astro.md`).
- **`git-flow` §1.2:** what to do with uncommitted work before opening a unit (InspecChile).
- `kit-db create` with `>/dev/null` in the guides: it prints the URLs with the password.

**Steps for a project on 3.17.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session). Then
   refresh the kit copy (`install-kit --project .`) and commit it.
2. Replace `scripts/qa-local.ts` with the kit's (LF and the project's Biome; `kit-update` ›
   Piece check). An Astro project with `@astrojs/vercel` that wants `--preview` adds its own
   `qa:serve` (`tech/astro.md`); it is not required.
3. If `.gitignore` has a line `.claude/` (all of it): replace it with `.claude/worktrees/` and
   `.claude/settings.local.json`, and `git add .claude/skills .claude/agents
   .claude/kit-reference .claude/settings.json`. Check: `git check-ignore -q .claude/skills`
   fails.
4. Nothing in `CLAUDE.md` or `context/`.

---

## 3.17.0 — 2026-11-04 · Hosting and migrations by case

**What changed**

- **`tech/vercel.md`:** `DEPLOY.md` §2, §2b, §2c and §2d moved with their numbers, plus the trap of
  `vercel link` touching `.gitignore` (world-flags). `DEPLOY.md` keeps GitHub, the questions and the
  post-deploy checks, and a citation of its §2c still leads there.
- **`tech/other-hosting.md`:** a checklist for any other host, asked at kickoff because a plan
  without Node changes the stack. No project has been through it: the first one on a host writes
  `tech/<host>.md`. It also says that César's VPS only serves the database today.
- **`tech/migrate-supabase-vps.md` and `tech/migrate-firebase-vps.md`:** `MIGRATE-TO-VPS.md` split by
  origin, so a project reads only its own (César). The old name forwards.
- **The cutover moved inside the merge:** a draft PR until the cutover, variables and data first,
  merge last. The guide said "after the merge", which gave 500s for about 40 minutes (world-flags
  #133). The old project stays without writes, not paused, while old clients may read from it.

**Steps for a project on 3.16.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session). Then
   refresh the kit copy (`install-kit --project .`) and commit it.
2. The project's `CLAUDE.md`, with no line added: add `vercel` (or `other-hosting`) to its `Tech
   refs`, by the signals in `reference/tech/README.md`.
3. Replace `scripts/cloud-setup.sh` with the kit's (only a comment changed; skip it if the project
   changed that file). Nothing else.

---

## 3.16.0 — 2026-11-04 · Technology references, a project can start on the VPS, VPS fixes

**What changed**

- **`reference/tech/`: one file per technology** (`astro`, `supabase`, `firebase`,
  `vps-postgres`, `wordpress`), and a `Tech refs` line in the project's `CLAUDE.md` naming its
  own. What only applied with one technology was spread through skills and guides every project
  reads (César). This round moves `STACK-NEXTJS`'s Astro section and `backend-build`'s
  Supabase and Firebase blocks; short mentions remain in the QA agents. `STACK-WORDPRESS.md`
  forwards to `tech/wordpress.md`.
- **The VPS Postgres is a kickoff option** (`tech/vps-postgres.md`): you develop against it as
  with Supabase. It was only a migration for finished projects (César; also world-flags'
  feedback). `MIGRATE-TO-VPS.md` stays for projects already in production.
- **`qa-local.ts`: Postgres backend** from world-flags (Postgres + Mailpit in Docker, a database
  per port, `--postgres`, `--db-only`). It aborts if a variable it does not override points at
  the VPS, also without `drizzle.config.*`: before this, a project on the VPS started the normal
  server with the real URL. `warmUp` also looks at `[::1]` (Astro 7 waited 10 minutes), and a
  failure creating accounts ends with a message instead of an orphaned server.
- **`vps-env.ts` writes `.env.development.local`**, not `.env.local`, which `vercel env pull`
  overwrites. Previews get their own database (`<project>_preview`): with the same URL, a PR's
  preview wrote real data (world-flags).
- **`kit-db`** (tested in Docker, 2026-11-04): a failed upload stopped the whole nightly run and
  later databases got no backup; `rclone` missing with a remote set passed in silence; a failed
  final backup did not stop `drop`; a failed `create` left a role that blocked every retry. New
  `kit-db status`, the only place a failure shows.
- **`bootstrap.sh`:** `--harden-ssh` wrote `60-kit.conf`, which loses to cloud images'
  `50-cloud-init.conf`: password login stayed on while it said "off" (César's VPS). Now
  `00-kit.conf`, and it reports what `sshd -T` says. Project roles can no longer enter `postgres`
  or `template1` (a session there blocked `CREATE DATABASE`). A re-run without `--domain` keeps
  the domain instead of dropping every new URL to `sslmode=no-verify`.
- `MIGRATE-TO-VPS.md`: Better Auth's CLI is `auth@latest` now (`@better-auth/cli` is being
  deprecated); a timer on the VPS instead of Vercel Cron.

**Steps for a project on 3.15.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session). Then
   refresh the kit copy (`install-kit --project .`) and commit it.
2. The project's `CLAUDE.md`, with no line added: replace the line ``The kit's `reference/…` =
   `~/.claude/kit-reference/…` (or `.claude/kit-reference/…`).`` (or its Spanish equivalent) with
   the two of `CLAUDE.md.template` (What to read). Fill `Tech refs` with the table's signals in
   `reference/tech/README.md`. If the project is at its cap, shorten a project line and say which.
3. Replace `scripts/qa-local.ts` with the kit's (LF and the project's Biome; `kit-update` ›
   Piece check). In `scripts/qa-roles.ts`, nothing is required. A project on the VPS copies the
   kit's `assignRolePostgres` there, if it has none. Check: `bun run qa:local -- --port <p>
   --offline` ends with `QA ready: http://localhost:<p>`.
4. Only a project on the VPS:
   - Replace `scripts/vps-env.ts` (add it, with its `vps:env` script, if the project migrated
     before it existed) and run it with the database of `tech/vps-postgres.md` › Environments:
     **with real users, `<project>_dev`**, never `<project>` (that one is production). If
     `_dev` does not exist yet, it is an action for César (`kit-db create <project>_dev
     >/dev/null` and a copy without personal data); ask before running it. Then delete
     `DATABASE_URL` and `DIRECT_URL` from `.env.local` if they were written there by hand.
     (Fixed in 3.18.0: run as written, it left world-flags' dev on the real database.)
   - `drizzle.config.ts` as in `tech/vps-postgres.md`, if `bun run db:generate` needs a database.
   - **Action for César:** `<project>_preview`, its migrations, and its URL in Vercel's Preview.
5. Nothing else. A project on Supabase or Firebase does not move.

**Steps for César's VPS (once, not per project)**

From the kit's folder: `scp -r reference/vps kit-vps:/root/kit-vps`, then `ssh kit-vps "bash
/root/kit-vps/bootstrap.sh --harden-ssh"`. It keeps the domain and every database. Check:
`ssh kit-vps "sshd -T | grep -i ^passwordauthentication"` says `no`, and `ssh kit-vps kit-db
status`.

---

## 3.15.0 — 2026-10-30 · Solved patterns, VPS Postgres, WordPress, payment methods, melao's feedback

**What changed**

- **`reference/PATTERNS.md` + the `patterns/` registry.** The pieces every site repeats,
  built once: the logic fixed, the design the project's. Registry items (installed with
  `bunx shadcn@latest add <kit>/patterns/r/<item>.json`, path relative to the project):
  `kit-fields` (Zod fields with the QA-PREVENTION rules), `kit-form` (`useKitForm`: validate
  on submit, or live with a delay before errors show), `kit-submit-guard` (no double
  submit, one idempotency key per operation). Recipes: fluid headings with `clamp()`, the
  four list states, the auth criteria checklist. `frontend-build` starts from them. Why:
  each project rebuilt them slightly differently and QA found the same gaps (César).
- **César's VPS as a central Postgres, for finished projects only.**
  `reference/VPS-POSTGRES.md` (the server: Postgres on localhost + PgBouncer with TLS,
  `kit-db` per project, daily backups + rclone, SSH key so nothing is typed),
  `reference/vps/bootstrap.sh` + `kit-db`, `reference/scripts/vps-env.ts`, and
  `reference/MIGRATE-TO-VPS.md` (Supabase/Firebase → Drizzle + Better Auth + the app's own
  emails, cutover, 30-day rollback). Projects are still created on Supabase or Firebase:
  the move is César's decision at the end.
- **`EMAIL-TEMPLATES.md` § Better Auth**: after the move every email is the app's, sent
  through Brevo's SMTP (free) with nodemailer, Mailpit in QA. Why not an SMTP server on
  the VPS: a new IP has no reputation and lands in spam, and port 25 is often blocked.
- **`reference/STACK-WORDPRESS.md`**: code in a site plugin + child theme in git (not in
  WPCodeBox snippets), local copy with wp-env, the kit's rules translated (nonces,
  capabilities, sanitize/escape), staging before production. `project-kickoff` offers it.
- **`reference/PAYMENTS.md`**: Cashea, PayPal, Bancolombia, Binance Pay and Pago Móvil —
  what the client provides, costs, sandbox and how each integrates. The kickoff asks the
  client for the documents in phase 00 (approvals take weeks); `backend-build` cites it.
- **Global CLIs by name** (`vercel`, `supabase`, `gh`), never through `bunx`: it downloads
  another copy instead of using the one with the session. `bunx` stays for one-offs and the
  project's own tools (César fixed `bunx` on the PATH of pwsh and the slots' Git Bash).
- **VPS bootstrap tested in Docker** (Postgres 17 image, `--test`): create, duplicate and bad
  names refused, TLS, isolation between databases, `postgres` and non-TLS refused, backup /
  restore, rotate, `backup --all`, drop. Two fixes from it: `cron` is installed (minimal
  images lack it), and PgBouncer's auth role goes in its userlist in clear (with its SCRAM
  secret it could not log in to Postgres: "wrong password type").

**melao's feedback (kit 3.13.0, 2026-10-29)**

- **`qa:local`:** Auth's `site_url` and redirect URLs set to `http://localhost:<port>` and
  `<prefix>SITE_URL` / `BETTER_AUTH_URL` injected, so email links come back to the QA server
  (×5); a stack running for another port is restarted keeping its data; `supabase start` up to
  3 times with `stop` between and the db container's log at the end, `db reset` retried once
  after stop + start (×3); a warning if `config.toml` turns `enable_confirmations` or
  `double_confirm_changes` off; `/` and `--warm` routes warmed, then the line `QA ready: …`
  to wait for (first `GET /` took 178 s). The role logic moves to **`scripts/qa-roles.ts`**,
  copied once and never replaced (it was re-ported by hand twice).
- **`pr-screenshots.ts`:** `route` per state (faked responses instead of patching `fetch`),
  3 attempts, paths warmed first, a warning if `.pr-shots.json` predates the branch's last
  commit. **`publish-pr-shots.sh`:** its worktree inside `.git` (with `MSYS_NO_PATHCONV=1`
  git could not resolve `/tmp`) and the push retried when two publishes collide.
- **`scripts/run-on-main.sh`** (new): runs a repro on a temporary worktree of `origin/main`,
  for the FAIL half of FAIL → PASS without patching the slot.
- **`orchestrate`:** brief with the absolute `context/` path, the test runner, "Shared shapes",
  closed number ranges and error codes per unit, checklist rows only for units with copy,
  log in `.qa/dev.log`, wait for a log line (no `pgrep`), check the port after stopping,
  Playwright guards on the production build, `MSYS_NO_PATHCONV=1`, load-only test timeouts,
  shared media fixtures, `wip` commits + `.qa/progress.md`, `shots` and `shots:publish`
  apart, missing tools skipped and said. The skill: read the generated CSS for token
  changes, PGlite vs the Supabase client, tokens for handoff values decided in the prompt,
  Docker FAIL → PASS after `wave-qa`, the measured guard decides over the grep.
- **The kit's `reference/` is installed** (`install-kit` → `~/.claude/kit-reference/`, and
  `.claude/kit-reference/` in the project copy). The skills cited it and a project could not
  open it (models assigned by eye). `CLAUDE.md.template` says where it is.
- **`CLAUDE.md.template` ≤ 7 KB** (it was 8.35 KB, over its own 8 KB): 1 KB left for the
  project's lines. From now on a version step that adds a line to the project's `CLAUDE.md`
  says which line it replaces or shortens (each version since 3.3.0 only added).
- **`new-project.ps1`** writes what it copies with LF and formats it with the project's
  Biome; `kit-update` does the same for scripts it replaces.
- **QA agents:** `wave-qa` waits for `QA ready`, uses `localhost`, creates accounts through the
  admin API, knows `kong:8000` signed URLs are a local artifact and the Playwright traps
  (`aria-disabled` needs `force`, `textContent` includes hidden text); `functional-qa` the
  same traps; `design-qa` measures with the browser font at 150 % (`browserWithFont`, full
  Chromium; reported as not run if it cannot start).
- **`QA-PREVENTION.md`:** `relative overflow-x-auto` for scroll containers, `grid-cols-1` +
  `min-w-0` for grid columns. **`a11y`:** Lighthouse skipped (and said) when not installed.
- Specific to melao and left there: the audio generator (only the rule "shared fixture"
  came in), `tokens.test.ts` itself.

**Steps for a project on 3.14.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session).
   Then refresh the kit copy (`install-kit --project .`): skills, agents and the new
   `.claude/kit-reference/` — commit the three.
2. `scripts/qa-roles.ts`: if missing, copy `<kit>/reference/scripts/qa-roles.ts`. If the
   project's `qa-local.ts` has its own `assignRole`, `assignRoleFirebase`, `ROLE_BY_ENV` or
   extra `ENV_MAP` entries, move their bodies into `qa-roles.ts` (same names; extra map
   entries → `EXTRA_ENV_MAP`).
3. Replace `scripts/qa-local.ts`, `scripts/pr-screenshots.ts` and
   `scripts/publish-pr-shots.sh` with the kit's, and add `scripts/run-on-main.sh`; LF and the
   project's Biome on them (`kit-update` › Piece check). Check: `bun run qa:local -- --port
   <p> --offline` ends with `QA ready: http://localhost:<p>`.
4. `.gitignore`: if a root-level `*.log` from QA (`.qa-dev.log`) is there, delete it; logs go
   to `.qa/`.
5. The project's `CLAUDE.md`, with no line added (rule above): replace the line `Size
   budgets: the kit's reference/TOKEN-ECONOMY.md.` (or its Spanish equivalent) with
   ``The kit's `reference/…` = `~/.claude/kit-reference/…` (or `.claude/kit-reference/…`).``
   If it has `bun x`, it may stay: same command.
6. `scripts/cloud-setup.sh`: nothing (it was 3.15.0's draft; the kit's copy is the same).
7. Nothing else. The patterns apply from the next form or list built; the VPS migration
   only when César asks for it; WordPress and payments are read at the next kickoff.

---

## 3.14.0 — 2026-10-23 · QA at the end of the version, prevention while building, model per task, widget motion

**What changed**

- **Model and effort for any task**, not only `orchestrate`'s workers
  (`reference/TOKEN-ECONOMY.md` §12): every subagent carries `model`/`effort` from the
  table, and the main session opens each task with `Modelo recomendado: <model · effort>`
  so César switches with `/model` / `/effort` when it differs. Why: the main session and
  the QA launched from `git-flow` 5b ran on the big model at high effort whatever the task.
- **`design-qa` only at the version QA.** Phase 09 is now the version QA: `design-qa` over
  every route + `functional-qa` over every flow, report in
  `context/plans/qa-version-<version>.md` with the sha; later versions run it before César
  merges the `chore(release)` PR, scoped by `git diff` since that sha. During development:
  `git-flow` 5b and `cloud-session` launch `functional-qa` **only on risk flows** (auth,
  saved data, payments), no `design-qa` per page; `orchestrate` §8 skips `wave-qa` for a
  wave with no risk flow. Phase 09's fixes close with their reproduction scripts, not with
  a second QA. Why: per-page and per-wave audits were most of the QA tokens, and their
  visual findings were classes one sweep fixes at once (César, 2026-10-23). The risk-flow
  QA stays because of inversiones-js #19 (three High data-loss findings weeks later).
- **`reference/QA-PREVENTION.md`**: the defect classes QA keeps finding (spaces as content,
  2-digit years, double submit, concurrent overwrite, reflow, widgets without transition),
  each with the rule that prevents it while building. `backend-build` (trim in every Zod
  text field), `frontend-build` (submitting forms) and the brief (rule 16) cite it. The
  three QA agents add a `Prevención` row to their "Feedback para el kit" for a class not in
  the list, and `KIT_FEEDBACK.md` has a new **Prevention** type, so the list grows from the
  feedback.
- **Motion in interactive widgets** (`frontend-build`, phases 02 and 03, the Claude Design
  brief and handoff §6, `design-qa` §4, `a11y`): accordions animate their height with the
  library's variable (or `grid-template-rows` 0fr → 1fr), tabs and nav links slide their
  indicator, overlays fade in and out, anchor links scroll with `motion-safe:scroll-smooth`
  and land under the sticky header with `scroll-margin-top`; everything off under
  `prefers-reduced-motion`. `design-qa` measures the transition durations.
- `CLAUDE.md.template`: one "Model per task" line, the QA gates table (three rows), and a
  shorter header box and comments so it stays ≤ 8 KB.

**Steps for a project on 3.13.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session).
   Then refresh the kit copy (`install-kit --project .`): skills and agents changed.
2. `CLAUDE.md`, after the "**Documentation:** Context7…" line, add (Spanish projects: the
   same in Spanish):

   ```
   **Model per task:** before each, `Modelo recomendado: <model · effort>` (kit
   `TOKEN-ECONOMY.md` §12; risk → `opus`); subagents get both in `Agent(...)`.
   ```
3. `CLAUDE.md`, "Quality gates" table: replace the `wave-qa` and `design-qa / functional-qa`
   rows with the template's three (`wave-qa` · `functional-qa` · `design-qa`). Spanish
   projects: same rows in Spanish. Then `wc -c CLAUDE.md`: if it is over 8 KB, shorten the
   comments of the commands block as the template did, never the rules.
4. `context/KIT_FEEDBACK.md` (or `KIT_FEEDBACK.md` in Spanish): add the **Prevention** row
   to the types table (Spanish: **Prevención**). Missing file: nothing to do.
5. `context/CURRENT_PHASE.md` "Blocked": `QA pendiente: design-qa — …` lines are removed
   (they go to the version QA); `QA pendiente: functional-qa — …` lines stay only if the
   flow is a risk one.
6. If the project already delivered a version and has no `context/plans/qa-version-*.md`:
   nothing to migrate; the next version QA runs over everything and leaves the first one.
7. A project whose phase 09 is already closed: nothing; a project past phase 03 with
   accordions, tabs or anchor links without transitions: a row in `plans/backlog.md`
   (`Movimiento en widgets — frontend-build › Motion in interactive widgets`), not a
   migration commit.

---

## 3.13.0 — 2026-10-22 · Feedback round 3 (inversiones-js, world-flags): QA without loops, Firebase and Astro

**What changed**

- **QA findings are fixed in the same wave and closed by a script, not by another QA.**
  `wave-qa`, `design-qa` and `functional-qa` leave a reproduction script per finding
  (`.qa/repro/<n>-<slug>.mjs`, prints `PASS`/`FAIL`); `orchestrate` §8 turns Critical/High
  into fix units **of this wave**, whose worker runs the script on `main` (FAIL) and on its
  branch (PASS). No second QA of the fixes. A finding that is a **class** is swept whole
  (`grep` pattern + measuring script versioned in the repo). Why: in world-flags each QA
  opened a wave, each fix got a QA that found more of the same reflow class: four rounds.
- **QA scope from `git diff`**: `orchestrate` §8 passes `wave-qa` the files changed since
  the last QA's sha; it walks those flows, the never-verified ones and a smoke pass. Why:
  three QAs re-walked flows whose files had not changed.
- **Model and effort per unit** (`reference/TOKEN-ECONOMY.md` §12, a 3-row table; risk —
  auth, data, concurrency — is always `opus`); `orchestrate` §4 reserves it with "Docker
  yes/no", and passes both in `Agent(...)`. Why: mechanical units spent 100-280 k tokens on
  the big model.
- **Brief**: a "Simulating the backend" section (shared mock script, exact build command);
  rule 16 "fix the class in the first pass" (and after that, Medium/Low → backlog, at most
  one extra round per PR); Astro ≥ 7 server rule; `gh pr create --body-file`.
- **Closing QA outside waves** (`git-flow` §2.1 gate 5b, `cloud-session` §2): a unit that
  completes a flow gets `functional-qa`, a page `design-qa`, or a `QA pendiente: …` line in
  "Blocked". Why: six cloud PRs in inversiones-js merged with no QA; three High data-loss
  findings came out weeks later.
- **`qa-local.ts`**: **Firebase emulators** when the project has `firebase.json` with
  `emulators` (`demo-*` project, 4-minute wait with progress, accounts with a `role` custom
  claim, `scripts/seed-emulator.ts`, `<prefix>USE_EMULATORS=true`); **Astro ≥ 7** server kept
  in the foreground (`ASTRO_*_BACKGROUND=0`) and `astro dev stop` on exit; `supabase start`
  retried once; `db reset` output live; email rate limit raised locally; new `--preview`
  (build + preview/start). Why: inversiones-js ran its own Firebase copy; world-flags'
  first `supabase start` failed every time and its Astro server was left orphaned.
- **Firebase and Astro documented as supported stacks**: `reference/STACK-NEXTJS.md`
  ("Astro in the kit", "Backend: Supabase or Firebase"), `backend-build` (emulators, rules
  tests with `beforeAll(…, 30_000)`), `project-kickoff` question 13, the QA agents and the
  `CLAUDE.md.template` QA line.
- QA measuring methods: `design-qa` (ResizeObserver instead of rAF, `Range` per word,
  `hyphens`), `a11y` (real keys for React Aria's focus ring, CDP touch drag), and the Windows
  file rules (no Python/`node -e` with backticks, `fetch` instead of `curl`) in the three QA
  agents.
- `frontend-build`: the `/estados` gallery in the states unit, and a 200 %/320 px build
  checklist (`flex-wrap`, no bare `truncate`, `fixed` with `max-height`).
- `kit-update` piece check: nested `package.json` (installed, typechecked, in CI) and the
  Firebase pieces; `ci.yml` has a commented job per subproject.
- `new-project.ps1 -OnlyPieces`: does not append `* text=auto` to an existing
  `.gitattributes` (it overrode a global `eol=lf`), uses `bun x` instead of `bunx` (not on
  pwsh's PATH) and formats `.claude/settings.json` too.

**Steps for a project on 3.12.0**

1. Global pieces: `install-kit.ps1 -Pull` and a new session (skipped in a cloud session).
   Then refresh the kit copy (`install-kit --project .`): skills and agents changed.
2. `scripts/qa-local.ts` ← `<kit>/reference/scripts/qa-local.ts`, carrying over the
   project's edits (`ENV_MAP`, `ROLE_BY_ENV`, `assignRole`). **A Firebase project that had
   its own `qa-local.ts`** (inversiones-js): replace it with the kit's; its seed script
   becomes `scripts/seed-emulator.ts` (rename or a one-line wrapper), a role kept in a
   document (`admins/{uid}`) goes to `assignRoleFirebase`, and if the client reads a flag
   with another name than `<prefix>USE_EMULATORS`, add it to the env loop. Check
   `package.json` has `"emulators": "firebase emulators:start --project demo-<name>"`.
3. `CLAUDE.md`, the "QA against a local database" paragraph: replace it with the template's
   new one, keeping only the project's backend ("Supabase in Docker" or "the Firebase
   emulators (Java, no Docker)"). Same length; check `wc -c CLAUDE.md` ≤ 8 KB.
4. `.gitattributes`: if it has a global `* … eol=lf` rule **followed by** a bare
   `* text=auto` line (added by an earlier `-OnlyPieces`), delete that later line.
5. Nested subprojects (`git ls-files '*/package.json'`): for each, `bun install` in its
   folder, its typecheck, and its job in `.github/workflows/ci.yml` (the commented `bot:`
   job of `<kit>/github-templates/workflows/ci.yml`). A red typecheck goes to the PR as a
   finding, not fixed silently.
6. Firebase rules tests (`@firebase/rules-unit-testing`): `beforeAll(…, 30_000)` around
   `initializeTestEnvironment`.
7. If a wave is in progress with QA findings planned "for the next wave": nothing to
   migrate; from now on `orchestrate` puts them in the current one.

---

## 3.12.0 — 2026-10-20 · `.env` in cloud sessions without pasting it

**What changed**

- **`cloud-setup.sh` pulls `.env.local` from Vercel** (Development) at the start of a cloud
  session when the environment has `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`
  (and optionally `VERCEL_ENV_FILE`) and allows `api.vercel.com`. Never prints values. Why:
  in tutor-web the service-account key was pasted into the chat to get Firebase working in
  the cloud, and had to be rotated.
- `cloud-session`: the `.env.local` row points to that setup and forbids asking for keys in
  the chat. `reference/DEPLOY.md` §2d documents the one-time setup; `GUIDE.md` cites it.

**Steps for a project on 3.11.0**

1. `scripts/cloud-setup.sh` ← `<kit>/reference/scripts/cloud-setup.sh` (carry over local edits).
2. Refresh the kit copy (`install-kit --project .`): `cloud-session` changed.
3. **Manual action for César** in the PR: the cloud environment setup of `DEPLOY.md` §2d
   (if the project deploys to Vercel and the cloud needs its variables).

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
   versions (8.8 KB and 8.1 KB). `CLAUDE.md.template` stays ≤ 7 KB, so the project keeps
   1 KB of its own (melao).
   A step that replaces a line also says what to do **when the line is not there** (the
   project is older than it, or trimmed it): add the new one or not, and, if the file is at
   its cap (8 KB), which kind of line to shorten to make room. Without that, world-flags
   skipped 3.15.0 step 5 and had to cut its own rules for 3.16.0 step 2. Measure with LF
   (`git show HEAD:CLAUDE.md | wc -c`): on Windows the working copy counts the CRs.
5. If a step edits a `context/` file a project may not have (it started short), it says what
   to do if it is missing (usually: create it with only the step's sections).
6. Steps are written for both kinds of project: new ones (English `context/`) and those
   created before 3.8.0 (Spanish `context/`, left as they are).
