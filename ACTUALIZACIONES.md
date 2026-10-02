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

## 3.4.0 — 2026-10-02 · QA de ola con cuentas de prueba, fases en olas, una ola por sesión

**Qué cambió**

- **Agente nuevo `wave-qa`.** Cuando todos los PRs de una ola están mergeados, `orchestrate`
  lo lanza en un slot del pool sobre `main`: levanta el servidor, recorre los flujos de la
  ola (y las costuras entre PRs) con sesión iniciada, por rol, y devuelve hallazgos
  reproducibles. Lo crítico y lo alto pasa a la ola siguiente. Por qué: cada worker probaba
  su unidad como invitado y en su rama; nadie probaba las unidades juntas ni con login.
- **Cuentas de prueba** en `.env.local`, una pareja por rol: `EMAIL_TEST`/`PASSWORD_TEST`,
  `ADMIN_EMAIL_TEST`/`ADMIN_PASSWORD_TEST`, `<ROL>_EMAIL_TEST`/`<ROL>_PASSWORD_TEST`. Solo la
  QA inicia sesión con ellas, en localhost, y sin que los valores pasen por su contexto
  (`node --env-file=.env.local`). Puede crear datos reales si los marca, los anota mientras
  los crea y los borra al terminar; lo que no se pueda borrar vuelve con el SQL para César.
  `functional-qa` sigue las mismas reglas y ahora levanta su propio servidor.
- **Fases en olas, una ola por sesión.** `orchestrate` puede partir una fase en olas
  (`context/plans/fase-0N-<nombre>.md`, plantilla `fase-plan-template.md`). Cada ola cierra
  con: fase, ola cerrada, resultado de la QA, qué sigue; y con "inicia la ola en otra sesión"
  abre una sesión nueva con el prompt de arranque (o lo da para pegar). Por qué: una sesión
  que encadena olas arrastra el mapeo y los informes de todas en cada mensaje.

**Pasos para un proyecto en 3.3.0**

1. Ninguno para las piezas globales: **reinstalar skills y agentes** (copiar `.claude\skills`
   y `.claude\agents` del kit a `~\.claude\`) y abrir sesión nueva, o `wave-qa` no existe
   ("Agent type not found").
2. `CLAUDE.md` del proyecto, desde `<kit>\CLAUDE.md.template`: el párrafo "Servidor de
   desarrollo", el de "Cuentas de prueba" debajo, y las filas de `orchestrate` y `wave-qa`
   de "Puertas de calidad". Tope 8 KB.
3. `context/CURRENT_PHASE.md`: la línea **Ola** bajo "Fase" (o nada si no se usan olas).
4. **Si el proyecto tiene login:** en `.env.example`, las parejas `*_EMAIL_TEST` /
   `*_PASSWORD_TEST` vacías, una por rol que exista en el código (búscalos:
   `grep -rniE "role|rol|isAdmin" --include=*.ts --include=*.tsx src app lib`). Comprueba que
   `.env.local` está en `.gitignore`. **Acción de César** en el PR: crear una cuenta de prueba
   dedicada por rol y poner los valores en `.env.local`.
5. Si hay una tanda en curso, termina con el flujo viejo; la siguiente ya cierra con
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
