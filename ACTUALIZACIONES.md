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
