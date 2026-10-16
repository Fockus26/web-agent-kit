# Guía de uso — Web Agent Kit

Cómo se usa el kit en el día a día, con un ejemplo completo. El `README.md` explica **qué
es** cada pieza; esta guía explica **qué haces tú** y en qué orden.

---

## 1. La idea en 30 segundos

No le pasas el kit a Claude en cada conversación. El kit tiene dos partes:

| Parte | Se instala | Qué es |
|---|---|---|
| **Skills y agentes** (`.claude/`) | Una vez, en `~/.claude/` | "Cómo se trabaja": entrevistar, implementar, revisar accesibilidad, abrir PRs, orquestar |
| **Plantillas** (`context-templates/`, `CLAUDE.md.template`, `scripts/`, `github-templates/`) | En cada proyecto nuevo, con `nuevo-proyecto.ps1` | La memoria del proyecto: qué es, qué se decidió, dónde quedó todo |

Después abres Claude Code en la carpeta del proyecto y hablas normal. `CLAUDE.md` se carga
solo en cada sesión y le dice a Claude qué leer según la tarea; las skills se activan solas
(o las llamas con `/nombre`).

Tu papel son cuatro momentos: **contar el proyecto**, **llevar el brief a Claude Design**,
**elegir entre opciones cuando te las presentan** y **revisar y mergear los PR**.

---

## 2. Instalación (una vez por máquina)

```powershell
git clone https://github.com/Fockus26/web-agent-kit.git "$env:USERPROFILE\Desktop\agents\web-agent-kit"
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\instalar-kit.ps1"
```

`instalar-kit.ps1` copia las skills y los agentes a `~\.claude\`, reemplazando la versión
que hubiera (sin dejar archivos viejos) y sin tocar lo que no es del kit.

Luego:

1. **Abre una sesión nueva de Claude Code.** Los agentes se cargan al arrancar; una sesión
   que ya estaba abierta no los ve.
2. Comprueba con `/skills` (9) y `/agents` (4: `feature-worker`, `wave-qa`, `design-qa`, `functional-qa`).
3. Conecta el MCP de **Context7** (documentación al día de las librerías).
4. Requisitos: **bun**, **Node ≥ 23.6** (para los scripts de Playwright), **git**, **gh**
   autenticado, **PowerShell 7** (`pwsh`). Si el proyecto usa Supabase: **Docker Desktop**
   abierto y la **CLI de Supabase** (la QA corre contra una base local).

### Actualizar el kit

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\instalar-kit.ps1" -Pull
```

`-Pull` hace `git pull` en el kit antes de reinstalar. Después, sesión nueva. El instalador
deja en `~\.claude\web-agent-kit.json` la ruta del clon y la versión instalada (lo lee
`kit-update`).

Los proyectos ya creados no cambian solos: cada uno guarda en `.kit-version` la versión con
la que quedó, y se pone al día con `/kit-update` (ver §3, "Proyecto que seguía una versión
anterior del kit").

---

## 3. Crear un proyecto

### Proyecto nuevo

```powershell
& "$env:USERPROFILE\Desktop\agents\web-agent-kit\nuevo-proyecto.ps1" -Ruta C:\Users\Admin\Documents\Work\clinica-dental
```

Hace, en este orden:

1. `bunx create-next-app@latest clinica-dental --ts --tailwind --app --biome --react-compiler --import-alias "@/*" --use-bun`
   — **Biome** (no ESLint), **React Compiler** activo, bun. Next ya inicializa git.
2. Copia `context/`, `phases/`, `scripts/`, `.github/` (plantilla de PR, CI y `release.yml`)
   y `.changeset/`, crea `design/` y `tests/unit/`. Si el proyecto no lleva versión ni
   CHANGELOG, `-SinVersion` omite lo de Changesets.
3. Escribe `CLAUDE.md` con la plantilla del kit, **conservando la línea `@AGENTS.md`** que
   pone Next.js 16 (así Claude lee las reglas de esa versión de Next).
4. Añade a `package.json`: `test`, `test:related`, `shots`, `shots:publish`, y las
   devDependencies `@types/bun`, `@playwright/test` y `@changesets/cli`.
5. Escribe `.kit-version` con la versión actual del kit.
6. Formatea lo copiado con el Biome del proyecto.

No pisa nada que ya exista y **no commitea**. El repo de GitHub y el despliegue en Vercel los
pregunta `/project-kickoff`: si dices que sí, hace el primer commit, crea el repo, aplica los
ajustes de abajo y conecta Vercel (`reference/DEPLOY.md`). Solo necesita que tengas sesión:

```powershell
gh auth login
bunx vercel login
```

Si prefieres hacerlo a mano, o el agente no pudo (un 403, sin sesión), esto es lo que hace:

```powershell
cd C:\Users\Admin\Documents\Work\clinica-dental
git add -A; git commit -m "chore: inicializa proyecto con web-agent-kit"
gh repo create <usuario>/clinica-dental --private --source . --push   # modo pr
```

En GitHub, protege `main`: exigir PR (0 aprobaciones, porque trabajas solo), exigir el check
`ci`, sin force-push ni borrado. Es la configuración de World Flags:

```bash
gh api -X PUT repos/<usuario>/<repo>/branches/main/protection --input - <<'EOF'
{"required_status_checks":{"strict":false,"contexts":["ci"]},"enforce_admins":false,
 "required_pull_request_reviews":{"required_approving_review_count":0},
 "restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
EOF
```

> **Repos privados en el plan gratuito de GitHub no admiten protección de ramas** (ni
> rulesets): la API responde 403 "Upgrade to GitHub Pro". Opciones: repo público, GitHub
> Pro, o seguir sin protección técnica (las reglas de `CLAUDE.md` siguen prohibiendo a los
> agentes empujar a `main` o mergear; lo que se pierde es el bloqueo si alguien se salta
> eso, y que el CI sea obligatorio antes de mergear).

Dos ajustes más en el repo de GitHub, una vez:

- *Settings › Actions › General › Allow GitHub Actions to create and approve pull
  requests*: sin eso, la Action de Changesets no puede abrir el PR de versión. Ese PR lo abre
  `GITHUB_TOKEN`, que no dispara `pull_request`; por eso `release.yml` lanza él mismo
  `ci.yml` sobre la rama del PR y el check `ci` aparece sin saltarse la protección.
- *Settings › General › Automatically delete head branches*: la rama remota se borra al
  mergear el PR.

Y en Windows, si vas a usar `orchestrate`: excluye de Windows Defender la carpeta de trabajo,
la del pool de worktrees (`..\<repo>-wt`) y `%USERPROFILE%\.bun\install\cache`. Con el
antivirus escaneando cada archivo de `node_modules`, instalar y borrar tarda el triple.

Ya puedes abrir Claude Code en la carpeta.

### Proyecto que seguía una versión anterior del kit

Abre una sesión en el proyecto y escribe `/kit-update`, venga de la versión que venga. Hace
esto:

0. Hace `git fetch` en el clon del kit y compara tres versiones: la del proyecto, la de las
   skills instaladas y la publicada (`origin/main`). Si el proyecto ya está en la publicada,
   te lo dice y termina. Si las skills instaladas son más viejas, las reinstala y te pide
   abrir otra sesión y repetir `/kit-update` (las skills se cargan al arrancar).
1. Lee `.kit-version` del proyecto. Si no existe (proyectos anteriores a la 3.3.0), deduce
   la versión por señales (`.changeset/`, `DECISIONS_INDEX.md`, `PHASE_LOG/`…) y te las
   enseña.
2. Calcula el camino con `ACTUALIZACIONES.md` (p. ej. 3.1.0 → 3.2.0 → 3.3.0) y te lo
   muestra antes de tocar nada.
3. Diagnostica todo el camino y te hace **una sola tanda** de preguntas.
4. Aplica cada versión en orden, en una rama `chore/kit-<versión>`, un commit por versión,
   actualizando `.kit-version` en cada paso. Un PR al final.
5. Lo que necesite diseño (p. ej. las pantallas de estado de la 3.3.0) no lo implementa: lo
   deja en `context/plans/pendientes.md` y te da el texto para Claude Design
   (`prompts/CLAUDE-DESIGN-ADENDA.template.md`).

`ACTUALIZAR-PROYECTO.md` y `MIGRAR-DECISIONES-Y-CI.md` siguen en `prompts/` porque
`ACTUALIZACIONES.md` los cita como los pasos de la 3.1.0 y la 3.2.0; no hace falta pegarlos
sueltos.

### Proyecto que ya creaste (o creaste con otras opciones)

```powershell
& "...\web-agent-kit\nuevo-proyecto.ps1" -Ruta C:\ruta\al\proyecto -Existente
```

Añade solo lo del kit; no toca la app. Si además lo creaste **con ESLint y sin React
Compiler** (pasó con `melao`: faltaban `--biome` y `--react-compiler`; `--typescript` sí
era válido, es alias de `--ts`), esto deja la app igual que si lo hubieras creado bien:

```powershell
bun remove eslint eslint-config-next
bun add -d @biomejs/biome babel-plugin-react-compiler
Remove-Item eslint.config.mjs
bunx biome init                 # o copia el biome.json que genera create-next-app --biome
```

- En `next.config.ts`: `reactCompiler: true` dentro de `nextConfig`.
- En `package.json`: `"lint": "biome check"` y `"format": "biome format --write"`.
- Comprueba: `bun run lint` y `bun run build`.

El `biome.json` que genera Next 16 activa los dominios `next` y `react`, el soporte de
directivas de Tailwind y el orden de imports; es mejor que el de `biome init`.

### Si PowerShell bloquea el script

Windows PowerShell 5.1 trae una política que no deja correr `.ps1`. Usa PowerShell 7
(`pwsh`), o salta la política **solo para esa ejecución**:

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\nuevo-proyecto.ps1" -Ruta C:\ruta\proyecto
```

---

## 4. El flujo, con un ejemplo completo

Ejemplo: una **landing para una clínica dental** en Valencia.

### Paso 1 — Arranque (`/project-kickoff`)

Abres Claude Code en la carpeta y escribes, en tus palabras:

```
/project-kickoff

Quiero una landing para una clínica dental en Valencia. Tienen logo azul (#0F6E8C) y usan
Inter. Secciones: hero, servicios, equipo, testimonios y agendar cita. Quiero que la cita
llegue por correo. El resto no lo tengo claro.
```

Qué pasa:

1. Te devuelve lo que ya entendió y **una sola tanda de preguntas**: lo que solo tú sabes
   (qué debe lograr el sitio, público, contenido real disponible, modo git `pr`/`local`,
   librería de componentes: shadcn/ui, Hero UI o MUI). También: qué **assets de marca**
   tiene el cliente (logo, icono, favicon, OG) y cuáles hay que crear, si hay que **crear el
   repo en GitHub y desplegar en Vercel**, y si el sitio necesitará **modo mantenimiento**.
2. Lo visual **te lo propone** con 3 direcciones (p. ej. "editorial sobrio / técnico /
   cálido"), con ventaja y riesgo de cada una. Eliges o le dejas elegir.
3. Entra en **modo plan**: resumen, track de fases (aquí *Landing*), secciones, paleta con
   contrastes medidos, arquitectura, riesgos. **Tú apruebas el plan.**
4. Rellena `context/` y `CLAUDE.md` con los datos reales (nada de `{{...}}`; lo que falte
   queda `PENDIENTE` + fila en `CONTENT_CHECKLIST.md`).
5. Si autorizaste repo y despliegue, los crea y configura (`reference/DEPLOY.md`).
6. Te entrega **el brief para Claude Design** en un bloque listo para copiar. Además de las
   páginas, pide las pantallas de estado (404, 500, sin conexión, mantenimiento), el color
   de selección de texto, los assets de marca que haya que crear y, si la app manda
   correos, sus plantillas (confirmar cuenta, recuperar contraseña, pedido, acuse del
   formulario…).

### Paso 2 — Diseño (tú, en Claude Design)

Pegas el brief en Claude Design. Vuelves con el diseño y un **`HANDOFF.md`**, que guardas en
`design/HANDOFF.md`.

### Paso 3 — Revisión del handoff

```
Revisa design/HANDOFF.md
```

Si falta algo (un estado de error, el comportamiento en móvil, una medida), te da **la
pregunta exacta** para devolvérsela a Claude Design. No te lo saltes: un dato inventado aquí
se paga rehaciendo secciones después.

### Paso 4 — Construcción, unidad a unidad

Sigues las fases del track. Cada unidad es algo que revisas en dos minutos:

```
/frontend-build fase 01, tokens
```

Lo que hace cada unidad, sin que se lo pidas:

```
rama feat/tokens  →  código  →  tests afectados  →  a11y  →  build + typecheck + lint + tests
   →  capturas (si cambió algo visible)  →  context/ al día  →  PR
```

En **modo `pr`** te llega un Pull Request con: qué cambia, cómo probarlo, **capturas** en
móvil y escritorio, claro y oscuro, cómo se verificó y qué no, decisiones tomadas y acciones
manuales. **Tú lo revisas y lo mergeas** (squash). Si pides cambios, se hacen en la misma
rama.

Siguientes unidades: `fase 02, layout base`, `fase 03, componentes: botón y tarjeta`,
`fase 04, sección hero`… Para el formulario de cita:

```
/backend-build formulario de agendar cita con envío por correo
```

Te propone 3 proveedores de correo si no está decidido, valida en el servidor, y al final te
lista **qué tienes que hacer tú** (crear la cuenta del proveedor, poner la variable de entorno
en Vercel…).

### Paso 5 — QA

Al cerrar la página o un flujo completo:

```
Lanza design-qa sobre la home
Lanza functional-qa sobre el formulario de cita
```

Corren aislados (su ruido no llena tu sesión) y te devuelven un informe con hallazgos
verificados. Los arreglos son unidades nuevas.

### Paso 6 — Tandas: cuando llegas con una lista

Semanas después vuelves con varias cosas a la vez:

```
/orchestrate

- El formulario de cita debería dejar elegir el tratamiento
- Añadir la sección de precios
- Los testimonios en móvil se ven apretados
- Que el botón de WhatsApp flote en móvil
```

Qué pasa:

1. Mapea cada punto al código y te hace **de una vez** las preguntas que bloquean (p. ej.
   "¿los precios son reales o placeholder?", "¿pueden los workers levantar el servidor?").
2. Agrupa (lo que toca los mismos archivos va junto), ordena en **olas** y reserva números
   (decisiones, filas del checklist) para que no choquen.
3. Deja el plan y los prompts en `context/plans/` y lanza un **`feature-worker`** por unidad,
   en paralelo, cada uno en un slot del **pool de worktrees** (`..\<repo>-wt\wt1..wtN`, con su
   puerto 4301, 4302…). Los slots no se borran: `node_modules` ya está y cada unidad solo
   instala si cambió `bun.lock`. La primera vez en un proyecto, el orquestador corre `wt init`.
4. Te llega **un PR por unidad**, cada uno con su changeset (sin tocar `version` ni
   `CHANGELOG.md`: no chocan entre sí). Mergéalos en el orden que quieras; tras cada merge
   el orquestador libera el slot (`wt free`).
5. Cuando le dices que mergeaste todos los PRs de la ola, lanza **`wave-qa`**: levanta el
   servidor sobre `main` y recorre los flujos de la ola como usuario real, con sesión
   iniciada (ver "Cuentas de prueba" abajo). Lo crítico y lo alto pasa a la ola siguiente.
6. Cierra la ola con un resumen corto: **en qué fase y ola estás, qué dejó la QA y qué ola
   sigue**. Le dices *"inicia la ola en otra sesión"* y abre una sesión nueva con el prompt
   de arranque (o te lo da para pegarlo, si no puede abrirla). Cada ola en su sesión: ninguna
   arrastra el contexto de las anteriores, y eso ahorra tokens en cada mensaje.
7. Cuando quieras publicar, mergeas el PR **`chore(release): versión`** que mantiene la
   Action: junta los changesets, sube la versión y escribe el CHANGELOG.

Mientras tanto puedes seguir con otra cosa. Lo que se te ocurra después va a
`context/plans/pendientes.md`, no a la tanda en curso.

**Una fase entera en olas.** Lo mismo sirve para construir: `/orchestrate arranca la fase 04`
parte la fase en olas (`context/plans/fase-04-secciones.md`) y lanza la primera. Cada cierre
te dice "Fase 04 · ola 2 de 3 cerrada · sigue ola 3"; al cerrar la última, sigue la fase
siguiente.

**QA contra una base local.** La QA nunca toca la base real. `bun run qa:local` levanta
Supabase en **Docker Desktop** (tenlo abierto), aplica las migraciones y el seed de `main`,
crea las cuentas de prueba y arranca el servidor apuntando a esa base. Ahí la QA puede crear,
romper y cambiar lo que quiera: cada corrida empieza de cero, y los correos que mande la app
se quedan en Mailpit. Por eso la base local es **desechable**: no guardes en ella nada tuyo.

Sin Docker en la máquina (o sin base local todavía), la ola no se bloquea: la QA corre con
`bun run qa:local -- --offline`, solo como invitado, y el cierre de la ola te dice que la
prueba con sesión quedó pendiente.

**Cuentas de prueba.** En cuanto el sitio tiene login, `backend-build` te pide rellenar
`.env.test.local` con una pareja por rol:

```
EMAIL_TEST=…            PASSWORD_TEST=…            # usuario normal
ADMIN_EMAIL_TEST=…      ADMIN_PASSWORD_TEST=…      # administrador
EDITOR_EMAIL_TEST=…     EDITOR_PASSWORD_TEST=…     # cualquier otro rol: <ROL>_…
```

Los valores los inventas tú: esas cuentas solo existen en la base local, las crea el script
en cada corrida. La QA inicia sesión con ellas solo en localhost y sin ver los valores (los
scripts los leen del entorno).

Lo único que tiene que cumplir el proyecto: el esquema entero como migraciones en
`supabase/migrations/` (un cambio hecho solo en el dashboard no existe en local) y un
`supabase/seed.sql` con lo mínimo para recorrer los flujos. `backend-build` ya lo hace así.

### Paso 7 — Devolver lo aprendido al kit

Durante todo el proyecto, cada vez que corriges algo que el agente hizo siguiendo el kit, le
pides lo mismo por segunda vez, haces a mano un paso que podría hacer él, o el kit no decía
qué hacer, el agente lo anota en `context/KIT_FEEDBACK.md` (si ya estaba, suma una "vez").
No tienes que pedírselo.

Cuando quieras (y siempre al cerrar la fase 09), en el proyecto:

```
/kit-feedback
```

Arma el informe con lo que no se había enviado (agrupado por pieza del kit, lo más repetido
primero) y abre un PR en el repo del kit con la etiqueta `kit-feedback`. No clona el kit ni
toca tu copia local.

Los PRs de varios proyectos se juntan ahí. Cuando quieras procesarlos, abre una sesión de
Claude Code en la carpeta del kit y escribe:

```
Revisa el feedback
```

Su `CLAUDE.md` le dice cómo: un triaje de todos los PRs a la vez (lo repetido entre
proyectos suma, qué ya está resuelto, qué es propio de un proyecto), te deja elegir qué
entra, lo implementa, sube la versión, escribe en `ACTUALIZACIONES.md` los pasos para los
demás proyectos y comenta en cada PR de feedback qué entró. Tú mergeas: el de la mejora y
los de feedback (quedan en `feedback/` como histórico). Después, `/kit-update` en cada
proyecto.

---

## 5. Comandos del día a día

| Comando | Para qué |
|---|---|
| `bun run test:related` | Solo los tests afectados por lo que cambió (por imports reales) |
| `bun run test` | Toda la suite (antes del PR; CI la corre siempre) |
| `bun run lint` / `bun run format` | Biome |
| `bun run shots` | Capturas de los estados definidos en `.pr-shots.json` (usa node + Playwright) |
| `bun run shots:publish` | Sube las capturas a la rama `pr-shots` e imprime el markdown del PR |
| `bunx playwright install chromium` | Una vez por máquina, antes de la primera captura o auditoría |

Normalmente no los corres tú: los corren las skills. Están para cuando quieras comprobar algo.

---

## 6. Qué mantener y qué no tocar

- **`context/CURRENT_PHASE.md`** es un tablero (≤ 60 líneas): lo abierto, lo que bloquea, lo
  que sigue. Si crece, lo cerrado se mueve a `PHASE_LOG/<rama>.md`. Los agentes lo podan al
  cerrar cada unidad; si ves que no, pídeselo.
- **`context/decisions/`**: un archivo por decisión; su primera línea es la fila del índice
  (`grep -rh "^# D" context/decisions/`). Lo decidido no se re-litiga; si cambias de
  opinión, se registra una decisión nueva y la vieja queda `Obsoleta → D0NN`.
- **`context/CONTENT_CHECKLIST.md`**: todo el texto/imagen provisional. Es tu lista de lo que
  el cliente tiene que mandar antes de publicar.
- **La rama `pr-shots`** acumula capturas. Borrarla cuando pese es decisión tuya
  (`git push origin --delete pr-shots`); los agentes nunca borran ramas.

---

## 7. Problemas conocidos

| Síntoma | Causa | Qué hacer |
|---|---|---|
| "Agent type 'feature-worker' not found" | La sesión se abrió antes de instalar/editar el agente | Sesión nueva |
| Playwright se queda colgado al lanzar Chromium | Script de Playwright corrido con `bun` en Windows | Con `node` (los scripts del kit ya lo hacen) |
| `bun test` falla sin tests | No hay archivos de test todavía | El script `test` usa `./tests/unit --pass-with-no-tests` |
| `tsc`/`next build` falla en `scripts/*.ts` | Faltan `@types/bun` o `@playwright/test` | `bun add -d @types/bun @playwright/test` (el script de arranque ya lo hace) |
| El `.ps1` no corre | Política de ejecución de PowerShell 5.1 | `pwsh`, o `-ExecutionPolicy Bypass -File` solo para esa ejecución |
| `next dev` vuelve a escribir `AGENTS.md` | Next.js 16 lo regenera | Normal: se commitea con el resto; `CLAUDE.md` lo importa con `@AGENTS.md` |
| `tsc` en CI: "Cannot find name LayoutProps" | Next 16 genera esos tipos en `.next/` al hacer dev/build | `bun run typecheck` = `next typegen && tsc --noEmit` (ya en el script de arranque y el CI) |
| Un worker no pudo escribir en `context/` local | Los worktrees en sandbox no escriben en la carpeta principal | Lo entrega en su informe y el orquestador lo copia |
| `wt take`: "No hay slots libres" | Todas las carpetas del pool tienen una unidad abierta | Esperar a que se mergee una (`wt free`) o ampliar: `wt init -Count 6` |
| `wt free` aborta | El slot tiene cambios sin commitear | Ver qué son (`wt status`); nunca se descartan solos |
| El pool va lento (install, borrados) | Windows Defender escanea cada archivo de `node_modules` | Excluir la carpeta de trabajo, `..\<repo>-wt` y `%USERPROFILE%\.bun\install\cache` |
| No aparece el PR de versión | La Action no tiene permiso para abrir PRs | Settings › Actions › General › "Allow GitHub Actions to create and approve pull requests" |
| El PR de versión no tiene el check `ci` | Los PRs abiertos con `GITHUB_TOKEN` no disparan `pull_request` | `ci.yml` con `workflow_dispatch` y `release.yml` con el paso "CI del PR de versión" y `actions: write` (plantillas del kit). Mientras tanto: Actions › CI › Run workflow sobre `changeset-release/main` |
| `changeset version` no sube la versión | App `private: true` sin `privatePackages.version: true` | Usar el `config.json` del kit (`changeset-templates/`) |
