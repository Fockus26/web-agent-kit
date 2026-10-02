# Web Agent Kit

Sistema de agentes para producir sitios web de punta a punta: de una idea a medio formar
hasta un sitio implementado, accesible, optimizado y auditado.

Está armado alrededor de una premisa concreta: **el desarrollador es fuerte en frontend y
flojo en diseño.** Por eso el diseño se delega a Claude Design con un brief riguroso, y todo
lo demás se apoya en puertas de calidad que no dependen de tener buen ojo.

> **¿Cómo lo uso?** Ver [GUIA.md](./GUIA.md): instalación, crear un proyecto y el flujo
> completo con un ejemplo.

---

## El flujo

```
      César llega con una idea
                │
                ▼
    ┌───────────────────────┐
    │  1. project-kickoff   │  entrevista → modo plan → context/ + brief
    │      (orquestador)    │
    └───────────┬───────────┘
                │  entrega un brief autocontenido
                ▼
    ┌───────────────────────┐
    │   2. CLAUDE DESIGN    │  ← César pega el brief a mano (herramienta aparte)
    │                       │
    └───────────┬───────────┘
                │  devuelve el diseño + HANDOFF.md
                ▼
    ┌───────────────────────┐        ┌──────────────────────┐
    │  3. frontend-build    │◄──────►│  4. backend-build    │
    │  tokens → componentes │        │  auth · datos · pagos │
    │  → secciones → páginas│        └──────────┬───────────┘
    └───────────┬───────────┘                   │
                │                               │
                ▼                               ▼
    ┌───────────────────────┐        ┌──────────────────────┐
    │   5. design-qa        │        │  6. functional-qa    │
    │   pantallas · CVD ·   │        │  romper flujos ·     │
    │   zoom · coherencia   │        │  seguridad · límites │
    └───────────────────────┘        └──────────────────────┘

  En cada cierre de unidad, siempre:   [a11y] → [seo si aplica] → [git-flow]

  ¿Llega una lista de varias cosas a la vez?  → [orchestrate] reparte en unidades,
  las ordena en olas y lanza un feature-worker por unidad, cada uno en un slot del pool de
  worktrees (reciclable: no reinstala node_modules) y con su PR.
```

---

## Roster

### Skills — corren en la sesión principal

Se activan solas cuando aplica, o las invocas con `/nombre`. Son las que **pueden hablar
contigo**: hacer preguntas, presentar 3 opciones, esperar tu aprobación.

| Skill | Qué hace | Cuándo se activa |
|---|---|---|
| **`project-kickoff`** | Entrevista, modo plan, genera `context/` y el brief para Claude Design | Proyecto nuevo |
| **`frontend-build`** | Handoff → código, una unidad a la vez | Cada unidad de UI |
| **`backend-build`** | Auth, sesiones, datos, pagos, formularios | Cada unidad de funcionalidad |
| **`git-flow`** | Ramas, commits, verificación, capturas, poda de `context/`; cierre por PR (modo `pr`) o con pausa + merge local (modo `local`) | Al abrir y cerrar cada unidad |
| **`orchestrate`** | Mapea una lista de pedidos (o una fase) al código, agrupa, ordena en olas, reserva números, pregunta lo que bloquea y lanza un `feature-worker` por unidad; con la ola mergeada lanza `wave-qa`, la cierra diciendo fase, ola y lo que sigue, y abre la siguiente en otra sesión | Cuando llegan varias cosas a la vez · al hacer una fase en olas |
| **`a11y`** | Puerta WCAG 2.1 AA | Siempre que se toque UI, antes de la revisión |
| **`seo`** | Metadata, JSON-LD, sitemap, Core Web Vitals | Init del repo · sección con contenido · página |

### Agentes — corren aislados y devuelven un reporte

Los de QA auditan sin interrumpir y no modifican código. `feature-worker` sí implementa: una
unidad completa, en su slot del pool de worktrees, hasta el PR.

| Agente | Qué hace | Cuándo lo lanzas |
|---|---|---|
| **`feature-worker`** | Implementa una unidad de punta a punta (rama, código, tests, verificación, capturas, PR) con el prompt que le prepara `orchestrate`. Opus, esfuerzo medio | Lo lanza `orchestrate` |
| **`wave-qa`** | Con la ola ya mergeada, levanta el servidor sobre `main` y recorre sus flujos como usuario real, con las cuentas de prueba de `.env.local` por rol (`EMAIL_TEST`, `ADMIN_EMAIL_TEST`, `<ROL>_EMAIL_TEST`…); los datos que crea, los borra | Lo lanza `orchestrate` al cerrar cada ola |
| **`design-qa`** | 320px a 3840px, daltonismo, zoom 400%, movimiento reducido, alto contraste, foco, coherencia de tokens. Con Playwright + axe. | Al cerrar una página o toda la integración |
| **`functional-qa`** | Intenta romper el flujo: entradas límite, dobles clics, red caída, sesión expirada, precios manipulados, webhooks duplicados | Al cerrar un flujo completo |

### Por qué unos son skills y otros agentes

No es arbitrario: **un subagente no puede hacerte preguntas mientras corre.** Se lanza, hace
su trabajo aislado, y devuelve un resultado.

Todo lo que necesita tu aprobación —el orquestador, el frontend, el backend— tiene que vivir
en la sesión principal, y por eso son skills. Lo que audita y reporta sin necesitar
decisiones tuyas a mitad de camino gana con el aislamiento: no contamina el contexto de la
sesión de desarrollo y puede correr en paralelo. Por eso los QA son agentes.

`orchestrate` es skill porque tiene que preguntarte (una vez, al principio) lo que bloquea.
`feature-worker` es agente porque ejecuta un prompt ya decidido: lo que falte lo resuelve de
forma conservadora y te lo deja explicado en el PR, que es donde apruebas.

---

## Instalación

### Skills y agentes (una vez, para todos tus proyectos)

**Windows (PowerShell):**

```powershell
$kit = "$env:USERPROFILE\Desktop\agents\web-agent-kit"   # donde clonaste el repo
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills","$env:USERPROFILE\.claude\agents"
Copy-Item "$kit\.claude\skills\*" "$env:USERPROFILE\.claude\skills\" -Recurse -Force
Copy-Item "$kit\.claude\agents\*" "$env:USERPROFILE\.claude\agents\" -Force
```

**macOS / Linux:**

```bash
kit=~/Desktop/agents/web-agent-kit   # donde clonaste el repo
mkdir -p ~/.claude/skills ~/.claude/agents
cp -r "$kit"/.claude/skills/* ~/.claude/skills/
cp -r "$kit"/.claude/agents/* ~/.claude/agents/
```

Verifica con `/skills` y `/agents`. Deberías ver las siete skills y los cuatro agentes.

> **Los agentes se cargan al abrir la sesión.** Si instalas o editas uno con una sesión
> abierta, esa sesión no lo ve ("Agent type not found"): abre una sesión nueva.

> Si prefieres tenerlos por proyecto en vez de globales, copia la carpeta `.claude/` completa
> a la raíz del proyecto. Lo global es más cómodo cuando todos tus proyectos siguen este
> mismo flujo; lo local, cuando quieres versionarlos junto al repo del cliente.

### Context7

El MCP de Context7 tiene que estar conectado: los agentes de frontend y backend lo consultan
antes de usar la API de cualquier librería. Si no está, lo dirán y marcarán ese código como
escrito sin verificar contra documentación actual.

---

## Arrancar un proyecto nuevo

Un solo comando (PowerShell 7, `pwsh`) crea la app y deja todo el kit copiado:

```powershell
& "$env:USERPROFILE\Desktop\agents\web-agent-kit\nuevo-proyecto.ps1" -Ruta C:\ruta\mi-proyecto
```

- Crea la app con `bunx create-next-app@latest <nombre> --ts --tailwind --app --biome
  --react-compiler --import-alias "@/*" --use-bun` (Biome, no ESLint; React Compiler activo).
- Copia `context/`, `phases/`, `CLAUDE.md` (conservando el `@AGENTS.md` de Next.js 16),
  `scripts/`, `.github/`, `.changeset/` y crea `tests/unit/` y `design/`.
- Añade los scripts de `package.json` (`test`, `test:related`, `shots`, `shots:publish`),
  `@types/bun`, `@playwright/test` y `@changesets/cli`, y `.pr-shots` al `.gitignore`.
- Versión y CHANGELOG con Changesets: cada PR trae su `.changeset/*.md` y una Action mantiene
  el PR de versión, así los PRs en paralelo no chocan. `-SinVersion` lo omite.
- No pisa nada que ya exista y **no commitea**.

¿Proyecto ya creado con otras opciones? `-Existente` añade solo lo del kit (ver GUIA.md).
¿Windows PowerShell 5.1 bloquea el script? `powershell -ExecutionPolicy Bypass -File <kit>\nuevo-proyecto.ps1 -Ruta ...`
(solo para esa ejecución; no cambia la configuración del sistema).

Después, en Claude:

**1. Arranque.** Cuéntale el proyecto en tus palabras — lo que tengas claro y lo que no.
No hace falta que esté ordenado.

```
/project-kickoff

Quiero una landing para una clínica dental en Valencia. Sé que quiero el azul de su logo
(#0F6E8C) y que use Inter. Secciones: hero, servicios, el equipo, testimonios y agendar cita.
El resto no lo tengo claro.
```

Te va a preguntar lo que solo tú sabes (negocio, contenido, alcance) y a **proponer** lo
visual con criterio. Entra en modo plan, y cuando apruebes el plan escribe todo `context/` y
te entrega el brief de diseño en un bloque listo para copiar.

**2. Diseño.** Pega ese brief en Claude Design. Vuelve con dos cosas: el diseño y un
`HANDOFF.md`. Guarda el handoff en `design/HANDOFF.md`.

**3. Verificación del handoff.** Vuelve a Claude y dile que lo revise. Si falta algo —un
estado, una medida, el comportamiento en mobile— te da la pregunta exacta para devolvérsela a
Claude Design. **Este paso parece opcional y no lo es**: un dato que falta aquí cuesta minutos
de preguntar y horas de reimplementar en la fase 5.

**4. Implementación.** Fase por fase, unidad por unidad:

```
/frontend-build   fase 01, tokens
```

Cada unidad termina con una pausa donde tú revisas. Apruebas, y ahí sí se commitea.

**5. Funcionalidad.** `/backend-build` cuando toque auth, datos o pagos.

**6. QA.** Lanza `design-qa` y `functional-qa`. Pueden correr en paralelo.

---

## El flujo de git

Dos modos, fijados en `context/GIT_STATE.md`:

**Modo `pr`** (recomendado en cuanto el repo está en GitHub con `main` protegida):

```
git switch -c <tipo>/<desc> origin/main → implementar → test:related → [a11y] → [seo]
   → build + typecheck + lint + test → capturas → podar context/
   → commit(s) + push de la rama → gh pr create → César revisa y mergea (squash)
```

En su rama el agente commitea y empuja sin pedir permiso: la aprobación es la revisión del
PR. **Nunca** push a `main`, nunca `gh pr merge`. Si César pide cambios: commits nuevos en
la misma rama.

**Modo `local`** (sin remoto): pausa de aprobación → commit → `merge --no-ff` a la base →
push solo si la base no es `main`. Ramas madre para bloques grandes.

En los dos: **nada destructivo** (ni `reset --hard`, ni `push --force`, ni borrar ramas, ni
reescribir historia).

---

## Las fases

| # | Fase | Quién |
|---|---|---|
| 01 | Tokens | `frontend-build` |
| 02 | Layout base | `frontend-build` |
| 03 | Componentes | `frontend-build` |
| 04 | Secciones | `frontend-build` |
| 05 | Páginas | `frontend-build` |
| 06 | Estados (vacío, carga, error) | `frontend-build` |
| 07 | Backend | `backend-build` |
| 08 | Responsive y pulido | `frontend-build` |
| 09 | QA final | `design-qa` + `functional-qa` |

**Tracks:** Landing (01·02·03·04·06·08·09) · Sitio (01–06·08·09) · Producto (01–09).
El orquestador elige uno y lo justifica.

---

## Estructura del kit

```
web-agent-kit/
├── README.md                      este archivo
├── VERSION                        versión actual del kit (cada proyecto guarda la suya en .kit-version)
├── ACTUALIZACIONES.md             qué cambió en cada versión y los pasos para migrar un proyecto
├── CLAUDE.md                      cómo se mantiene el kit (procesar informes de feedback, versionar)
├── CLAUDE.md.template             va a la raíz de cada proyecto (≤ 8 KB: mapa, no manual)
├── .claude/
│   ├── skills/                    las 7 skills → ~/.claude/skills/
│   │   └── orchestrate/           + brief-, unit-prompt- y fase-plan-template.md y
│   │                                scripts/wt.ps1 (pool de worktrees reciclables)
│   └── agents/                    design-qa, functional-qa, feature-worker, wave-qa → ~/.claude/agents/
├── prompts/
│   ├── CLAUDE-DESIGN-BRIEF.template.md   lo que se le pega a Claude Design
│   ├── DESIGN-HANDOFF.template.md        lo que debe volver, y su verificación
│   ├── CLAUDE-DESIGN-ADENDA.template.md  piezas que faltan en un diseño ya hecho (estados, icono, OG…)
│   ├── ACTUALIZAR-KIT.md                 el que se pega para poner al día un proyecto (calcula el camino)
│   ├── ACTUALIZAR-PROYECTO.md            paso 3.0 → 3.1 (lo cita ACTUALIZACIONES.md)
│   └── MIGRAR-DECISIONES-Y-CI.md         paso 3.1 → 3.2 (lo cita ACTUALIZACIONES.md)
├── context-templates/             → se copia como context/ en cada proyecto
├── phases-templates/              → se copia como phases/
├── sections-template/             brief de contenido, uno por sección
├── github-templates/              → se copia como .github/ (plantilla de PR, CI y release.yml)
├── changeset-templates/           → se copia como .changeset/ (versión y CHANGELOG sin conflictos)
└── reference/
    ├── STACK-NEXTJS.md            Next.js + bun + Context7 + convenciones
    ├── UI-LIBRARIES.md            shadcn/ui · Hero UI · MUI — criterio y qué cambia
    ├── TOKEN-ECONOMY.md           lectura por niveles, topes de context/, tests, capturas
    ├── STATUS-SCREENS.md          404 · 500 · sin conexión · mantenimiento: catálogo e implementación
    ├── BRAND-ASSETS.md            logo, icono, favicon, touch icon, OG: qué se pregunta y qué se genera
    ├── DEPLOY.md                  crear el repo en GitHub y desplegar en Vercel
    └── qa-scripts/
        ├── design-qa.ts           barrido de Playwright (con node)
        ├── test-related.ts        → scripts/: tests afectados por el grafo de imports
        ├── pr-screenshots.ts      → scripts/: capturas para el PR (con node)
        └── publish-pr-shots.sh    → scripts/: las sube a la rama pr-shots
```

---

## Reglas transversales

Valen para todos los agentes, en todo momento:

- **Cero contenido inventado.** Ni copy, ni `alt` real, ni precios, ni datos de contacto, ni
  testimonios. Placeholder marcado + fila en `CONTENT_CHECKLIST.md`. Contenido inventado que
  parece final se publica sin que nadie lo revise.
- **Cero lorem ipsum.** Placeholder realista, en el idioma del proyecto, con la longitud del
  texto final. Un layout validado con lorem se rompe al llegar el copy real.
- **Cero valores mágicos.** Todo sale de los tokens. Un `text-[#3a7bd5]` significa que falta
  un token o falta registrar una decisión.
- **Cero secretos en el código.** Variables de entorno siempre.
- **Ambigüedad → exactamente 3 opciones**, con ventaja y desventaja real, y se espera.
- **Falta un dato del handoff → se pregunta**, no se estima del mockup.
- **Problema en código ya cerrado → se reporta**, no se arregla de paso dentro de otra unidad.
- **Archivo sin uso → se señala**, no se borra.
- **Accesibilidad gana sobre el handoff.** Si un color del diseño no llega a AA, se corrige el
  diseño, no se hace la vista gorda.
- **El servidor de desarrollo lo levantas tú.** Cuando un agente necesita el sitio corriendo,
  te lo pide y espera. Única excepción: una tanda de `orchestrate` en la que tú autorices
  que cada worker levante el suyo, en segundo plano y en su puerto. Ver
  `reference/TOKEN-ECONOMY.md`.
- **Playwright se corre con `node`, no con `bun`.** En Windows, Playwright lanzado desde un
  script de Bun se cuelga al arrancar Chromium.

---

## Economía de tokens

Detalle en `reference/TOKEN-ECONOMY.md`. Lo que más pesa:

| Regla | Por qué |
|---|---|
| **Lectura por niveles:** siempre `CLAUDE.md` + `CURRENT_PHASE.md`; lo demás según la tarea o con `grep` | "Lee estos 5 archivos antes de empezar" costaba ~20.000 tokens por sesión en el primer proyecto real |
| **Topes:** `CLAUDE.md` ≤ 8 KB, `CURRENT_PHASE.md` ≤ 60 líneas, índices con filas de una línea | Lo que se lee siempre se paga siempre; lo cerrado va a `PHASE_LOG/<rama>.md` |
| **Tests afectados en el bucle, todos en CI** (`test:related`, `--dots`) | Menos tiempo y menos salida mientras se itera, sin perder la red de seguridad |
| **Capturas al disco, no al contexto** | Son para quien revisa el PR; el agente verifica midiendo el DOM |
| **Subagentes para lo ruidoso**, con prompts que traen rutas y líneas | Su ruido se queda en su contexto; arrancan en frío, así que el prompt da el contexto mínimo suficiente |
| **Esfuerzo según el papel:** orquestador alto, workers medio | Planificar bien una vez abarata ejecutar muchas |
| El servidor lo levanta César (o cada worker el suyo, en segundo plano, si él lo autoriza) | Logs de compilación en el contexto; servidores huérfanos |

---

## Versiones y actualización de proyectos

El kit lleva versión (`VERSION`, ahora **3.3.0**) y cada proyecto guarda en `.kit-version`
con cuál quedó alineado. Para ponerlo al día: `prompts/ACTUALIZAR-KIT.md` en una sesión del
proyecto. Calcula el camino con `ACTUALIZACIONES.md` y aplica cada versión en orden, en un PR.

Y el camino de vuelta: cada proyecto anota en `context/KIT_FEEDBACK.md` lo que César tuvo que
corregir o repetir y lo que el kit no cubría. Al pedir "el informe para el kit" sale un bloque
que se pega en una sesión abierta en este repo, donde `CLAUDE.md` dice cómo procesarlo.

### 3.3.0

| Antes | Ahora |
|---|---|
| "Estados de error (404, 500…)" como una casilla del brief | Catálogo de pantallas de estado: 404 con sesión/invitado (solo con auth), 500 con/sin código, sin conexión elegida según la red, mantenimiento con/sin hora — diseñadas, con estado HTTP real y galería `/estados` |
| Color de selección sin definir | Token `selection` con contraste verificado, claro y oscuro |
| Favicon y OG se generaban sin preguntar | El arranque pregunta qué assets tiene el cliente y cuáles hay que crear |
| Crear el repo y ajustar GitHub eran acciones manuales | El arranque pregunta; con el sí, el agente crea el repo, lo configura y conecta Vercel |
| Proyectos viejos: un prompt suelto por cambio | `.kit-version` + `ACTUALIZACIONES.md` + un solo `ACTUALIZAR-KIT.md` |
| Las correcciones se perdían en el chat | `KIT_FEEDBACK.md` por proyecto → informe → mejora del kit |

## Qué cambió en la v3 (lo aprendido en World Flags)

| v2 | v3 |
|---|---|
| "Lee estos 5 archivos antes de empezar" | Lectura por niveles: siempre `CLAUDE.md` + `CURRENT_PHASE`; lo demás según la tarea o con `grep` |
| `CURRENT_PHASE.md` "liviano" sin tope (llegó a 38 KB) | Tope de 60 líneas; la narrativa va a `PHASE_LOG/<rama>.md`; se poda al cerrar cada unidad |
| Solo merge local con pausa de aprobación | Modo `pr` (PR que César revisa y mergea) además del `local` |
| Una sesión hace todo, unidad a unidad | `orchestrate` + `feature-worker`: tandas en paralelo en un pool de worktrees reciclables, en olas, con números reservados |
| Toda la suite de tests en cada iteración | `test:related` (grafo de imports) en el bucle; suite completa antes del PR y en CI |
| PR sin capturas | `shots` + `shots:publish`: capturas a la rama `pr-shots`, enlazadas en el PR, sin que el agente las abra |
| Scripts de Playwright con `bun` (se colgaban en Windows) | Con `node` |
| Plantillas de ejemplo citadas que no existían (`01-colores.md`) | Ejemplo dentro de `decisions/README.md` |

## Qué cambió respecto de la v1

| v1 | v2 |
|---|---|
| 6 agentes de texto para pegar en un chat | 6 skills que se activan solas + 2 agentes de QA aislados |
| El agente `WEB_DESIGNER` inventaba la paleta y el sistema | Claude Design diseña; el orquestador prepara el brief y verifica el handoff |
| El traspaso a desarrollo era implícito | `HANDOFF.md` con estructura obligatoria y checklist de verificación |
| Git como recomendación de texto | Flujo ejecutable con ramas madre, pausa de aprobación y regla de push |
| Accesibilidad como auditoría posterior | Puerta obligatoria antes de cada commit |
| Sin QA de dispositivos ni de funcionalidad | `design-qa` (320–3840px, daltonismo, zoom) y `functional-qa` (adversarial) |
| Stack genérico | Next.js + TS, **bun**, **Context7**; la librería de componentes se decide por proyecto |
| 10 fases de diseño | 9 fases de implementación, con 3 tracks según el proyecto |

La v1 sigue siendo válida para ChatGPT o para Claude sin skills disponibles: sus agentes son
prompts pegables. La v2 asume Claude Code o Cowork con acceso a archivos.
