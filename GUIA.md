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

$kit = "$env:USERPROFILE\Desktop\agents\web-agent-kit"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills","$env:USERPROFILE\.claude\agents"
Copy-Item "$kit\.claude\skills\*" "$env:USERPROFILE\.claude\skills\" -Recurse -Force
Copy-Item "$kit\.claude\agents\*" "$env:USERPROFILE\.claude\agents\" -Force
```

Luego:

1. **Abre una sesión nueva de Claude Code.** Los agentes se cargan al arrancar; una sesión
   que ya estaba abierta no los ve.
2. Comprueba con `/skills` (7) y `/agents` (3: `feature-worker`, `design-qa`, `functional-qa`).
3. Conecta el MCP de **Context7** (documentación al día de las librerías).
4. Requisitos: **bun**, **Node ≥ 23.6** (para los scripts de Playwright), **git**, **gh**
   autenticado, **PowerShell 7** (`pwsh`).

### Actualizar el kit

```powershell
cd "$env:USERPROFILE\Desktop\agents\web-agent-kit"; git pull
# y vuelve a copiar .claude\skills y .claude\agents como arriba, luego sesión nueva
```

Los proyectos ya creados no cambian solos: si quieres una plantilla nueva en uno, cópiala a
mano o pídeselo a Claude.

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
5. Formatea lo copiado con el Biome del proyecto.

No pisa nada que ya exista y **no commitea**. Después:

```powershell
cd C:\Users\Admin\Documents\Work\clinica-dental
git status                      # revisa
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

### Proyecto que seguía la versión anterior del kit

Abre Claude Code en el proyecto (sesión nueva) y pega el bloque de
`prompts/ACTUALIZAR-PROYECTO.md`: diagnostica, migra a Changesets, alinea `CLAUDE.md`, la
plantilla de PR, las decisiones y las memorias, y lo deja en un PR `chore/changesets`.

Si el proyecto ya usa Changesets pero tiene `context/DECISIONS_INDEX.md` (o el PR de versión
se queda sin el check `ci`), pega el de `prompts/MIGRAR-DECISIONES-Y-CI.md`: pasa las
decisiones a un archivo cada una y hace que el CI corra sobre el PR de versión. Lo deja en un
PR `chore/decisiones-y-ci`. Si el proyecto es más viejo todavía, primero
`ACTUALIZAR-PROYECTO.md` y después este.

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
   librería de componentes: shadcn/ui, Hero UI o MUI).
2. Lo visual **te lo propone** con 3 direcciones (p. ej. "editorial sobrio / técnico /
   cálido"), con ventaja y riesgo de cada una. Eliges o le dejas elegir.
3. Entra en **modo plan**: resumen, track de fases (aquí *Landing*), secciones, paleta con
   contrastes medidos, arquitectura, riesgos. **Tú apruebas el plan.**
4. Rellena `context/` y `CLAUDE.md` con los datos reales (nada de `{{...}}`; lo que falte
   queda `PENDIENTE` + fila en `CONTENT_CHECKLIST.md`).
5. Te entrega **el brief para Claude Design** en un bloque listo para copiar.

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
5. Cuando quieras publicar, mergeas el PR **`chore(release): versión`** que mantiene la
   Action: junta los changesets, sube la versión y escribe el CHANGELOG.

Mientras tanto puedes seguir con otra cosa. Lo que se te ocurra después va a
`context/plans/pendientes.md`, no a la tanda en curso.

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
