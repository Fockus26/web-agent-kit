# Actualizaciones del kit — versiones y camino de migración

Cada proyecto guarda en **`.kit-version`** (raíz del repo, en git, una línea) la versión del
kit con la que quedó alineado. La versión actual del kit está en [`VERSION`](./VERSION).

Para actualizar un proyecto no se elige a mano qué migración correr: se pega
[`prompts/ACTUALIZAR-KIT.md`](./prompts/ACTUALIZAR-KIT.md) en una sesión abierta en el
proyecto. Lee `.kit-version`, calcula el camino (todas las versiones posteriores, en orden)
y aplica cada paso de esta lista en una sola rama, un commit por versión.

---

## Cómo saber la versión de un proyecto sin `.kit-version`

Los proyectos anteriores a la 3.3.0 no tienen el archivo. Se deduce por señales, de la más
nueva a la más vieja (la primera que se cumple gana):

| Si el proyecto… | Está en |
|---|---|
| tiene `context/decisions/D0NN-*.md` y no `context/DECISIONS_INDEX.md`, y (si lleva versión) `ci.yml` con `workflow_dispatch` | **3.2.0** |
| tiene `.changeset/` y `.github/workflows/release.yml` (o `CLAUDE.md` habla del pool `..\<repo>-wt`) | **3.1.0** |
| tiene `context/CURRENT_PHASE.md` con el tope de 60 líneas y `context/PHASE_LOG/` | **3.0.0** |
| no tiene `context/PHASE_LOG/` | **2.x o anterior**: no hay camino automático. `nuevo-proyecto.ps1 -Existente` añade lo que falte sin pisar nada y se sigue desde 3.0.0 |

Si las señales se contradicen (p. ej. proyecto creado con `-SinVersion`, sin Changesets), el
agente lo dice y pregunta antes de elegir.

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
   - `.kit-version` con `3.3.0` (lo escribe el paso final de `ACTUALIZAR-KIT.md`).
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
(la rama, la verificación y el cierre los hace `ACTUALIZAR-KIT.md`; las "Acciones manuales"
de su paso 8 van al PR). Sin Changesets, solo la parte de
decisiones.

---

## 3.1.0 — 2026-09-26 · Pool de worktrees y versión con Changesets

**Qué cambió:** `orchestrate` usa un pool fijo de worktrees (`wt.ps1`) en vez de crear y
borrar uno por unidad. Versión y CHANGELOG con Changesets: cada PR trae su
`.changeset/*.md` y una Action mantiene el PR de versión.

**Pasos para un proyecto en 3.0.0:** el bloque de
[`prompts/ACTUALIZAR-PROYECTO.md`](./prompts/ACTUALIZAR-PROYECTO.md), pasos 1, 3, 4, 5 y 8
(la rama, la verificación y el cierre los hace `ACTUALIZAR-KIT.md`; las "Acciones manuales"
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
3. Si la versión nueva añade una señal detectable, añádela a la tabla de deducción.
