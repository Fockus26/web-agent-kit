# Informe de feedback — proyecto world-flags — kit 3.9.0 — 2026-10-19

Stack: Astro 7 (isla React 19) · Supabase (auth + sync) · Bun · Windows 10

## `qa-local.ts` / `wave-qa`
- [Fricción ×2] Faltaba el Chromium de Playwright en la PC; `bunx` no estaba en el PATH y hubo que usar `node node_modules/@playwright/test/cli.js install chromium` → propuesta: que `qa:local` compruebe e instale el navegador al arrancar.
- [Bug ×1] Astro 7 lanza `astro dev` como demonio: `qa:local` sale enseguida con 0, el servidor queda huérfano, `taskkill /T` no lo apaga (hace falta `astro dev stop`) y murió a mitad de la QA sin log → propuesta: con Astro ≥ 7 arrancarlo en primer plano o mandar `astro dev stop` al salir; documentar cómo apagarlo.
- [Hueco ×1] Con el `config.toml` por defecto de `supabase init`, `supabase start` y `db reset` fallan en una PC lenta (vence el chequeo de salud de 2 min de db, Studio/pg-meta y analytics); hubo que apagar Studio y analytics y subir `health_timeout` a 5m → propuesta: `config.toml` mínimo para QA (Studio y analytics apagados, `health_timeout = "5m"`) y aviso en `qa-local.ts` de que el primer arranque tarda minutos.

## Flujo de PR (`git-flow` / `orchestrate`)
- [Fricción ×1] El dueño mergeó un PR mientras se subía su segundo commit, nacido de la QA, y el commit se quedó fuera → propuesta: si la QA se hace con los PRs abiertos, pasarlos a borrador (`gh pr ready --undo`) hasta cerrarla, o avisar en el PR de que la QA sigue en curso.
  Evidencia: Fockus26/world-flags#95 → Fockus26/world-flags#100
- [Hueco ×1] En una máquina nueva falta todo lo que el kit da por hecho (`bun`, `gh`, agentes `feature-worker`/`wave-qa`, `wt.ps1`, `context/` local) y CLAUDE.md cita la ruta de otra PC → propuesta: chequeo de entorno al arrancar (`/kit-doctor` o paso 0 de `orchestrate`) que diga qué falta y cómo instalarlo, y sugerir `context:restore` si falta `CURRENT_PHASE.md`.

## Plantilla de CLAUDE.md (worktrees de sesión)
- [Fricción ×1] Un hook impide que una sesión en `.claude/worktrees/…` escriba en el `context/` local de la carpeta principal, pero CLAUDE.md dice que `context/` se actualiza ahí → propuesta: que CLAUDE.md diga que desde un worktree se devuelve el bloque para `context/` en el informe (o que el hook permita `context/`, que está gitignored).

## `new-project.ps1 -Existing` (piece check de `kit-update`)
- [Fricción ×1] Asume Next: añadiría `typecheck` con `next typegen`, copia `phases/` y reformatea `package.json` entero; en un proyecto Astro se aplicó a mano → propuesta: detectar el framework y saltar `typecheck`/`phases/`, o que el piece check diga qué aplicar a mano.

## UPDATES.md 3.8.0 (paso 4, `supabase/` en git)
- [Hueco ×1] No dice qué hacer con un `.gitignore` que ignora `/supabase/*` ni con decisiones previas que lo fijaron → propuesta: mencionar que hay que abrir una decisión nueva que reemplace la anterior.

## Lo que funcionó bien y no hay que tocar
- `qa:local` contra Supabase en Docker con cuentas de prueba: una vez arrancado, la QA dejó de tocar la base real.
- El pool de worktrees con `.env*` copiados permitió trabajar en paralelo sin pisarse.
