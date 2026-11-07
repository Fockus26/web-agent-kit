# Informe de feedback — proyecto world-flags — kit 3.15.0 — 2026-11-04

Stack: Astro 7 + React 19 (PWA con SW propio) · Postgres en VPS con Drizzle y Better Auth (migrado desde Supabase) · Bun · Windows

Todos los puntos llevan ×1, así que dentro de cada pieza van en orden de fecha. Las piezas van de más a menos puntos.

## `reference/MIGRATE-TO-VPS.md`

- [Hueco ×1] La guía da por hecho Next con servidor; un Astro estático no tiene dónde poner las rutas, y su SW empieza a interceptar `/api` al dejar de ser otro origen → propuesta: sección para apps estáticas/PWA con adaptador, `/api` excluido del SW e identidad sin red con cookie httpOnly.
- [Hueco ×1] §5 pone el corte tras el merge, pero el merge ya despliega; y pausar el proyecto viejo no avisa a clientes con bundle viejo si la versión mínima vive en él → propuesta: merge dentro de la ventana de corte y proyecto viejo activo sin escritura hasta que no queden clientes.
- [Hueco ×1] §1, junto con `VPS-POSTGRES.md`: propone Vercel Cron como sustituto de `pg_cron` sin hablar del límite de frecuencia por plan, usa la misma URL de base en preview y producción, deja la región por defecto de Vercel lejos del VPS, y `vps:env` escribe en `.env.local`, que CLAUDE.md prohíbe editar → propuesta: temporizador en el VPS, base aparte para previews, región de funciones fijada y `vps:env` a `.env.development.local`.
- [Hueco ×1] §5: el PR de la migración se mergeó antes del corte, porque solo lo impedía un aviso en su descripción, y la API de producción dio 500 unos 40 min → propuesta: abrir el PR como borrador hasta tener variables, migraciones y datos listos.
  Evidencia: Fockus26/world-flags#133
- [Hueco ×1] Falta una lista corta y ordenada de lo que hace el dueño y lo que hace el agente; aquí hubo que descubrirla sobre la marcha → propuesta: añadir como checklist la lista del anexo.

## `reference/DEPLOY.md`

- [Fricción ×1] `vercel link` añade `.env*` al `.gitignore`, lo que ignoraría `.env.example`, y reescribe `.env.local` → propuesta: avisarlo y revisar `git status` tras enlazar.
- [Hueco ×1] §2c no dice qué variable va en cada entorno de Vercel tras migrar (base y secretos solo en Production, previews sin base o con la suya) → propuesta: tabla de variables por entorno.

## `reference/scripts/qa-local.ts`

- [Corrección ×1] 3.15.0, `warmUp`: espera solo a `127.0.0.1`, pero Astro 7 escucha solo en `[::1]`, así que agota sus 10 min antes de precalentar y `QA ready` sale a los 10 min → propuesta: `answers("127.0.0.1") || answers("::1")`, como en `taken`. Arreglado en world-flags: `QA ready` en 21 s.
- [Hueco ×1] No hay modo para `@astrojs/vercel` que sirva `.vercel/output` con `NODE_ENV=production`, y sin él no se prueban el SW ni el límite de intentos. Además, si `astro dev` no escucha en 10 min, el alta de cuentas lanza sin capturar y lo deja huérfano → propuesta: modo de build real y capturar ese fallo. Hay un punto de partida en world-flags, `.qa/fqa-prod.mjs` (local, sin versionar; se puede pasar si hace falta).

## `UPDATES.md`

- [Hueco ×1] 3.15.0, paso 5: reemplaza la línea "Size budgets…" por la de `kit-reference`, pero no dice qué hacer en un proyecto que nunca tuvo esa línea (anterior a 3.14). Con CLAUDE.md al tope, no se añadió → propuesta: que el paso lo diga, por ejemplo "si falta, no se añade".

## `new-project.ps1 -OnlyPieces`

- [Fricción ×1] Con un `.claude/` que ignoraba todo, añadió `.claude/worktrees/` al final (redundante) en vez de sustituir la regla, y la copia del kit quedaba ignorada; hubo que hacerlo a mano (paso 3 de 3.10.0) → propuesta: detectar la regla `.claude/` y cambiarla por `.claude/worktrees/` + `.claude/settings.local.json`.

## `reference/QA-PREVENTION.md`

- [Hueco ×1] La QA de la migración encontró cinco fallos evitables con una línea de guía cada uno → propuesta: añadirlos:
  - SW viejo que intercepta rutas nuevas del mismo origen.
  - `pg.Pool` sin `on("error")`.
  - Cambios de sesión por cookie no anunciados entre pestañas.
  - `Date.parse` más laxo que Postgres.
  - Llamadas a terceros sin timeout en un cron.

## `project-kickoff` y `reference/VPS-POSTGRES.md`

- [Hueco ×1] El dueño no quiere solo migrar: quiere que un proyecto nuevo pueda nacer con la base en el VPS, sin pasar por Supabase → propuesta: opción de arranque con Postgres en el VPS, Drizzle y Better Auth desde el primer día.

## Lo que funcionó bien y no hay que tocar

- `decisions/` con un archivo por decisión: se encuentra con `grep` sin cargar un índice.
- Changesets escritos a mano: el PR de versión y "Novedades" salen sin que ningún agente toque la versión.

## Anexo: pasos reales de la migración (para el checklist)

**Antes de tocar nada, el dueño decide y prepara:**

1. Backblaze: bucket privado, clave limitada a ese bucket y regla de ciclo de vida.
2. En su terminal, `rclone config` por SSH en el VPS (las claves nunca en el chat).
3. Brevo: remitente verificado, login y clave SMTP. `SMTP_USER`, `SMTP_PASS` y `SMTP_FROM` en Vercel.
4. Google: proyecto y cliente OAuth con la URI `/api/auth/callback/google`; hace falta URL de privacidad para publicar. `GOOGLE_*` en Vercel.
5. Autorizar lectura de la base vieja, y secretos y despliegue en Vercel (los permisos automáticos los bloquean sin autorización expresa).

**El agente desarrolla (rama + PR en borrador hasta el corte):**

6. Inspeccionar la base real solo con lectura: políticas, columnas, trabajos de cron y migraciones aplicadas.
7. Adaptador de servidor y rutas `/api/*` en la misma región que el VPS; excluir `/api/` del SW.
8. Esquema Drizzle, Better Auth (bcrypt para contraseñas importadas) y correo por SMTP.
9. Una prueba de acceso por cada política de RLS.
10. Identidad sin red (la cookie httpOnly no se lee) y cambio de sesión avisado entre pestañas.
11. Script de importación todo o nada, que compara contenido; ensayarlo en una base temporal.
12. QA funcional sobre el build real, no solo en dev; también con el SW anterior instalado.
13. Temporizador en el VPS con `Content-Type` (sin él, Astro responde 403). Copias: `KIT_BACKUP_REMOTE`, y probar una restauración.

**Corte, en este orden:**

14. Variables de producción en Vercel (`vercel link` toca `.gitignore`: revisar `git status`).
15. `db:migrate` por túnel, importar y comprobar conteos.
16. Pasar el PR a listo y mergear: despliega.
17. Comprobar API, cron con secreto y errores en Vercel. El dueño prueba login, Google, correo y push.
18. Comparar la base vieja con la nueva antes de borrarla. Borrarla es acción del dueño.
