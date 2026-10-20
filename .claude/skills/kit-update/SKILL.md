---
name: kit-update
description: Brings a project up to date with the latest web-agent-kit version. Use it when César asks "update the kit", "is the kit up to date?" ("actualiza el kit", "¿está al día el kit?"), "/kit-update", or when a project carries a kit version older than main's. Compares the project's version (.kit-version), the installed skills' version and the kit's origin/main (local clone + git fetch); if they match it says so and checks for missing pieces, if the skills are old it reinstalls them and asks for a new session, and if the project is behind it computes the path in UPDATES.md and applies it on a branch and a PR, one commit per version.
---

# Update the kit in a project

Runs in a session opened **in the project's folder**. It reads the kit from its local
clone, always as it is on `origin/main` (what is published), never from a half-done branch.
It does not touch the project's `main`: everything goes on a branch and a PR.

**Not in a cloud session** (`CLAUDE_CODE_REMOTE=true`): there is no kit clone or
`~/.claude/` there to compare against or reinstall. Say so and ask César to run
`/kit-update` from his machine.

**Language:** everything you tell César, the commits and the PR are in Spanish. Projects
created before kit 3.8.0 keep their `context/` in Spanish (same files, Spanish headings,
plan names such as `pendientes.md`): migration steps written for English headings apply to
their Spanish equivalents; do not translate or rename the project's files.

## 0. Where the kit is

`~/.claude/web-agent-kit.json` is written by `install-kit` when installing:

```json
{ "path": "C:\\...\\web-agent-kit", "version": "3.8.0", "installed": "2026-10-16" }
```

- `path` = the kit's clone (I call it `<clone>`). `version` = the installed skills'.
  Installations before 3.8.0 wrote `ruta` / `instalado`: read them the same way.
- If the file does not exist (installed before 3.6.0 or by hand): look for the clone in
  `~/Desktop/agents/web-agent-kit` and, if it is not there, ask César for the path. The
  installed skills count as an unknown (= old) version.
- If `<clone>` is not a git repo with an `origin` remote: stop and say so. Without a clone
  there is nothing to compare against (on another machine: `git clone
  https://github.com/Fockus26/web-agent-kit.git` and `install-kit`).

## 1. The three versions

```bash
git -C "<clone>" fetch origin --quiet
git -C "<clone>" show origin/main:VERSION          # published (target)
git -C "<clone>" status --porcelain --branch       # current branch and uncommitted changes
```

| Version | From |
|---|---|
| **Published** | the clone's `origin/main:VERSION` |
| **Installed skills** | `version` in `~/.claude/web-agent-kit.json` |
| **Project** | the project's `.kit-version`. If it does not exist, deduce it with the table "How to tell a project's version without `.kit-version`" in `UPDATES.md` and show the signals; if they contradict each other, ask |

Show them in one line: `proyecto 3.4.0 · skills 3.5.0 · publicada 3.8.0`.

## 2. What to do

**a) Project = published:** "El proyecto está al día con el kit <versión>." If the installed
skills are also older, say it is worth reinstalling them (step b). Run the "Piece check"
(below), read-only: if everything is there, finish; if something is missing, show it in a
table and ask whether to add it (branch `chore/kit-pieces`, step 3 for `<kit>` and the
closing of step 9).

**b) Installed skills < published:** new skills only load when a session opens, and the
migrations use them. Before migrating anything:

- If the clone is on `main` with no changes (`## main...origin/main` and nothing else in
  the `status`): install from there, which does the `git pull --ff-only` first:
  `powershell -ExecutionPolicy Bypass -File "<clone>\install-kit.ps1" -Pull`
  (macOS/Linux: `bash "<clone>/install-kit.sh" --pull`).
- If the clone is on another branch or has changes (César is editing the kit): do not touch
  it. Tell him to go back to `main` in the kit or to run the installer when he is done.

Then stop: "Abre una sesión nueva en este proyecto y escribe `/kit-update` otra vez." Do
not go on with the old skills loaded.

**c) Project > published:** something is off (it was updated from an unmerged kit branch).
Say so and ask; touch nothing.

**d) Project < published and skills up to date:** go on with step 3.

## 3. Read copy of the kit

The migration steps read and copy files from `<kit>`. `<kit>` is:

- `<clone>`, if it is on `main` with no changes and up to date with `origin/main` (step 2b
  already did the pull);
- otherwise, a copy of `origin/main` in the scratchpad, without touching the clone:
  `mkdir -p "<scratchpad>/kit" && git -C "<clone>" archive origin/main | tar -x -C "<scratchpad>/kit"`.

From the kit you only read and copy: no commits, pulls or changes in it.

## 4. Path

Every entry of `<kit>/UPDATES.md` after the project's version, from oldest to newest. Show
it as a list (version · what changes in one line) before touching anything.

## 5. The project's context

Read `CLAUDE.md`, `context/GIT_STATE.md`, `.gitignore`, `package.json` and
`git log --oneline -10`. And the project's memories
(`~/.claude/projects/<this project>/memory/`), in case one describes a flow the path changes.

## 6. Diagnosis of the whole path, changing nothing

For each version, what its diagnosis step asks for: one table per version. Gather into **a
single round** of questions (AskUserQuestion) everything the versions ask to ask; do not
ask version by version.

If a step edits a file the project does not have (e.g. `context/COLORS.md` in a project
that started short), create it with only the sections that step asks for and say so in the
diagnosis.

If the project is **without versioning** (its `CLAUDE.md` says so, or it has no
`.changeset/` and César confirms), the Changesets steps of any version are skipped: they are
not a pending migration, and it is not asked again.

Add the **piece check** (below) to the diagnosis.

## Piece check

A project can be on the right version and still lack pieces the skills take for granted (it
happened: a project on 3.5.0 without `test:related` or `shots`, because it started before
`new-project.ps1` added them; the workers improvised four times). Changing nothing, check:

| Piece | How |
|---|---|
| `package.json` scripts: `test`, `test:related`, `shots`, `shots:publish`, `qa:local`, `context:backup`, `context:restore`, and their files in `scripts/` | `package.json` and `ls scripts/` |
| devDependencies: `@types/bun`, `@playwright/test`, `@axe-core/playwright` (and `@changesets/cli` if versioned) | `package.json` |
| `.gitignore` with `.pr-shots`, `.env*.local` (or `.env*`) and `.claude/worktrees/` | `git check-ignore -q <path>` |
| **`.gitignore` does NOT ignore** `supabase/` (except `.temp/`, `.branches/`) or the fixed documents of `context/` (`PROJECT_CONTEXT`, `DESIGN_RULES`, `COLORS`, `DESIGN_TOKENS`, `TYPOGRAPHY`, `decisions/`) | `git check-ignore -v supabase/migrations context/PROJECT_CONTEXT.md context/decisions` |
| `biome.json` (if any) excludes `.claude/worktrees` | `files.includes` / `files.ignore` |
| `CLAUDE.md` ≤ 8 KB | `wc -c CLAUDE.md` |
| Kit copy for cloud sessions: `.claude/skills/<each kit skill>` and `.claude/agents/<each kit agent>`, equal to `<kit>`'s, not gitignored | `diff -rq "<kit>/.claude/skills/<name>" .claude/skills/<name>` per kit skill (and agents); `git check-ignore -q .claude/skills` |
| `.claude/settings.json` with the `SessionStart` hook to `scripts/cloud-setup.sh`, and the script | `grep cloud-setup .claude/settings.json`; `ls scripts/cloud-setup.sh` |
| Backup of the local `context/` on the remote | `git ls-remote --heads origin context-state` |

What is missing is added with the kit's own script, which only adds what does not exist and
overwrites nothing: `pwsh -File "<kit>/new-project.ps1" -Path . -Existing` (plus
`-NoVersion` if the project is without versioning). It goes in the same PR, in its own
commit (`chore(kit): piezas que faltaban`). If the stack is not Next.js (Astro, Vite), say
so first: the scripts may need adjusting, and it is a question for the single round.

If `supabase/` or the fixed documents of `context/` are gitignored, it is a question for the
single round, not something you change silently: César may have done it on purpose. The
recommendation, with its reason: they go in git (without them, losing the folder loses the
schema and the decisions; the pool and `wave-qa` do not see the migrations); if the reason
was privacy, the repo is made private. With his yes: remove them from `.gitignore`, `git
add` them (check first that there are no secrets in them) and commit them in this PR. And
if there is no `context-state` yet, the first `bun run context:backup` (private repo) after
the merge, as a manual action in the PR.

## 7. Branch

Per `context/GIT_STATE.md`: `pr` mode → `chore/kit-<published>` from an updated
`origin/main`; `local` mode → from the base.

## 8. Apply each version, in order

Follow its "Steps" in `<kit>/UPDATES.md` (and the prompts they cite, only the steps
indicated). The "global pieces / install-kit" step is already done (step 2). When each
version is done:

- write its number in `.kit-version` (one line, nothing else);
- commit only that version's files:
  `chore(kit): actualiza a <versión> — <qué cambia en pocas palabras>`.

If a version fails halfway, stop there: what was done stays in commits and `.kit-version`
says how far it got.

With every version applied, **refresh the project's copy of the skills and agents** (cloud
sessions load only that one): `powershell -ExecutionPolicy Bypass -File "<kit>\install-kit.ps1" -Project .`
(macOS/Linux: `bash "<kit>/install-kit.sh" --project .`). It replaces only the kit's skills
and agents; the project's own stay. Its own commit:
`chore(kit): copia de skills y agentes <versión>`. If `.claude/settings.json` existed
without the cloud hook, merge the kit's `reference/claude/settings.json` `SessionStart`
into it (keep what it had).

The project's `CLAUDE.md` stays at 8 KB or less (`wc -c CLAUDE.md`). If a step pushes it
over, replace the old paragraph that the step supersedes instead of adding, and if it still
does not fit, ask which project-specific part moves to `context/`.

## 9. Verification and closing

- Typecheck, lint, tests and build green.
- Close per `git-flow`: push and PR with the template, title
  `chore(kit): actualiza de <origen> a <destino>`. No changeset (it is tooling). In the
  body: the path, a summary per version, and in "Acciones manuales" what each version asks.
  In `local` mode: approval pause and merge as always.
- If a version left design or implementation work pending (e.g. 3.3.0's status screens), do
  not do it here: it goes to `context/plans/backlog.md` (`pendientes.md` in older projects),
  and give César the text for Claude Design if there is one.

## Final report

In Spanish: PR URL, path applied, what changed (one line per file), memories touched, open
questions, backlog items created and what could not be verified.

And log in `context/KIT_FEEDBACK.md` any migration step that was confusing or wrong (type
Gap or Friction, piece "UPDATES.md <version>"). It reaches the kit with `/kit-feedback`.
