# kit-deploy — brief: our own Vercel on César's VPS

**How to use this file:** it is the idea and the requirements of a project of its own, not a
change to an existing one. Create its repo (`new-project.ps1`), open a session there, run
`/project-kickoff` and paste this file as the idea. The kickoff still interviews: this brief
answers most of its questions, and the ones it leaves open are listed at the end. `kit-deploy` is
a working name. Decided by César, 2026-11-09.

---

## The idea

Host the kit's projects on César's VPS instead of Vercel, with what makes Vercel comfortable and
that a bare server does not have: a **preview per PR**, **deploy on merge**, **environment
variables per environment** edited in a web page, **domains with automatic HTTPS**, **instant
rollback**, and a **dashboard** to see how every project is doing. Ours: no per-seat or per-use
bill, the database next to the app, and the kit's agents driving it the way they drive the
`vercel` CLI today.

Why build it and not install Coolify or Dokploy: both want to own the server (their own proxy,
their own database, their own way of running Postgres), and the VPS is already set up by the
kit's `bootstrap.sh` with a central Postgres that a dozen projects use. They also do not know the
kit's conventions (a `_preview` database per project, `kit-db`, the agent never seeing a secret).
The parts that are hard are not built: Caddy does HTTPS, Docker does isolation, GitHub Actions
does the builds. kit-deploy is the glue and the page.

## What already exists (do not rebuild it)

- **The VPS:** 4 cores, 8 GB RAM, 100 GB disk, EU, Ubuntu/Debian, no provider backups. Reached
  from César's PC with `ssh kit-vps` (key, no password). The kit's `reference/VPS-POSTGRES.md` is
  the server; read it first.
- **Postgres 17** on localhost only, **PgBouncer** on `:6432` with TLS as its only public door,
  one database and one role per project, created with `kit-db` (`create`, `url`, `list`,
  `status`, `backup`, `restore`, `rotate`, `drop`). `<project>_preview` is the previews' database.
  Nightly `pg_dump` of everything, copied off the VPS with rclone.
- **Firewall (ufw):** 22, 6432, and 80 only for the certificate of `db.<domain>`, which certbot
  renews in **standalone** mode on port 80. fail2ban, unattended security upgrades, SSH password
  login off.
- **The projects:** Next.js (App Router) managed with bun, a GitHub repo each, Vercel today: a
  preview per PR whose URL the kit's flow uses (César reviews there; `git-flow` opens it once per
  unit), production on merge to `main`, variables pulled with `vercel env pull`.

## Requirements

**Must (v1)** unless marked v2.

| # | Requirement | Detail |
|---|---|---|
| F1 | **Projects** | Register a project: name (the `kit-db` name, `^[a-z0-9_]+$`), GitHub repo, production branch (`main`), memory limit. A page per project with its state |
| F2 | **Deploy on merge** | A push to the production branch builds and deploys production with no downtime. The page shows each deployment: commit, author, time, state, link to its build log |
| F3 | **Preview per PR** | Each PR gets `<project>-pr-<n>.preview.<domain>`, updated on every push, removed when the PR closes. The URL lands in the PR (a comment updated in place, and a commit status so it shows among the checks). Previews use the Preview variables and the `<project>_preview` database, carry `X-Robots-Tag: noindex`, and ask for a login (César's dashboard session), like Vercel's Deployment Protection |
| F4 | **Environment variables** | Per project and per environment: Production, Preview, Development. Each one secret (write-only: it can be replaced, never read back in the page or the API) or plain. Changing one offers a redeploy; a `NEXT_PUBLIC_*` change says it needs a **rebuild**, not a restart (see Traps). Every change in an audit log (who, when, which name; never the value) |
| F5 | **Pull for development** | The equivalent of `vercel env pull .env.local --yes`: the agent writes the Development set to a file without printing it. Over SSH, like `kit-db`: `ssh kit-vps kit-deploy env pull <project> > .env.local` or a small script in the kit. No token on the PC |
| F6 | **Domains** | Add a domain to a project: the page shows the DNS records to create, checks they resolve to the VPS, and Caddy gets the certificate. `www` redirected to the apex (or the reverse, a choice per domain). Certificate state and expiry visible |
| F7 | **Rollback and controls** | Roll back to any of the last 5 production deployments in seconds (the image is kept, nothing is rebuilt). Redeploy, restart, stop |
| F8 | **Logs** | Runtime logs per deployment, live (tail) and searchable for the last days. The build log is the GitHub Actions run, linked |
| F9 | **Metrics** | CPU and memory per container against its limit, disk and memory of the VPS, requests and errors (5xx) per project from Caddy's logs |
| F10 | **Health and alerts** | A health check per project. Alert when a site is down, a certificate expires in < 14 days, the disk passes 80 %, memory is tight, or `kit-db status` shows a failed backup. Channel: César decides (email through Brevo, or Telegram) |
| F11 | **Databases** | The project's page shows its databases (`kit-db list`/`status`) and creates them. **The platform puts `DATABASE_URL` into Production and Preview by itself** from `kit-db url`, so nobody pipes it by hand any more and nobody sees it |
| F12 | **Cron** | Scheduled jobs per project (a route + a schedule), called with the project's `CRON_SECRET`, with a log of each run. It replaces the hand-made systemd timers of `tech/vps-postgres.md` |
| F13 | **Access** | César only in v1: Better Auth with a passkey or TOTP, no public sign-up. v2: collaborators, and a read-only view for a client |
| F14 | **The agent's interface** | Everything the kit's agents need, over SSH and without secrets on screen: `kit-deploy list`, `status <p>`, `env ls/pull/set <p> <env>` (`set` reads the value from stdin, so César types it in his terminal), `logs <p>`, `deploy <p>`, `rollback <p>`. v2: an MCP server |
| F15 | **Static and Astro sites** (v2) | A static export served by Caddy itself, and Astro with the Node adapter as one more container |

**Non-functional**

- **Sites do not depend on the dashboard.** If kit-deploy is down or being updated, every site
  keeps serving: Caddy and the containers run on their own (`restart: unless-stopped`), and
  everything comes back by itself after a reboot.
- **Its state is rebuildable.** The source of truth is kit-deploy's own database (`kit-db create
  kit_deploy`, so it gets the nightly backup). Caddy's site files and the containers are generated
  from it: a command regenerates them all.
- **No downtime on deploy.** The new container starts beside the old one, the switch only happens
  when its health check answers, and the old one is stopped after a drain of ~10 s.
- **No Kubernetes, no Swarm, one server.** Every moving part is one César can inspect over SSH
  (`docker ps`, `/etc/caddy/`, `journalctl`).
- **Secrets encrypted at rest:** AES-256-GCM with a master key in a root-only file
  (`/etc/kit-deploy/master.key`). **That key also goes into César's password manager**: without
  it, a database backup cannot decrypt a single variable.

## Proposed architecture

The kickoff may change any of it, with the reason written in a decision.

```
 GitHub (each project)
   push / PR ──► Actions: bun install, next build (output: standalone) with the environment's
                 NEXT_PUBLIC_* ──► image to ghcr.io (private) ──► POST kit-deploy /api/v1/deploy
                                                                       (KIT_DEPLOY_TOKEN, per repo)
 VPS
   Caddy :80/:443 ── *.preview.<domain> (wildcard, DNS-01) ── <domains of each project>
      │ reverse_proxy 127.0.0.1:<port>
      ├─► container <project>-prod-<sha>        (memory limit, non-root, restart unless-stopped)
      ├─► container <project>-pr-<n>
      └─► kit-deploy web (Next.js, unprivileged) ── unix socket ──► kit-agent (root, a fixed set
                │                                                   of operations: docker, caddy
                └── Postgres via PgBouncer (db kit_deploy)          reload, kit-db, cron)
   Postgres 17 + PgBouncer :6432 (as today) ◄── every container, same DATABASE_URL as on Vercel
```

| Decision | Why |
|---|---|
| **Build in GitHub Actions, push the image to GHCR** | A Next.js build takes 1–2 GB of RAM for a minute or two; on the VPS it competes with Postgres and the live sites. Private repos have Actions minutes on the free plan, and the logs come for free. The VPS pulls with a read-only token |
| **One image per environment** | `NEXT_PUBLIC_*` are inlined at build (Next.js docs, self-hosting): a preview image carries the preview's public values, so a preview cannot be "promoted" to production as on Vercel. Production is built from `main` with Production's values. The Action asks kit-deploy for the public variables of its environment; secrets never reach the Action |
| **Docker, one container per deployment** | Isolation and a memory limit per site, and the rollback is starting an image that is already there |
| **Caddy, with generated site files and `caddy reload`** | Automatic HTTPS and graceful reloads. One file per site in `/etc/caddy/sites/`, imported from the `Caddyfile`, rather than only the admin API: the config survives a reboot by itself and César can read it |
| **Wildcard certificate for previews through DNS-01** | Each preview with its own certificate would count against Let's Encrypt's weekly limit per domain and take seconds on every PR. A wildcard needs the DNS challenge: Caddy built with the provider's module (`caddy-dns/cloudflare`), and a Cloudflare token limited to DNS edit on that one zone |
| **kit-agent apart from the web app** | Whoever controls the Docker socket controls the server. The web app, exposed to the internet, never mounts it: it asks a small root process, over a local socket, for a closed list of operations with validated arguments |
| **A deploy token per repo, not a GitHub App** (v1) | One secret per repo (`gh secret set KIT_DEPLOY_TOKEN`) is enough for one person. Scoped to its project: it can deploy that project and read its public build variables, nothing else. v2 may move to a GitHub App for the PR comments |
| **Same `DATABASE_URL` as on Vercel** | Moving a project changes nothing in its code. The container resolves `db.<domain>` to the host (`--add-host db.<domain>:host-gateway`) so traffic does not leave the machine, and `sslmode=verify-full` still matches the certificate |
| **kit-deploy deploys itself by the simple path** | A platform that can only be repaired through itself cannot be repaired when it breaks: its own update is a script over SSH (pull, migrate, restart) that does not need the dashboard |

**Memory budget** (to confirm with `docker stats` in the first phase):

| What | RAM |
|---|---|
| Postgres (`shared_buffers` 2 GB + connections) + PgBouncer | ~2.5 GB |
| OS, Caddy, Docker, kit-deploy web + agent | ~1 GB |
| Production sites, 256–512 MB limit each | 6 sites ≈ 2.5 GB |
| Previews, 384 MB each, **at most 4 at once** (the oldest is stopped, and wakes on its next push) | ~1.5 GB |
| Swap file, 2–4 GB | a cushion, not capacity |

## Flows

1. **Production:** merge → the Action builds with Production's public variables → image
   `ghcr.io/<owner>/<repo>:<sha>` → `POST /deploy` → kit-agent pulls, starts the container with the
   runtime variables, waits for `/api/health`, rewrites the site file, `caddy reload`, stops the
   old one after the drain → the deployment is `ready` and the commit gets its status.
2. **Preview:** a PR is opened or pushed → the same with Preview's variables and `pr-<n>` → the PR
   comment with the URL is created or updated. PR closed → `DELETE /preview` from the Action's
   `closed` event, and a nightly sweep removes the previews of PRs that are no longer open.
3. **A variable changes:** saved encrypted → the page offers "Redeploy" (runtime variable: same
   image, new container) or "Rebuild" (`NEXT_PUBLIC_*`: it re-runs the Action with
   `workflow_dispatch`).
4. **Rollback:** pick a previous deployment → its image starts → the switch as in a deploy.
5. **Domain:** add it → DNS instructions → a check every minute until it resolves to the VPS →
   it goes into the site file → Caddy gets the certificate → `ready`.

## Traps known before starting

Each one with why it is here.

- **Docker publishes ports past ufw.** `-p 3000:3000` opens the port to the internet even with
  ufw denying it, because Docker writes its own iptables rules. Every container binds
  `127.0.0.1:<port>` only; the first phase tests from outside that no app port answers.
- **certbot standalone and Caddy both want port 80.** Once Caddy is listening, the renewal of
  `db.<domain>` fails without anyone noticing, and when that certificate expires every project
  with `sslmode=verify-full` loses its database at once. Before installing Caddy, the certificate
  moves to `webroot`: Caddy serves `http://db.<domain>` from `/var/www/acme`, then `certbot
  certonly --webroot -w /var/www/acme -d db.<domain> --cert-name db.<domain> -n` (which rewrites
  its renewal config) and `certbot renew --dry-run` must pass. The PgBouncer deploy hook stays.
- **`NEXT_PUBLIC_*` are frozen at build** (Next.js docs). A change of one needs a new image;
  only server variables can change with a restart.
- **The Server Actions key and the version skew.** For a few seconds the old and the new
  container both answer. Each project gets a stable `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY` (set by
  kit-deploy, secret) and `deploymentId` from the commit (`process.env.GIT_SHA`, next.config), as
  the Next.js self-hosting guide asks for more than one instance.
- **Docker's logs fill the disk.** The default `json-file` driver has no limit:
  `/etc/docker/daemon.json` with `"log-opts": {"max-size": "10m", "max-file": "3"}`, and the
  long-term logs in kit-deploy's own store with a retention.
- **Images pile up.** Keep the last 5 per project for rollback and prune the rest nightly; the
  disk is 100 GB and also holds the database dumps.
- **The OOM killer may pick Postgres.** The containers have hard memory limits (the OOM stays
  inside their cgroup), Node gets `--max-old-space-size` at ~75 % of its limit (set it, do not
  trust the default), and Postgres' unit gets `OOMScoreAdjust=-900`.
- **Previews get indexed and shared.** `noindex` and the login on every preview, from day one.
- **Email is not sent from the VPS.** A new IP has no reputation (`VPS-POSTGRES.md`); alerts and
  the apps' emails go through Brevo.
- **The Next.js cache lives in the container** and is lost on every deploy. With one instance per
  site that is the same as Vercel (it starts clean per deployment); a shared cache handler is only
  for v2 if a site runs more than one instance.

## Out of scope (v1)

More than one server, autoscaling, scale to zero (beyond stopping old previews), a global CDN
(Cloudflare's proxy in front stays possible per domain), builds on the VPS, WordPress (its
hosting stays as `tech/wordpress.md` says), billing, teams.

## Suggested phases

The kit's phases are written for a site from a design; this one is infrastructure first, with a
dashboard at the end. The kickoff turns this into its phase plan.

1. **Server ready:** certbot to webroot, Docker (with the log limits), Caddy with the DNS module,
   80/443 open, swap, the memory settings. A script in the kit (`reference/vps/`), tested in the
   kit's Docker test (`bootstrap.sh --test`) before it touches the VPS.
2. **One site by hand, end to end:** a throwaway Next.js app built in Actions, deployed by
   kit-agent through its CLI, with a domain and a rollback. Measure its RAM.
3. **Previews:** the Action, the wildcard, the PR comment, the teardown.
4. **Variables and databases:** encrypted storage, the per-environment sets, `env pull`, the
   automatic `DATABASE_URL`.
5. **The dashboard:** projects, deployments, variables, domains, logs, metrics. Built with the
   kit's own flow (Claude Design brief, frontend-build, a11y).
6. **Alerts and cron.**
7. **First real project:** a low-traffic one moves from Vercel (lowered DNS TTL the day before,
   Vercel kept for a week as the fallback).
8. **Back into the kit:** the workflow template and the Dockerfile in `reference/tech/vps-hosting/`,
   `tech/vps-hosting.md` turned from a contract into the guide, the kickoff option, and an
   `UPDATES.md` entry, sent as a PR to the kit (or with `/kit-feedback`).

## Done when

- [ ] A PR on a test project gets its preview URL in the PR in under 5 minutes, behind the
      login, and loses it when the PR closes.
- [ ] A merge deploys with no failed request during the switch (a load test during the deploy).
- [ ] A rollback takes under 30 s and needs no build.
- [ ] A variable can be set from the page and from `ssh kit-vps kit-deploy env set`, and is
      never readable afterwards if it is secret; `env pull` writes a working `.env.local`.
- [ ] A domain added from the page serves HTTPS with no manual step besides the DNS record.
- [ ] Rebooting the VPS brings every site back without touching anything.
- [ ] With kit-deploy stopped, every site still answers.
- [ ] `nmap` from outside sees only 22, 80, 443 and 6432.
- [ ] `certbot renew --dry-run` passes with Caddy running.
- [ ] The kit has the workflow template and its `UPDATES.md` entry.

## For César to decide at kickoff

- The name, and the domains: the dashboard (`deploy.<domain>`?) and the previews'
  (`*.preview.<domain>`).
- **The DNS of that domain on Cloudflare** (free plan): the wildcard needs a DNS provider with an
  API that Caddy supports. If it is elsewhere, either move it or choose a provider from
  `caddy-dns`.
- The alerts' channel: email (Brevo) or Telegram.
- The dashboard open on the internet behind its login, or only through a tunnel (Tailscale or
  `ssh -L`): the second is safer and worse for reviewing a preview from the phone.
- Which project moves first.
