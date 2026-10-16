# Actualizaciones del kit — versiones y camino de migración

Cada proyecto guarda en **`.kit-version`** (raíz del repo, en git, una línea) la versión del
kit con la que quedó alineado. La versión actual del kit está en [`VERSION`](./VERSION).

Para actualizar un proyecto no se elige a mano qué migración correr: en una sesión abierta
en el proyecto, la skill [`kit-update`](./.claude/skills/kit-update/SKILL.md)
(`/kit-update`). Compara `.kit-version` con la versión publicada del kit (`origin/main`),
calcula el camino (todas las versiones posteriores, en orden) y aplica cada paso de esta
lista en una sola rama, un commit por versión.

---

## Cómo saber la versión de un proyecto sin `.kit-version`

Los proyectos anteriores a la 3.3.0 no tienen el archivo. Se deduce por señales, de la más
nueva a la más vieja (la primera que se cumple gana):

| Si el proyecto… | Está en |
|---|---|
| tiene `context/decisions/D0NN-*.md` (un archivo por decisión) y no `context/DECISIONS_INDEX.md` | **3.2.0** |
| `CLAUDE.md` habla del pool de worktrees (`..\<repo>-wt`, `wt take`) | **3.1.0** |
| tiene `context/PHASE_LOG/` y `context/CURRENT_PHASE.md` | **3.0.0** |
| no tiene `context/PHASE_LOG/` | **2.x o anterior**: no hay camino automático. `nuevo-proyecto.ps1 -Existente` añade lo que falte sin pisar nada y se sigue desde 3.0.0 |

Las señales no dependen de Changesets a propósito: un proyecto **sin versión** (creado con
`-SinVersion`, o su `CLAUDE.md` lo dice) no tiene `.changeset/` ni `release.yml` y no por eso
es más viejo. En ese proyecto, los pasos de Changesets de cualquier versión se saltan: no
son una migración pendiente. Si las señales se contradicen, el agente las enseña y pregunta
antes de elegir.

---

## 3.7.0 — 2026-10-16 · Feedback de inversiones-js, Melao, Maranatha y World Flags

**Qué cambió** (cada punto, con el incidente que lo motivó, en la pieza que lo cambia)

- **Brief de la tanda y `feature-worker`**: reglas de entorno que los workers
  redescubrían. Archivos con Write/Edit, no por shell (heredoc, `node -e` con backticks y
  Python en Windows rompieron archivos 6 veces). Suite completa sola, en segundo plano y a
  archivo (Bun se colgaba o PGlite agotaba la memoria con varios workers). Servidor: puerto
  libre o nada, parar por PID con el árbol, nunca `<framework> stop`; `.next/dev` ante el
  500 de Turbopack. Scripts de Playwright en `.qa/` del slot (desde el scratchpad no
  encuentran el paquete). Esperas en segundo plano (`sleep` está bloqueado). Commit por
  etapa y `git status` al retomar tras un 429. `test:related` con respaldo a `bun test`.
- **`orchestrate`**: mapea y reserva números contra `origin/main` (se reservó una D que ya
  existía y se pidió una migración ya aplicada); compara los valores pedidos con la
  decisión implementada, mira si hay entorno de test de DOM y abre la imagen antes de
  proponer su alt. Rango opcional de códigos de error propios. Sin base local, la ola
  cierra con QA de invitado (`--offline`) en vez de quedarse bloqueada. La plantilla de
  prompt sugiere medir antes/después en `main` y en la rama para los arreglos.
- **`wt.ps1`**: `take` y `free` paran lo que siga escuchando en el puerto del slot
  (servidores huérfanos que hacían saltar al siguiente de puerto); `.qa/` queda ignorado en
  todos los slots (`.git/info/exclude`).
- **`qa-local.ts`**: `--offline` (sin base: variables a una dirección muerta, solo
  invitado); aborta si el puerto está ocupado (también solo en IPv6); en Windows mata el
  árbol del servidor; todo error termina el proceso con mensaje. `MAPEO` cubre `PUBLIC_*` y
  `VITE_*`. Roles por lista en una variable (`ROL_POR_ENV`, p. ej. `ADMIN_EMAILS`) y ejemplo
  de acceso por suscripción en `asignarRol`.
- **`publish-pr-shots.sh`** deja el markdown también en `.pr-shots/README.md` (un `tail`
  lo cortaba). `git-flow`: reescribir `.pr-shots.json` en cada unidad (se publicaron
  capturas ajenas), el campo es `base`, `shots:publish` en segundo plano.
- **`nuevo-proyecto.ps1`**: `@axe-core/playwright` como devDependency (un worker no puede
  añadirla y acababa cargando axe de un CDN); `.claude/worktrees/` fuera de git y de Biome
  (el worktree de Claude Desktop traía otro `biome.json` y rompía el lint).
- **`kit-update`**: revisión de piezas aunque la versión esté al día (un proyecto en 3.5.0
  no tenía `test:related` ni `shots`); las añade con `nuevo-proyecto.ps1 -Existente`.
- **Sin versión** es un camino oficial: línea en `CLAUDE.md`, `git-flow` sin changeset, y la
  tabla de deducción ya no usa Changesets como señal.
- **Correos**: proveedor de envío por defecto (Brevo por SMTP) en una decisión y pregunta
  en el arranque; sin SMTP propio Supabase solo entrega al equipo. Firebase Auth: comprobar
  antes de diseñar si la consola deja editar las plantillas; si no, envío propio con el
  Admin SDK.
- **Diseño**: barra de scroll (tokens `scrollbar`, ≥ 3:1) junto a `::selection` en brief,
  handoff, adenda, `COLORS.md`, fase 02 y `design-qa`. Logo provisional que se cambia por
  el real sin rehacer icono ni OG (`BRAND-ASSETS.md` y adenda).
- **Skills**: `frontend-build` (un módulo `'use client'` solo exporta componentes), `a11y`
  (foco por estado, no por `useRef` de montaje, por StrictMode), `seo` (headings contados
  sobre el DOM por nombre accesible, no con grep). `DEPLOY.md`: adoptar un proyecto de
  Vercel ya creado. Migración 3.2.0: secciones de decisiones agrupadas.
- **Al publicar una versión**: cada paso dice qué párrafo de `CLAUDE.md` sustituye, y qué
  hacer si falta el archivo que edita.

**Pasos para un proyecto en 3.6.0**

1. Piezas globales: `powershell -ExecutionPolicy Bypass -File <kit>\instalar-kit.ps1 -Pull`
   y sesión nueva (cambian `orchestrate` y su `wt.ps1`, `git-flow`, `a11y`, `seo`,
   `frontend-build`, `backend-build`, `project-kickoff`, `kit-update`, y los agentes
   `feature-worker`, `wave-qa` y `design-qa`). Si actualiza `kit-update`, ya está hecho.
2. **Revisión de piezas** de `kit-update` (axe como devDependency, `.claude/worktrees/` en
   `.gitignore` y `biome.json`, scripts del kit): lo que falte, con
   `nuevo-proyecto.ps1 -Ruta . -Existente`.
3. `scripts/publish-pr-shots.sh` ← `<kit>\reference\qa-scripts\publish-pr-shots.sh` (no
   tiene partes propias del proyecto).
4. `scripts/qa-local.ts`: tiene partes propias (lo añadido a `MAPEO`, `asignarRol`). Copia
   el del kit y vuelve a poner encima esas partes del proyecto (`git diff` del archivo para
   verlas). Si el rol se decide por una lista en una variable, pásalo a `ROL_POR_ENV`.
   Verifica: `bun run qa:local -- --port 4399 --offline` arranca y el sitio carga.
5. `CLAUDE.md`: solo si el proyecto es **sin versión**, su línea "Versión" pasa a la
   alternativa "sin versión" de `<kit>\CLAUDE.md.template` (sustituye, no suma).
6. `context/COLORS.md`: filas `scrollbar.thumb / scrollbar.track` en claro y oscuro. Si el
   archivo no existe, créalo solo con esas filas y `selection`. Si el layout base ya está
   hecho y el diseño no trae la barra: el bloque "Barra de scroll" de la adenda a César y la
   unidad (tokens + CSS) a `context/plans/pendientes.md`; no se implementa en este PR.
7. **Diagnóstico** (sin cambiar nada): si la app manda correos y no hay decisión del
   proveedor de envío (`grep -rli "smtp\|brevo\|resend" context/decisions/`), pregunta cuál
   es y regístrala. Con Firebase Auth, acción de César: comprobar si la consola deja editar
   las plantillas. Si el sitio está en Vercel sin `.vercel/project.json`, acción:
   `reference/DEPLOY.md` § 2b.

---

## 3.6.0 — 2026-10-16 · Skills `kit-update` y `kit-feedback`

**Qué cambió**

- **`kit-update`** sustituye a `prompts/ACTUALIZAR-KIT.md` (que queda como aviso). Compara
  tres versiones: la del proyecto (`.kit-version`), la de las skills instaladas y la
  publicada (`origin/main` del clon del kit, tras `git fetch`). Si coinciden, dice que está
  al día y termina; si las skills instaladas están viejas, las reinstala y pide sesión nueva
  (antes se migraba con las skills viejas cargadas); si el proyecto va atrás, aplica el
  camino como hacía el prompt. Lee el kit siempre como está en `origin/main`, aunque el clon
  esté en otra rama. Por qué: el prompt pedía copiar skills a mano, cambiar la ruta en el
  bloque y pegarlo, y no avisaba si el proyecto ya estaba al día.
- **`kit-feedback`** envía `context/KIT_FEEDBACK.md` como un PR en el repo del kit
  (`feedback/<fecha>-<proyecto>.md`, etiqueta `kit-feedback`) con `gh api`, sin clonar. En el
  kit, "revisa el feedback" hace un triaje consolidado de todos los PRs abiertos (ver
  `CLAUDE.md` del kit). Por qué: los informes pegados en el chat llegaban de uno en uno y se
  perdían; lo que se repetía entre proyectos no se veía.
- **`instalar-kit`** escribe `~/.claude/web-agent-kit.json` (ruta del clon y versión
  instalada), que es lo que lee `kit-update`.

**Pasos para un proyecto en 3.5.0**

1. Piezas globales: `powershell -ExecutionPolicy Bypass -File <kit>\instalar-kit.ps1 -Pull`
   y sesión nueva (skills nuevas, y el instalador deja `web-agent-kit.json`). Si la
   actualización la hace `kit-update`, este paso ya está hecho.
2. `CLAUDE.md` del proyecto, desde `<kit>\CLAUDE.md.template`: la línea **Kit:** (se
   actualiza con `/kit-update`) y la última frase de "Feedback para el kit" (se envía con
   `/kit-feedback`). Sustituyen a las de antes; el tamaño no cambia.
3. `context/KIT_FEEDBACK.md` (local): la sección "Informe para el kit" se sustituye por
   "Enviarlo al kit" de `<kit>\context-templates\KIT_FEEDBACK.md`, y la frase en negrita de
   "Si ya existe una fila…". Las filas marcadas `→ informe <fecha>` cuentan como enviadas.
4. `phases/09-QA-FINAL.md`, si existe y la fase 09 no está cerrada: la casilla "Feedback
   para el kit" de `<kit>\phases-templates\09-QA-FINAL.md`.

---

## 3.5.0 — 2026-10-02 · Plantillas de correo en el diseño

**Qué cambió**

- **Los correos que manda la app se diseñan con el sitio.** El arranque deduce la lista
  (confirmar cuenta, recuperar contraseña, transaccionales, acuse y aviso del formulario…) y
  la cierra en el plan (6e) y en `PROJECT_CONTEXT.md` § "Correos"; el brief la pide en §7
  con las restricciones del medio (600 px, tipografía de respaldo, imágenes bloqueadas, modo
  oscuro forzado) y el handoff la devuelve en § 5c. Por qué: sin diseño, el backend mandaba
  la plantilla por defecto del proveedor (en inglés, sin marca) o inventaba una en la fase 07.
- **Implementación en la fase 07** (`backend-build`): una plantilla base compartida, React
  Email para los correos de la app (HTML + texto plano), y los de auth en
  `supabase/templates/` + `config.toml`, así la base local los manda con el diseño real a
  Mailpit. Guía: `reference/EMAIL-TEMPLATES.md`.
- La adenda para Claude Design tiene un bloque de correos.

**Pasos para un proyecto en 3.4.0**

1. Piezas globales: `powershell -ExecutionPolicy Bypass -File <kit>\instalar-kit.ps1` y
   sesión nueva (`project-kickoff` y `backend-build` cambiaron).
2. **Diagnóstico** (sin cambiar nada): qué correos manda ya la app
   (`grep -rniE "resend|sendmail|nodemailer|postmark|emails\.send|resetPasswordForEmail|signUp|signInWithOtp|inviteUserByEmail" --include=*.ts --include=*.tsx app src lib`),
   si existen `emails/` y `supabase/templates/`, y si `design/HANDOFF.md` tiene correos.
   Si la app no manda ninguno ni lo hará, `PROJECT_CONTEXT.md` § "Correos" = "No aplica" y
   termina aquí.
3. `context/PROJECT_CONTEXT.md`: la sección "Correos" de
   `<kit>\context-templates\PROJECT_CONTEXT.md`, llena con el diagnóstico (y la casilla
   "Correos que manda la app" en "Funcionalidad").
4. **Lo que falta de diseño no se implementa en este PR.** Se le entrega a César el bloque
   "Plantillas de correo" de `<kit>\prompts\CLAUDE-DESIGN-ADENDA.template.md`, lleno con la
   lista, y los correos van a `context/plans/pendientes.md` como unidades de la fase 07 (la
   plantilla base + auth primero).
5. Si el proyecto está en la fase 07 o ya la pasó, esas unidades siguen
   `reference/EMAIL-TEMPLATES.md` cuando vuelva el diseño. Copy que falte: filas en
   `CONTENT_CHECKLIST.md`.

---

## 3.4.0 — 2026-10-02 · QA de ola contra base local, fases en olas, una ola por sesión

**Qué cambió**

- **Agente nuevo `wave-qa`.** Cuando todos los PRs de una ola están mergeados, `orchestrate`
  lo lanza en un slot del pool sobre `main`: levanta el servidor, recorre los flujos de la
  ola (y las costuras entre PRs) con sesión iniciada, por rol, y devuelve hallazgos
  reproducibles. Lo crítico y lo alto pasa a la ola siguiente. Por qué: cada worker probaba
  su unidad como invitado y en su rama; nadie probaba las unidades juntas ni con login.
- **QA contra base local.** `scripts/qa-local.ts` (`bun run qa:local -- --port <p>`) levanta
  Supabase en Docker, aplica migraciones + seed, crea las cuentas de prueba y arranca el
  servidor con las variables de Supabase apuntando a lo local (por `process.env`, sin
  escribir archivos). Aborta si alguna variable sigue apuntando a `*.supabase.co`. Por qué:
  probar con datos reales contra la base de producción arriesga datos de clientes; en local
  la QA puede crear y romper lo que quiera.
- **Cuentas de prueba** en `.env.test.local`, una pareja por rol: `EMAIL_TEST`/`PASSWORD_TEST`,
  `ADMIN_EMAIL_TEST`/`ADMIN_PASSWORD_TEST`, `<ROL>_EMAIL_TEST`/`<ROL>_PASSWORD_TEST`. Solo
  existen en la base local (el script las crea en cada corrida); los valores no pasan por el
  contexto del agente (`node --env-file=.env.test.local`). Solo un servicio externo sin
  equivalente local se prueba en remoto, con datos marcados, registrados y borrados.
  `functional-qa` sigue las mismas reglas y ahora levanta su propio servidor.
- **`backend-build`**: todo el esquema como migraciones en `supabase/migrations/`, un
  `seed.sql` mínimo, y las cuentas de prueba como acción de César.
- **Fases en olas, una ola por sesión.** `orchestrate` puede partir una fase en olas
  (`context/plans/fase-0N-<nombre>.md`, plantilla `fase-plan-template.md`). Cada ola cierra
  con: fase, ola cerrada, resultado de la QA, qué sigue; y con "inicia la ola en otra sesión"
  abre una sesión nueva con el prompt de arranque (o lo da para pegar). Por qué: una sesión
  que encadena olas arrastra el mapeo y los informes de todas en cada mensaje.
- **`instalar-kit.ps1` / `instalar-kit.sh`**: instalan o reinstalan skills y agentes
  (`-Pull` / `--pull` hace `git pull` antes).

**Pasos para un proyecto en 3.3.0**

1. Piezas globales: `powershell -ExecutionPolicy Bypass -File <kit>\instalar-kit.ps1` y
   sesión nueva, o `wave-qa` no existe ("Agent type not found").
2. `scripts/qa-local.ts` desde `<kit>\reference\qa-scripts\`, y en `package.json` el script
   `"qa:local": "node scripts/qa-local.ts"`.
3. `.gitignore`: comprueba que cubre `.env.test.local` (`git check-ignore .env.test.local`);
   si no, añade `.env*.local`.
4. `CLAUDE.md` del proyecto, desde `<kit>\CLAUDE.md.template`: el párrafo "Servidor de
   desarrollo", el de "QA contra base local" debajo, y las filas de `orchestrate` y `wave-qa`
   de "Puertas de calidad". Tope 8 KB.
5. `context/CURRENT_PHASE.md`: la línea **Ola** bajo "Fase" (o nada si no se usan olas).
6. **Si el proyecto usa Supabase:** que exista `supabase/config.toml` y que las migraciones
   reproduzcan el esquema de producción. Si el esquema se hizo en el dashboard, sácalo con
   `supabase db pull` (proyecto enlazado) a una migración, y un `supabase/seed.sql` mínimo
   sin datos personales. Adapta en `scripts/qa-local.ts` `MAPEO` (si la app usa variables
   con otros nombres) y `asignarRol` (si el rol no vive en `app_metadata.role`). Verifica
   con `bun run qa:local -- --port 4399` (Docker Desktop abierto): arranca y el sitio carga.
7. **Si el proyecto tiene login:** en `.env.example`, bajo `# QA → .env.test.local`, las
   parejas `*_EMAIL_TEST` / `*_PASSWORD_TEST` vacías, una por rol que exista en el código
   (búscalos: `grep -rniE "role|rol|isAdmin" --include=*.ts --include=*.tsx src app lib`).
   **Acción de César** en el PR: rellenar `.env.test.local` (valores inventados: solo
   existen en la base local).
8. Si hay una tanda en curso, termina con el flujo viejo; la siguiente ya cierra con
   `wave-qa`.

---

## 3.3.0 — 2026-10-01 · Estados, assets de marca, repo y despliegue, feedback

**Qué cambió**

- **Pantallas de estado** como parte del diseño y de la fase 06: 404 (con sesión / invitado,
  solo si hay auth), 500 (con / sin código), sin conexión, error según la red, mantenimiento
  (con / sin hora). Guía: `reference/STATUS-SCREENS.md`.
- **Color de selección de texto** (`::selection`) como token, con contraste verificado, en
  claro y oscuro. Fase 02.
- **Assets de marca**: el arranque pregunta qué tiene el cliente (logo, icono, favicon, touch
  icon, OG) y qué hay que crear. Guía: `reference/BRAND-ASSETS.md`.
- **Repo en GitHub y despliegue en Vercel**: el arranque pregunta si se crean, y con el sí el
  agente los crea y configura (incluidos los ajustes que antes eran acciones manuales).
  Guía: `reference/DEPLOY.md`.
- **Feedback para el kit**: `context/KIT_FEEDBACK.md` registra correcciones, repeticiones,
  huecos y fricciones; al pedirlo, sale un informe para pegar en el kit.
- **Versionado**: `.kit-version` en cada proyecto, este archivo y `prompts/ACTUALIZAR-KIT.md`.

**Pasos para un proyecto en 3.2.0**

1. **Diagnóstico** (sin cambiar nada), en una tabla:
   - pantallas de estado: existen `app/**/not-found.tsx`, `error.tsx`, `global-error.tsx`,
     página de mantenimiento, manejo de offline, galería de estados; si el sitio tiene auth;
   - `::selection` en los estilos globales (`grep -rn "::selection\|selection:" app/ styles/ src/`);
   - assets: `app/favicon.ico`, `icon.*`, `apple-icon.*`, `manifest.*`, `opengraph-image.*`,
     y si hay logo/icono fuente en `public/` o `design/`;
   - remoto de GitHub (`git remote -v`), ajustes del repo
     (`gh api repos/<dueño>/<repo> -q .delete_branch_on_merge`), y enlace con Vercel
     (`.vercel/project.json`).
2. **Archivos del kit** (sin pisar lo propio del proyecto):
   - `.kit-version` con `3.3.0` (lo escribe `kit-update` al cerrar cada versión).
   - `context/KIT_FEEDBACK.md` desde `<kit>\context-templates\KIT_FEEDBACK.md`, local como el
     resto de `context/` no fijo (añádelo al `.gitignore` si el proyecto ignora
     `CURRENT_PHASE.md`).
   - `CLAUDE.md`: la línea **Kit** de la cabecera y la regla de feedback de "Cuándo parar y
     preguntar", copiadas de `<kit>\CLAUDE.md.template`. Tope 8 KB.
   - `context/PROJECT_CONTEXT.md`: secciones "Assets de marca" y "Repo y despliegue" de la
     plantilla, llenas con el diagnóstico.
   - `context/COLORS.md`: filas `selection` en claro y oscuro (vacías si no hay valor aún).
3. **Preguntas a César** (una tanda, `AskUserQuestion`): por cada asset que falte, ¿lo tiene
   el cliente o hay que crearlo?; si no hay remoto, ¿se crea el repo?; si no hay Vercel, ¿se
   despliega? Con el sí, ejecuta `reference/DEPLOY.md` (fuera de este PR si el repo aún no
   existe: primero se crea y se empuja `main`, luego va el PR).
4. **Lo que falta de diseño no se implementa en este PR.** Va a `context/plans/pendientes.md`
   como unidades (una por pantalla de estado que falte, selección, assets), y se le entrega a
   César el texto para Claude Design con `<kit>\prompts\CLAUDE-DESIGN-ADENDA.template.md`,
   lleno solo con lo que falta.
5. Contenido que falte (copy de las pantallas, logo/icono del cliente): filas en
   `CONTENT_CHECKLIST.md`.

---

## 3.2.0 — 2026-09-28 · Decisiones por archivo y CI en el PR de versión

**Qué cambió:** `context/DECISIONS_INDEX.md` desaparece; cada decisión es
`context/decisions/D0NN-<tema>.md` y su primera línea es la fila del índice. `release.yml`
lanza `ci.yml` (con `workflow_dispatch`) sobre el PR de versión.

**Pasos para un proyecto en 3.1.0:** el bloque de
[`prompts/MIGRAR-DECISIONES-Y-CI.md`](./prompts/MIGRAR-DECISIONES-Y-CI.md), pasos 1 y 3 a 6
(la rama, la verificación y el cierre los hace `kit-update`; las "Acciones manuales"
de su paso 8 van al PR). Sin Changesets, solo la parte de
decisiones.

---

## 3.1.0 — 2026-09-26 · Pool de worktrees y versión con Changesets

**Qué cambió:** `orchestrate` usa un pool fijo de worktrees (`wt.ps1`) en vez de crear y
borrar uno por unidad. Versión y CHANGELOG con Changesets: cada PR trae su
`.changeset/*.md` y una Action mantiene el PR de versión.

**Pasos para un proyecto en 3.0.0:** el bloque de
[`prompts/ACTUALIZAR-PROYECTO.md`](./prompts/ACTUALIZAR-PROYECTO.md), pasos 1, 3, 4, 5 y 8
(la rama, la verificación y el cierre los hace `kit-update`; las "Acciones manuales"
de su paso 7 van al PR).

---

## 3.0.0 — 2026-09-24 · Base v3 (lo aprendido en World Flags)

Lectura por niveles, `CURRENT_PHASE.md` con tope y `PHASE_LOG/`, modo `pr`, `orchestrate` +
`feature-worker`, `test:related`, capturas en el PR. Ver "Qué cambió en la v3" en el README.

---

## Al publicar una versión nueva del kit (para quien mantiene el kit)

1. Sube [`VERSION`](./VERSION) (semver: **minor** si un proyecto necesita pasos de migración
   o hay piezas nuevas; **patch** si solo se corrigen textos o bugs de scripts sin cambio en
   los proyectos; **major** si rompe el flujo y la migración no es automática).
2. Añade la entrada **arriba** de esta lista: qué cambió y **los pasos para un proyecto en la
   versión anterior**, autocontenidos (el agente que migra solo lee esto y lo que se cite).
3. Si la versión nueva añade una señal detectable, añádela a la tabla de deducción (que no
   dependa de Changesets: hay proyectos sin versión).
4. **`CLAUDE.md` del proyecto no crece sin tope.** Un paso que le añade texto dice qué
   párrafo viejo sustituye; si es nuevo de verdad, que sea una línea que cite el detalle en
   el kit. Dos proyectos tuvieron que recortar a mano sus reglas propias tras sumar
   versiones (8,8 KB y 8,1 KB).
5. Si un paso edita un archivo de `context/` que un proyecto puede no tener (arrancó corto),
   dice qué hacer si falta (lo normal: crearlo solo con las secciones del paso).
