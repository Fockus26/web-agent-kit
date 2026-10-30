# web-agent-kit — kit maintenance

This repo **is the kit**, not a project. No site gets built here: the skills, agents,
templates, scripts and prompts the projects use get improved. (The template that goes to
each project is `CLAUDE.md.template`; this file is not copied anywhere.)

Map: `README.md` (what each piece is) · `GUIDE.md` (how it is used) · `UPDATES.md`
(versions and migrations) · `VERSION` (current version) · `feedback/` (project reports
already processed).

**Language:** the kit's files are written in English. Everything said to César — questions,
triage tables, PR titles and bodies, commit descriptions — is in Spanish.

## When feedback arrives from the projects

It arrives in two ways, both from a project's `context/KIT_FEEDBACK.md`:

- **PRs with the `kit-feedback` label** (the normal way since 3.6.0): each project's
  `kit-feedback` skill uploads its report as `feedback/<date>-<project>.md`. When César asks
  "revisa el feedback": `gh pr list --label kit-feedback --state open`, and each one's file
  with `gh pr diff <n>`.
- A pasted "Informe de feedback" (projects that do not have the skill yet).

1. **Triage**, in a table, changing nothing: for each point — the kit piece affected (file
   and section), whether it is already solved in the current version (search for it: the
   project may be behind; its version is in the report's header), and the concrete change
   proposed. **Consolidated across reports:** the same problem in several projects is one
   row, with the "Times" added up and a "Projects" column. Order by "Times": most repeated
   first. Flag what is **specific to one project** or to a stack the kit does not cover, and
   must not be generalized.
2. César chooses what goes in. If a point admits several reasonable solutions: 3 options
   with their real advantage and disadvantage.
3. Implement what was chosen on a branch (`feat/…` or `fix/…`), changing the fewest pieces
   and keeping their style: English, direct tone, rules with their why, no filler.
4. **Version** (see the end of `UPDATES.md`): bump `VERSION` and add the entry at the top
   with what changed and **the steps for a project on the previous version**. If the change
   only affects skills/agents (installed globally), the steps may be "none in the project;
   reinstall the skills".
5. Update `README.md`/`GUIDE.md` if something César does or sees changes.
6. Commit (Conventional Commits, description in Spanish), push and PR. César merges. In the
   body, the feedback PRs it addresses (`Atiende: #12, #14`).
7. **Close the loop:** on each feedback PR, a comment (in Spanish) with what went in (and in
   which PR) and what did not and why (`gh pr comment`). César merges them: they stay in
   `feedback/` as history, and a point that arrives again is compared with what was decided
   there.

## Rules when editing the kit

- What a project's agent **always** reads (`CLAUDE.md.template` ≤ 7 KB, `CURRENT_PHASE` ≤ 60
  lines) is kept short: the long material goes to `reference/` and is cited.
- Every change an existing project needs to apply **has** its entry in `UPDATES.md`;
  otherwise old projects fall behind without knowing.
- Every new rule says why it exists (the incident or the measurement that prompted it).
- Check Context7 before writing code or library APIs in the guides.
- `new-project.ps1`: test it in a temporary folder (`-Existing` on a minimal `package.json`)
  before calling the change good. Same with the scripts in `reference/scripts/` and
  `wt.ps1`: run them, not just read them.
- Projects created before 3.8.0 keep their `context/` in Spanish: a skill that names a
  heading or a file of `context/` must still work with the Spanish one (say so where it
  matters, as the skills already do).
- Renaming a file the installed skills or old projects call (`install-kit`, `new-project`,
  `prompts/ACTUALIZAR-KIT.md`) leaves a forwarding file with the old name.
