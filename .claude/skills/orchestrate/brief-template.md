# Orchestration of {{DATE}} — shared brief for the workers

> {{Phase 0N, wave N of M — plan: `context/plans/phase-0N-<name>.md` | Standalone batch}}

> **Every worker** reads this before starting. Its prompt carries only what is specific to
> its unit. Main folder of the repo: `{{ABSOLUTE_PATH}}` (the local/gitignored files live
> there: `context/CURRENT_PHASE.md`, `context/CONTENT_CHECKLIST.md`, `context/PHASE_LOG/`,
> `context/plans/`, `.env`).

## Units and order

| # | Branch | What | Wave | Slot / port |
|---|---|---|---|---|
| W1 | `{{feat/...}}` | {{...}} | 1 | {{wt1 / 4301}} |

Slot and port are assigned by `wt take` at launch; the message that launches each worker
repeats them.

Wave 2 starts from `main` **after** {{W…}} are merged (they touch {{which files}}).

## Reserved numbers

| Unit | Decision IDs | `CONTENT_CHECKLIST` rows |
|---|---|---|
| W1 | {{D0NN–D0NN}} | {{NN–NN}} |

Do not use numbers outside your range.

## César's decisions for this batch

- {{e.g. "each worker may start its server on its port"}}
- {{e.g. "W1 may apply new columns through the MCP; nothing destructive"}}

## Simulating the backend

How a worker sees data-dependent states without logging in to the real backend. Fill it in
before launching: with "intercept Supabase" alone, two workers copied a mocks file from
another slot and guessed the build command, and a third inherited stale `.qa/` scripts
(world-flags).

- Shared mock script (in the repo): `{{scripts/qa/mock-backend.mjs | none yet: W1 creates it}}`
- Exact build / server command with it: `{{e.g. PUBLIC_SUPABASE_URL=http://127.0.0.1:9 bun run build && …}}`
- App state to skip (tutorial, cookie banner, onboarding): `{{helper or localStorage key}}`

Nothing from another slot's `.qa/`: it belongs to a previous unit and may be stale.

## Batch rules (on top of `CLAUDE.md`)

1. **Read only** `CLAUDE.md` and what your prompt cites (paths, lines, decisions). Do not
   read the whole `context/`; the rest, with `grep`.
2. **Slot and branch:** you work ONLY in your pool slot's path (`..\<repo>-wt\wtN`), which
   already has your branch created, `node_modules` installed and the `.env*` files copied.
   Do not create or delete worktrees, do not run `wt` and do not switch branches.
3. **Shared local files:** do not edit `CURRENT_PHASE.md` or `CONTENT_CHECKLIST.md`. Write
   `context/PHASE_LOG/<your-branch-with-dashes>.md` in the main folder; if you have no write
   permission there, deliver it whole in your final report.
4. **Decisions:** one file per decision, `context/decisions/D0NN-<topic>.md`, with the IDs
   of your range and the one-line header (format in `context/decisions/README.md`). It goes
   in git. There is no index to edit.
5. **Changeset:** the bump your prompt says (patch/minor/major, or none). If there is one, a
   `.changeset/<desc-kebab>.md` written by hand (format in `git-flow` §2.1) with user-facing
   text in Spanish. Do not touch `version` or `CHANGELOG.md`: the version PR writes them.
6. **Server:** {{authorized: `bun run dev -- --port <your slot's port>` in the background,
   in your slot (already installed, with `.env*`). | not authorized: verify through code,
   and flag it.}} If the port is taken, do not start on another one: the framework jumps to
   the next free port without warning and lands on another worker's; say so in the report.
   Shut it down when done by killing **your** process and its children (Windows:
   `taskkill /PID <pid> /T /F`; a plain `kill` only kills the shell and leaves the server
   orphaned on the port), never with a `<framework> stop`, which stops the project's server
   and may be another slot's. **Astro ≥ 7** detaches `astro dev` into the background: start
   it with `ASTRO_DEV_BACKGROUND=0` so the kill reaches it; if it detached anyway, `bun x astro
   dev stop` run **inside your slot** is safe (its lock, `.astro/dev.json`, is per folder).
   **Docker:** only if your prompt says "Docker: yes" (another unit may be using it).
   If it says "Node.js subprocess crashed … deadline has elapsed" (Turbopack with several
   servers at once): shut it down, delete `.next/dev` and restart it; the 500 stays cached
   and a restart is not enough.
7. **Browser:** create your own tab and pass its `tabId` on every call. Verify by measuring
   the DOM (not by looking at screenshots). Playwright scripts: with `node`, and saved in
   `.qa/` inside your slot (ignored by git): from the scratchpad they cannot find the
   package. Redirects (guest → login): with `curl -sI`, instantly; Playwright can spend
   minutes compiling the route.
8. **Real data:** `.env` points to {{production}}. Do not log in, create accounts or write
   data; verify as a guest or by intercepting responses in the page (for debugging only).
   Logged-in testing with data is done by `wave-qa` once the wave is merged: in your PR,
   "How to test" says which flow and which role, so it can do it.
9. **Tests:** `bun run test:related` while you work (if the project does not have it:
   `bun test <file>` for what you touched). Before the PR, the full suite **alone**: not at
   the same time as the build and not with its output through a pipe (with several workers,
   Bun hangs on Windows or PGlite runs out of memory): `mkdir -p .qa && bun run test >
   .qa/test.log 2>&1` in the background, then read the summary at the end.
10. **Files:** created and changed with Write/Edit. No heredoc for long files (Git Bash
    breaks the ones with quotes and backticks), no `node -e` with backticks, no Python in
    text mode (on Windows it converts to CRLF and Biome flags the whole file). If you
    touched a file through the shell (`sed`, `biome --write`), read it before editing it.
11. **Waiting and searching:** `sleep` is blocked; anything that takes more than 2 min
    (suite, build, typecheck) runs in the background and you wait for its notice. `grep`
    always with scoped paths (`app/`, `lib/`, `components/`): at the root it walks
    `node_modules` and `.next`.
12. **Commit when each stage closes** (backend, UI, docs), not only at the end: an API cut
    (403/429) mid-unit does not take the work with it. When resuming: `git status` and
    carry on; do not reread what you already wrote.
13. **Minimum verification before the PR:** typecheck, lint (no new errors in your code),
    tests, build; if you touched UI, the `a11y` skill (axe light and dark, 320 px, keyboard).
14. **Screenshots:** if something visible changed, rewrite `.pr-shots.json` with your states
    (the one there belongs to the slot's previous unit; the URL goes in the `base` field),
    `bun run shots`, and `bun run shots:publish` in the background (it takes minutes on
    Windows). The markdown is left in `.pr-shots/README.md`: paste it into the PR. Do not
    open the images.
15. **Unable to ask:** when data is missing, the conservative option + "Decision taken /
    alternative" in the PR. Do not block.
16. **Fix the class, in the first pass.** If what you fix (or a bug you meet) has the same
    shape elsewhere — the same anatomy, the same missing `flex-wrap`, the same `truncate` —
    find it with `grep` over the whole `src/`, not only the folder your prompt names, and fix
    it now. What you notice after your PR is up goes in the report as "seen in passing"; if
    Medium or Low, the orchestrator sends it to the backlog, not back to you. Why: in
    world-flags, a snackbar with the same anatomy in another folder was missed, and "bugs in
    passing" cost 2-3 rounds per PR.
17. **New copy = provisional:** flagged in the code + your reserved checklist row.
18. **Closing:** Conventional commits (only your files) with the description in Spanish,
    push of your branch, `gh pr create --body-file .qa/pr-body.md` with the template (PR in
    Spanish; the body written with Write, never inline: quotes and backticks break it). Leave the slot
    clean: everything committed and pushed (empty `git status`), or the orchestrator cannot
    free it. **Never** `gh pr merge`, push to `main`, force-push or amend what was pushed.
    Database: only the authorized additive changes; nothing destructive.
19. **Final report** (the orchestrator reads it, be brief): PR URL, slot, changeset,
    verified / not verified, open decisions, manual actions, bugs seen in passing, and your
    PHASE_LOG if you could not write it.
