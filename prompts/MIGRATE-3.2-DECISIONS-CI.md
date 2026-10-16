# Migration 3.1.0 → 3.2.0 — decisions per file and CI on the version PR

`kit-update` applies the steps that `UPDATES.md` cites from here (it does the branch, the
verification and the closing). Kept as a standalone block for reference.

What changed in the kit:

- **Decisions:** there is no `context/DECISIONS_INDEX.md` or per-topic files
  (`decisions/01-colores.md`) any more. Each decision is its own file
  `context/decisions/D0NN-<topic>.md` and its first line is the index row
  (`# D0NN · Category · Summary · Status`). The index comes from
  `grep -rh "^# D" context/decisions/`. So two PRs that record decisions do not collide,
  like changesets with the CHANGELOG.
- **CI on the version PR:** the `chore(release): versión` PR is opened by `GITHUB_TOKEN`,
  which does not fire `pull_request`, and it was left without the `ci` check (it had to be
  merged with a bypass). Now `release.yml` triggers `ci.yml` with `workflow_dispatch` on the
  PR's branch.

If the project does not use Changesets (no `.github/workflows/release.yml`), the CI part
does not apply: do only the decisions part.

---

```text
This project follows an earlier version of the web-agent-kit. The kit changed two things and
the project has to be aligned: decisions become one file per decision (no
DECISIONS_INDEX.md) and CI runs on the version PR.

The kit is <kit> (read and copy only; do not modify it).

Read first, from the kit:
- <kit>\context-templates\decisions\README.md (new format and the "Migrating" section)
- <kit>\github-templates\workflows\ci.yml and release.yml
And from the project: CLAUDE.md, context/GIT_STATE.md, .gitignore and `git log --oneline -10`.

1. Diagnosis (changing nothing): tell me in a table what there is today:
   - whether context/DECISIONS_INDEX.md exists, how many decision rows it has
     (`grep -c "^| D[0-9]" context/DECISIONS_INDEX.md`) and which files are in context/decisions/,
   - how many decision sections those files have (`grep -rc "^## D[0-9]" context/decisions/`)
     and which IDs are on one side and not the other,
   - whether context/decisions/ and DECISIONS_INDEX.md are in git or local (.gitignore and
     `git ls-files context/`),
   - whether .github/workflows/release.yml and ci.yml exist, and whether ci.yml already has
     workflow_dispatch,
   - open PRs (`gh pr list`) touching DECISIONS_INDEX.md or context/decisions/
     (`gh pr view <n> --json files -q '.files[].path'`),
   - citations of the old format: `grep -rn "DECISIONS_INDEX\|decisions/[0-9]" --exclude-dir=node_modules --exclude-dir=.git .`,
   - memories of this project (~/.claude/projects/<this project>/memory/) that talk about
     DECISIONS_INDEX or merging the version PR with a bypass.
   If there are IDs without detail or detail without a row, tell me before going on: do not
   invent the missing one.

2. Branch per context/GIT_STATE.md (pr mode: `chore/decisions-and-ci` from an updated
   origin/main; local mode: the branch from the base).

3. Decisions, following the "Migrating" section of the kit's decisions/README.md:
   - For each `## D0NN — <title>` in the old files, create
     context/decisions/D0NN-<topic-kebab>.md. First line:
     `# D0NN · <Category> · <Summary> · <Status>`, with Category, Summary and Status taken
     from its DECISIONS_INDEX.md row (if the row has no category, use the old file's topic).
     One-line summary (header ≤ 160 characters); if the row was a paragraph, the rest goes
     to the body. Below it, the body unchanged, without the `**Status:**` line. Keep the
     project's language (an older project's decisions stay in Spanish).
   - An index row without a detail section: a file with the header and
     `**Decision:** <the row's summary>` as body.
   - A section grouping several (`## D037 / D038 / D039 — <title>`): one file per index ID,
     each with its header; the shared body goes in the first and the others carry
     `**Groups:** see D037` as body. Without that, crossing index ↔ detail gives false gaps.
   - Copy <kit>\context-templates\decisions\README.md over context/decisions/README.md.
   - Check nothing is lost:
     `ls context/decisions/D*.md | wc -l` = number of distinct IDs of the old index, and
     `grep -rh "^# D" context/decisions/ | sort` lists them all, in order, without gaps that
     were not there before. Show me the result.
   - Delete context/DECISIONS_INDEX.md and the old NN-<topic>.md files (with `git rm` if
     they were in git).
   - Replace the citations `decisions/NN-<topic>.md` with the new file or the ID, in
     context/, phases/, .github/ and CLAUDE.md. Do not rewrite closed PHASE_LOG/ files: it
     is enough that the ID stays searchable.

4. CLAUDE.md (cap 8 KB), comparing with <kit>\CLAUDE.md.template; change only the flow,
   keep what belongs to the project:
   - "Search, don't read": `decisions/` (one file per decision) instead of
     DECISIONS_INDEX.md, and the example `grep -rhi "^# D.*modal" context/decisions/`.
   - "What goes in the repo": remove DECISIONS_INDEX.
   - Any other mention of the old format that comes up in step 1's grep.

5. CI (only if .github/workflows/release.yml exists):
   - ci.yml: add `workflow_dispatch:` to the `on:`, with the kit's comment. Do not touch its
     steps or variables: they belong to the project.
   - release.yml: add, as in the kit's, `actions: write` in permissions, `id: changesets` on
     the changesets/action step and the final "CI for the version PR" step. If the project's
     release.yml has no changes of its own versus the kit's, copy it whole.
   - Validate the syntax: `bunx --bun js-yaml .github/workflows/ci.yml` and the same with
     release.yml.
   - If the CI job's name is not `ci` or main's required check has another name
     (`gh api repos/{owner}/{repo}/branches/main/protection -q .required_status_checks.contexts`,
     may give 403 on private repos without Pro), tell me: the check that gets triggered has
     to have the same name as the required one.

6. Project memories: update or delete the ones describing DECISIONS_INDEX.md or the version
   PR bypass.

7. Verification: typecheck, lint, tests and build green (with Biome, `bunx biome check` sees
   the .md and .yml files the config covers).

8. Closing per git-flow: commit `chore: decisiones por archivo y CI en el PR de versión`
   (only this unit's files), push and PR with the template. No changeset of its own (it is
   tooling). In the PR's "Acciones manuales":
   - The open PRs that touched DECISIONS_INDEX.md (list from the diagnosis): when they sync
     with main, their row becomes the header of a new D0NN-<topic>.md file and their change
     to the index is dropped. If there are few, better merge this PR when none are left.
   - When this PR is merged, release.yml already runs with the new step and the version PR
     (if there are pending changesets) should get the `ci` check. If it does not show up:
     check the "Release" run in Actions, and as a way out Actions › CI › Run workflow on
     `changeset-release/main`.

Final report (in Spanish): PR URL, how many decisions you migrated (and whether something was
missing), what you changed (one line per file), memories touched, open PRs to adjust and what
you could not verify.
```
