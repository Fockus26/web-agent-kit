# Migration 3.0.0 → 3.1.0 — worktree pool and versioning with Changesets

`kit-update` applies the steps that `UPDATES.md` cites from here (it does the branch, the
verification and the closing). Kept as a standalone block for reference.

What changed in the kit:

- **Worktrees:** `orchestrate` no longer creates and deletes a worktree per unit. It uses a
  fixed pool (`..\<repo>-wt\wt1..wtN`) managed by `wt.ps1`; `node_modules` stays in each slot.
- **Version and CHANGELOG:** no PR touches `version` or `CHANGELOG.md`. Each PR with a
  visible change adds a `.changeset/<desc>.md` and an Action keeps the
  `chore(release): versión` PR, which César merges when he wants to publish.

---

```text
This project follows the previous version of the web-agent-kit. The kit changed two things
and the project has to be aligned. The kit is at <kit>.

Read first, in ~/.claude/skills/ (already updated):
- git-flow/SKILL.md §1.2, §2.1 (step 6), §2.1.3 and "Migrating an existing project to Changesets"
- orchestrate/SKILL.md §6, §7 and §8
And from the project: CLAUDE.md, context/GIT_STATE.md, package.json and `git log --oneline -15`.

1. Diagnosis (changing nothing): tell me in a table what there is today:
   - whether the project is versioned (there is a CHANGELOG.md or `version` has been bumped),
   - whether .changeset/ or .github/workflows/release.yml already exist,
   - open PRs (`gh pr list`) that bump `version` or touch CHANGELOG.md,
   - plans in context/plans/ with a half-done batch that reserves versions or ports,
   - whether .gitignore ignores `.env*` (the pool only copies the ones git ignores),
   - mentions of the old flow: `grep -rn -i "changelog\|versión\|version\|worktree\|isolation\|merge order\|orden de merge" CLAUDE.md context/ .github/`,
   - memories of this project (~/.claude/projects/<this project>/memory/) that talk about
     bumping the version, merge order by version or new worktrees.
   If the project is NOT versioned, ask me first whether we adopt it; if I say no, skip the
   Changesets steps (the project is "no versioning").

2. Branch per context/GIT_STATE.md (pr mode: `chore/changesets` from origin/main).

3. Changesets (if versioned), following git-flow's migration guide:
   - `bun add -d @changesets/cli`
   - copy <kit>\changeset-templates\ as .changeset\ and
     <kit>\github-templates\workflows\release.yml to .github\workflows\ (if it already
     exists, replace it: the kit's version triggers CI on the version PR)
   - add `workflow_dispatch:` to the `on:` of .github\workflows\ci.yml (without it, the
     version PR lacks the `ci` check)
   - do not touch CHANGELOG.md or `version`: the Action continues from there
   - if the project uses Biome: `bunx biome check --write .changeset`
   - check with `bunx --bun changeset status` that it reads the config (a warning about
     missing changesets is normal in this PR; do not run `changeset version`)

4. Align the project's files with the kit's templates (compare with
   <kit>\CLAUDE.md.template, <kit>\github-templates\pull_request_template.md and
   <kit>\context-templates\PHASE_LOG\README.md; change only the flow, keep what belongs to
   the project):
   - CLAUDE.md: the "Version: nobody touches `version` or `CHANGELOG.md`…" line in the git
     section, and the paragraph about gitignored files ("The worktree pool slots… get the
     `.env*` files copied, but not the local context/"). Cap 8 KB.
   - .github/pull_request_template.md: the version checkbox becomes a changeset one.
   - context/PHASE_LOG/README.md (local): header with changeset instead of version.
   - Any other mention from the diagnosis that describes the old flow.
   - Record the decision in its own file context/decisions/D0NN-<topic>.md (format in
     <kit>\context-templates\decisions\README.md; if the project still uses
     DECISIONS_INDEX.md, also add its row there):
     "Version with Changesets; the version PR is opened by the Action and merged by César".

5. Project memories: update or delete the ones describing the old flow (bump the version in
   every PR, merge order by version, a new worktree per unit, copying the .env by hand).

6. Verification: typecheck, lint, tests and build green (it is a tooling change, but Biome's
   lint sees .changeset/config.json).

7. Closing per git-flow: commit `chore: adopta changesets y el pool de worktrees del kit`
   (only this unit's files), push and PR with the template. No changeset of its own (it is
   tooling). In the PR's "Acciones manuales":
   - GitHub › Settings › Actions › General › "Allow GitHub Actions to create and approve pull
     requests" (already done if César says so)
   - GitHub › Settings › General › "Automatically delete head branches"
   - The open PRs that bump the version (list from the diagnosis): when they sync with main,
     they drop their `version`/CHANGELOG.md change and add their changeset.

8. Do not run `wt init` now: orchestrate does it the first time it launches a batch.

Final report (in Spanish): PR URL, what you changed (one line per file), memories touched,
open PRs to adjust and what you could not verify.
```
