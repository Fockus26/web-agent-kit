# Informe de feedback — proyecto kit-deploy — kit 3.22.0 — 2026-11-18

Stack: Next.js 16 App Router + daemon y CLI en TypeScript (`bun build --compile`) · Postgres (kit-db) + Drizzle · Better Auth · bun 1.4 · Windows 10 (desarrollo) + VPS Linux

## `security-review` skill (uso desde un slot del pool)
- [Fricción ×8] Toma `git status`/`git diff` de la carpeta principal (vacía) en vez del slot del worker; cada worker tuvo que pasarle el diff a mano → propuesta: aceptar una ruta o rama como argumento, o usar el cwd del worktree.
  Evidencia: unidades de la fase 05 (Fockus26/kit-deploy#49 a Fockus26/kit-deploy#61)

## `orchestrate` skill (y su plantilla de brief)
- [Fricción ×2] › mensaje de reanudación tras un corte de API: citaba `.qa/progress.md`, que ningún worker había escrito, y adivinaba el paso por la última línea (W3, W4) → propuesta: reanudar con "`git status` + `git log` son la verdad"; el brief pide `.qa/progress.md` desde el primer commit wip.
- [Fricción ×2] › Playwright y builds con 4 slots: `next build` se colgó dos veces con 4 slots ocupados (W10) y Playwright sobre `next dev` se colgó en `load` (W11) → propuesta: correr flujos/guards sobre `--preview` desde el primer intento; el orquestador hace un build por ola y los workers confían en CI. `[Tech: next]`
  Evidencia: Fockus26/kit-deploy#52, Fockus26/kit-deploy#54
- [Corrección ×1] › regla de rebase del brief: permitía `--force-with-lease` sobre la rama del worker; el modo auto lo niega, CLAUDE.md lo prohíbe, y el PR rebaseado quedó en conflicto (se republicó en otra rama) → propuesta: actualizar ramas con `git merge origin/main` + push normal; nunca un rebase que necesite force-push.
- [Hueco ×1] › arranque de una fase de UI sin `design/HANDOFF.md`: la skill mapeó y lanzó unidades de UI sin handoff; César tuvo que parar la ola para decidir el diseño → propuesta: antes del §0 de una fase de UI, comprobar que existe `design/HANDOFF.md`; si no, parar y ofrecer Claude Design / canvas de diseño en la sesión / construir desde el brief.
- [Hueco ×1] › §4 reserva de IDs de decisión: los IDs reservados para W14 (D047–D048) los tomó entretanto otra sesión que trabajaba en la carpeta principal; el worker renumeró → propuesta: reservar contra origin/main **y** los PRs abiertos / otras sesiones vivas, o que el worker tome "el siguiente libre tras mergear main" y lo reporte.
  Evidencia: Fockus26/kit-deploy#61
- [Hueco ×1] › números de migración reservados: regenerar una migración para renumerarla borra el SQL escrito a mano (el `UPDATE` de W4) → propuesta: el brief dice guardar aparte el SQL manual y re-añadirlo después de `db:generate`. `[Tech: drizzle]`
  Evidencia: Fockus26/kit-deploy#47
- [Hueco ×1] › ola de páginas de UI en Windows: cada unidad iba a reescribir un kit-agent falso; los unix sockets dan EACCES en Windows (W10 usó una named pipe) → propuesta: un `scripts/qa-fake-agent.ts` compartido sobre named pipe, planificado en la ola de componentes. (Propio de un proyecto con daemon local; quizá solo como nota.)
- [Hueco ×1] › plan de ola con unidades de página en paralelo: dos unidades añadieron cada una `components/ui/native-select.tsx` (W10, W11) → conflicto → propuesta: listar las primitivas compartidas que necesita la ola y dárselas a una sola unidad (o a la ola de componentes).
- [Fricción ×1] › prompt de unidad para trabajo de daemon: el prompt de W2 proponía un hijo `docker logs -f` de larga vida por contenedor, ignorando el `MemoryMax=256M` de la unidad systemd (el worker cambió a la API de Docker) → propuesta: en unidades de daemon, revisar los límites del cgroup antes de proponer procesos hijos de larga vida.
- [Fricción ×1] › regla 10 del brief (edición de archivos): `python -` con heredoc entre comillas igual convirtió `\n` en salto de línea en la herramienta Bash; dos parches fallaron en silencio y uno rompió un string de test → propuesta: regla 10: nada de heredoc `python -` para texto con barras invertidas — Edit, o un script en `.qa/`.

## Plantillas de Biome (`biome.json` del kit › `files.includes`)
- [Fricción ×2] `!**/.claude/worktrees` también casa con la raíz del worktree, así que `bun run lint` dentro de un slot ignora todos los archivos y sale con 1 → propuesta: excluir los worktrees relativo a la raíz (`!.claude/worktrees`) o documentar `--config-path` para los slots.

## `scripts/pr-screenshots.ts`
- [Hueco ×2] No tiene opción de `storageState`/cookie: las pantallas con sesión no se pueden capturar, y el PR de W1 salió sin imágenes → propuesta: un campo `storageState` por captura (o uno global).
  Evidencia: Fockus26/kit-deploy#49

## `project-kickoff` skill
- [Hueco ×1] › tracks de fases: ningún track sirve para un proyecto que empieza por infraestructura (servidor, agente, CLI y después un dashboard); se improvisó uno → propuesta: añadir un track "Infra": fases propias primero y las fases de UI anidadas en una fase "Dashboard".
- [Repetición ×1] › Bloque C, personalidad: César pidió *ver* las direcciones en vez de leerlas, y luego una mezcla y variaciones → propuesta: renderizar las 3 direcciones como un canvas de Design rápido (la misma pantalla en cada una) antes de pedirle que elija.

## `new-project.ps1` y `scripts/qa-local.ts`
- [Fricción ×1] Un proyecto recién creado falla `typecheck` (`env.NODE_ENV = …` es de solo lectura con los tipos de Next 16, `qa-local.ts:552`) y `lint` (tsconfig.json queda con CRLF) → propuesta: `Object.assign(env, { NODE_ENV: "production" })` en el kit; correr `biome format --write` al final de `new-project.ps1`.
- [Fricción ×1] `qa-local.ts` › Postgres: llama a `bun run db:migrate`, que un proyecto Drizzle sin los scripts del kit puede no tener; además el primer `initdb` en un HDD superó su espera de arranque → propuesta: comprobar que el script existe y decir cuál añadir; esperar más (o sondear `pg_isready`) en el primer arranque del contenedor.

## `reference/vps/` (`bootstrap.sh`, `kit-db`, VPS-POSTGRES.md)
- [Hueco ×1] `bootstrap.sh`: deja `db.<dominio>` con certbot standalone; cualquier servidor web posterior en :80 rompe su renovación en silencio y cada proyecto lo resuelve solo → propuesta: emitir por webroot desde el primer día (`/var/www/acme`), o incluir la migración standalone→webroot que escribió kit-deploy.
- [Hueco ×1] `kit-db create`: su camino de reintento reutiliza un rol existente sin base y le resetea la contraseña (`ALTER ROLE … PASSWORD`): quien pueda correr `kit-db create` puede romper un rol que kit-db no creó (hallazgo de la revisión de seguridad) → propuesta: reutilizar solo roles para los que kit-db tiene `dbs/<nombre>.env`; rechazar cualquier otro rol existente.
  Evidencia: Fockus26/kit-deploy#37

## Documentación y scripts para César en Windows
- [Hueco ×1] `bash scripts/ship.sh …` desde PowerShell ejecutó el bash.exe de WSL (sin distro: `execvpe(/bin/bash) failed`); César tuvo que preguntar → propuesta: dar los comandos como `& "C:\Program Files\Git\bin\bash.exe" …` (o "abre Git Bash"), o incluir un wrapper `.ps1`.

## Lo que funcionó bien y no hay que tocar
- Las olas con pool de slots y PR por unidad: 14 unidades de la fase 05 en paralelo con conflictos acotados y revisables.
- El registro de KIT_FEEDBACK con "Veces": los ×8 y ×2 dejan claro qué arreglar primero.
- `qa:local` con Postgres en Docker y cuentas de `.env.test.local`: QA sin tocar la base real.
