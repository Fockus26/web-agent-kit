# decisions/

**One file per decision.** There is no separate index: each file's first line is its index
row, and the index comes from `grep`. So two parallel PRs that decide things never collide,
just like changesets: each brings its new files and nobody edits a shared file.

## Search

```bash
grep -rh "^# D" context/decisions/ | sort               # the whole index (one line each)
grep -rhi "^# D.*ranking\|^# D.*leaderboard" context/decisions/   # anything decided about this?
cat context/decisions/D042-*.md                          # the detail of a cited decision
```

## Name

`decisions/D0NN-<topic-kebab>.md`: `D001-primary-logo-blue.md`, `D017-first-run-tutorial.md`.
The ID is sequential and never reused.

## Format

```markdown
# D0NN · <Category> · <one-line summary, ≤ 120 characters> · <Status>

**Decision:** <what was decided, in 1-2 lines>
**Why:** <the reason; the data or measurement behind it>
**Discarded alternative:** <which and why not> (if there was one)
```

`Status`: `Implemented` | `Pending` | `Obsolete → D0NN`. Usual categories: Colors,
Typography, Tokens, Layout, Components, Responsive, Content, SEO, Data, Auth, Payments, QA,
Email.

Example, `decisions/D001-primary-logo-blue.md`:

```markdown
# D001 · Colors · Primary #0F6E8C (logo blue), #5FB4D1 in dark · Implemented

**Decision:** the primary is the logo blue, #0F6E8C, in light; #5FB4D1 in dark.
**Why:** mandatory brand color. White text on #0F6E8C = 5.6:1 (AA); in dark, #0B1B22 on
#5FB4D1 = 8.1:1.
**Discarded alternative:** #1487AD (brighter) — 3.9:1 with white text, fails AA.
```

## Rules

- A decision is never deleted and an ID is never reused. If it changes: in the old one's
  header, the status becomes `Obsolete → D0NN`, and the new one goes in its own file with the
  next ID.
- Written by whoever decides, when the unit closes — not "later".
- The header is a single line: if the summary needs a paragraph, the paragraph goes in the body.
- With parallel units, each uses the ID range the orchestrator reserved for it. Without an
  orchestrator, the ID after the highest on `main`
  (`git fetch && git ls-tree --name-only origin/main context/decisions/ | sort | tail -1`);
  if, when syncing with `main`, another file with your same ID shows up, renumber yours
  (file, header and citations on your branch).
- This folder goes in git (it is what a new session needs to know what was decided).
- Projects from before kit 3.8.0 have their decisions in Spanish (`Categoría · Resumen ·
  Estado`, `Implementado`): they stay as they are; new ones may follow the same language.

## Migrating a project with `DECISIONS_INDEX.md` and per-topic files

In a PR of its own, `chore/decisions-per-file`, not mixed with anything else:

1. For each `## D0NN — <title>` in `decisions/NN-<topic>.md`, a file
   `decisions/D0NN-<topic-kebab>.md` with the header built from its `DECISIONS_INDEX.md`
   row (ID · Category · Summary · Status) and the body unchanged (without the `**Status:**`
   line, which moves to the header). A section that groups several (`## D037 / D038 / D039`)
   becomes one file per ID: the body in the first and `**Groups:** see D037` in the others.
2. Check nothing is lost: the number of IDs in `DECISIONS_INDEX.md` equals
   `ls context/decisions/D*.md | wc -l`.
3. Delete `DECISIONS_INDEX.md` and the old `NN-<topic>.md` files; replace the citations
   `decisions/NN-<topic>.md` with the ID (`grep -rn "decisions/[0-9]" .`).
4. Update `CLAUDE.md` (the "search, don't read" table and what goes in the repo).

Open PRs that added rows to the index, when syncing with `main`: their row becomes the
header of a new file and their change to `DECISIONS_INDEX.md` is dropped.
