# Git State — {{PROJECT_NAME}}

> The source of truth for "how and where is this unit delivered?". The `git-flow` skill reads
> it before creating any branch. **Never infer the base from `git branch --show-current`.**

## Mode

**`{{pr | local}}`**

| Mode | When | Closing a unit |
|---|---|---|
| `pr` | There is a remote and a protected `main` (the normal case once the repo is on GitHub) | commit(s) on the branch → push of the branch → `gh pr create` → **César reviews and merges** (squash) |
| `local` | No remote, or César prefers it | approval pause → commit → `--no-ff` merge into the base → push only if base ≠ `main` |

In `pr` mode the branches' status is `gh pr list`: the table below is not needed (leave it empty).

## Base branch of the next unit

`{{main | parent-branch-name}}`

## Active parent branch (`local` mode only, big blocks)

`{{parent-branch-name | none}}`

## Working branches (`local` mode only)

| Branch | Base | Unit | Status |
|---|---|---|---|
| {{design/hero}} | {{design/integration}} | {{Hero section}} | {{open / in review / merged}} |

<!-- Merged branches are not deleted: deleting is destructive and César decides it. -->

## Parallel work on this machine

What `orchestrate` launches at once here (§4). This file is local: each machine keeps its own.
Without this section, the defaults below.

| Limit | Value | Default |
|---|---|---|
| Workers running at once | `{{3}}` | 3 |
| Dev servers at once (`bun run dev`, `qa:local`) | `{{2}}` | 2 |
| Local builds at once (`next build`, `--preview`) | `{{1}}` | 1 |
| Full suite and full typecheck | `{{ci | local}}` | `ci` when CI runs them, else `local` (one slot at a time) |

<!-- Why: on a Windows laptop with 4–7 workers, suites passed 10 min, typecheck 6 min without
     finishing (CI: 1m50s), `next dev` stopped answering and 3 of 4 PRs left without
     screenshots (krea ×19, iglesia-maranatha ×12, kit-deploy ×7). A desktop with more RAM
     raises the numbers. -->
