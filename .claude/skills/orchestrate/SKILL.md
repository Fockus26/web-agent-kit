---
name: orchestrate
description: Orquestador de tandas y fases. Úsala cuando César llega con una lista de varias cosas a la vez, cuando arranca una fase para hacerla en olas, o cuando pide "la ola N" / "inicia la tanda". Mapea cada pedido al código, agrupa por archivos que se tocan, ordena en olas (una por sesión), reserva números, toma un slot del pool por unidad, hace de una vez las preguntas que bloquean, lanza workers feature-worker en segundo plano, consolida sus PRs, tras el merge lanza wave-qa con las cuentas de prueba, y cierra la ola diciendo en qué fase y ola se está y qué ola sigue.
---

# Orquestar una tanda

Tú planificas; los workers ejecutan. Tu trabajo caro (leer código, decidir agrupaciones,
escribir prompts precisos) se hace **una vez**; cada worker arranca en frío y solo lee lo
que su prompt le señala. Por eso tú vas con esfuerzo alto y ellos con medio (ver
`reference/TOKEN-ECONOMY.md` §11-12).

Requisito: los agentes `feature-worker` y `wave-qa` instalados (`~/.claude/agents/` o `.claude/agents/`)
**antes de abrir la sesión**. Los agentes se cargan al arrancar: uno creado a mitad de
sesión da "Agent type not found" hasta que se abre una sesión nueva.

Los workers trabajan en el **pool de worktrees** que gestiona `scripts/wt.ps1` (en esta
carpeta; PowerShell 7). En esta skill, `wt` es:

```bash
pwsh -NoProfile -File "$USERPROFILE/.claude/skills/orchestrate/scripts/wt.ps1" <comando>
```

(Con el kit instalado en el proyecto, la ruta es `.claude/skills/orchestrate/scripts/wt.ps1`.)

**Una ola por sesión.** César usa "ola" y "tanda" para lo mismo: un grupo de unidades que
corren en paralelo, se mergean y pasan QA juntas. Cada ola vive en su propia sesión: la
que la lanza acumula mapeo, prompts e informes, y arrastrar eso a la ola siguiente cuesta
tokens en cada mensaje sin aportar nada (`reference/TOKEN-ECONOMY.md`). Lo que la ola
siguiente necesita va a disco (§9).

| César dice | Qué haces |
|---|---|
| una lista de pedidos | §1-§7 sobre la lista. Si sale más de una ola, el plan en olas va a `context/plans/tanda-<fecha>.md` (misma plantilla que una fase) |
| "fase 0N" / "arranca la fase 04" | §0 y luego la ola 1 |
| "ola N de la fase 0N" (el prompt de arranque) | lee **solo** el plan y `CURRENT_PHASE.md`, y §1-§7 para las unidades de esa ola |

---

## 0. Partir una fase en olas

Con `phases/0N-*.md` del proyecto, el inventario que toque y el handoff de esa fase (por
partes, no entero): lista las unidades, agrúpalas en olas con las reglas de §3 y escribe
`context/plans/fase-0N-<nombre>.md` (plantilla: `fase-plan-template.md` en esta carpeta).
Una línea por unidad: rama, qué, archivos principales. Los prompts detallados **no** van
aquí: los escribe la sesión de cada ola, sobre el `main` que dejó la anterior.

En `CURRENT_PHASE.md`, "Ahora" pasa a: fase, ola en curso de cuántas, y la ruta del plan.

## 1. Mapear cada pedido al código

Por cada punto de la lista, localiza dónde vive (grep, rangos, no archivos enteros): qué
archivos toca, qué decisiones previas lo condicionan (`grep -rhi "^# D.*<tema>" context/decisions/`),
qué trampas conocidas hay. Anota ruta:línea — irá al prompt.

Contra lo que hay en `origin/main`, no contra tu copia: `git fetch` antes de mapear. Y antes
de convertir un pedido en prompt, comprueba que sigue haciendo falta y que se puede hacer
como lo vas a pedir:

- **¿Ya está hecho?** Una migración pendiente puede estar ya en
  `git ls-tree --name-only origin/main supabase/migrations/` (y aplicada: `list_migrations`
  del MCP). Un pendiente viejo no es un pedido vigente.
- **¿Contradice una decisión implementada?** Si el pedido trae valores (bandas, topes,
  colores), busca la decisión del tema y compáralos; si no coinciden, es una pregunta de
  §2, no un prompt. (Se pidieron 5 bandas cuando la decisión implementada usaba 4 topes.)
- **¿Hay con qué verificarlo?** Antes de pedir un test de DOM, mira si el proyecto tiene
  entorno de DOM para tests (`happy-dom`/`jsdom` en `package.json`); si no, pide "verificar
  midiendo con Playwright". Antes de llamar bug a algo, mídelo (p. ej. dos clases `font-*`
  que `cn` ya resuelve no son un bug).
- **¿Hay una imagen de por medio?** Ábrela antes de proponer su `alt` o su texto: un alt
  escrito sin verla no describe nada.

Señales de que un pedido es más grande de lo que parece:
- Toca datos guardados o la base (merge, migraciones, columnas) → necesita tests de la capa
  pura y probablemente acción manual.
- Cambia una regla que afecta datos ya existentes (p. ej. un castigo que vuelve
  incomparables los tiempos guardados) → pregunta qué hacer con lo viejo.
- Es transversal (estilos de foco, hover, tokens) → toca muchos archivos: va al final.
- Es de otro sistema (plantilla de correo en un dashboard, config externa) → no es un PR:
  el worker prepara los archivos y César los aplica.

## 2. Preguntar lo que bloquea — una vez, al principio

Los workers corren en segundo plano y **no pueden preguntar**. Todo lo que cambie qué
hacen se pregunta ahora, en una sola tanda (máx. 4 preguntas, con opción recomendada):

- ¿Pueden levantar su propio servidor de desarrollo (cada uno en su puerto)?
- ¿Pueden aplicar cambios **aditivos** en la base (columnas nuevas) vía MCP, o los deja
  escritos para César?
- Decisiones de producto que el pedido deja abiertas y que cambian el diseño de la unidad.

No preguntes por la QA de cierre: el servidor y las cuentas de prueba de `wave-qa` ya están
autorizados (§8).

Lo demás (detalles visuales, copy) lo decide el worker de forma conservadora y lo deja
explicado en el PR con su alternativa.

## 3. Agrupar y ordenar

- **Agrupa** lo que toca los mismos archivos o gira alrededor de la misma pieza (ranking:
  top N + avatares + skeleton + la regla que lo alimenta = una unidad).
- **Separa** lo independiente: cada unidad = una rama = un PR, revisable en poco tiempo.
- **Olas:** unidades que se pisan (mismos archivos) van en olas distintas; lo transversal
  (estilos globales, cabeceras compartidas de modales) va en la última, sobre `main` ya
  actualizado.
- Una unidad sin código de repo (plantilla externa) corre sin slot del pool ni PR.

## 4. Reservar números

Para que las unidades en paralelo no choquen, asigna a cada una:

| Qué | Ejemplo |
|---|---|
| Rama | `feat/ranking-top20` |
| Rango de IDs de decisión (un archivo por ID) | D075–D079 |
| Filas de `CONTENT_CHECKLIST` | 26–27 |
| Salto del changeset | `minor` (o `ninguno`) |
| Rango de códigos de error propios, si el proyecto los usa (SQLSTATE de `raise … using errcode`) | MS010–MS014 |

**Los IDs se reservan contra `origin/main`**, no contra la carpeta local, que puede ir
atrasada (se reservó D186 mirando `context/decisions/` sin pull y ya existía en `main`):

```bash
git fetch origin --quiet
git ls-tree --name-only origin/main context/decisions/ | sort | tail -3
```

Y por encima de eso, los rangos reservados en PRs aún abiertos de otra tanda, si los hay.

El slot y su puerto no se reservan aquí: los da `wt take` al lanzar (wt2 → 4302, §6).

Versiones: ya no hay números que reservar ni orden de merge por versión. Ningún PR toca
`version` ni `CHANGELOG.md`: cada unidad con cambio visible agrega su `.changeset/<desc>.md`
con su salto, y la Action del proyecto los junta en el PR de versión (ver `git-flow` §2.1).
Dos changesets en paralelo no chocan: son archivos distintos. Tú decides el salto de cada
unidad y va en su prompt.

## 5. Escribir el brief y los prompts — en disco

Dos archivos en `context/plans/` (local):

- `orquestacion-<fecha>.md` — **brief común** (plantilla: `brief-template.md` en esta
  carpeta): tabla de unidades, olas, números reservados y las reglas de la tanda.
- `orquestacion-<fecha>-prompts.md` — **un prompt por unidad** (plantilla:
  `unit-prompt-template.md`): qué pidió César (cita literal), dónde está el código
  (ruta:línea), decisiones que condicionan, trampas conocidas, enfoque ya decidido,
  cómo verificar, cierre.

En disco y no solo en el mensaje: sobreviven a un reinicio de sesión y al worker le basta
con "tu prompt es la sección W3 de ese archivo" — lo escribes una vez, no dos.

Guarda también una memoria del proyecto que apunte a esos dos archivos y al plan de la
fase o tanda, y diga en qué ola va.

## 6. Lanzar

Sin `isolation: "worktree"`: crearía y borraría un worktree (y su `node_modules`) por
unidad. Cada unidad con código toma un slot del pool, desde la carpeta principal y **una
tras otra** (en paralelo elegirían el mismo slot):

```bash
wt take feat/ranking-top20
# slot=wt2 · rama=feat/ranking-top20 · ruta=C:\…\<repo>-wt\wt2 · puerto=4302
```

`wt take` crea la rama desde `origin/main` (o la retoma si ya existe), instala solo si
cambió `bun.lock` y refresca los `.env*`. Si no quedan slots libres, las unidades que
sobran esperan a la ola siguiente, o se amplía el pool con `wt init -Count <N>`.

```
Agent(
  subagent_type: "feature-worker",
  run_in_background: true,
  description: "W3 modales",
  prompt: "Trabaja SOLO en `C:\…\<repo>-wt\wt2` (rama feat/…, ya creada); tu puerto es 4302.
           Tu prompt completo es la sección '## W3 — …' de <ruta>/orquestacion-<fecha>-prompts.md.
           Léela entera y síguela. Resumen para orientarte: …(3-4 líneas)"
)
```

Una unidad sin código de repo no toma slot. Todas las unidades de una ola en el **mismo
mensaje** (corren en paralelo). No sondees: te avisan al terminar.

## 7. Consolidar

Cuando llega cada informe:

- Copia su `PHASE_LOG` y los archivos locales que dejó (SQL, plantillas) a la carpeta
  principal si el worker no pudo escribir ahí (un worktree en sandbox no suele poder).
- Actualiza `CURRENT_PHASE.md` (una fila por PR, tablero corto) y `CONTENT_CHECKLIST.md`.
- Pasa su "Feedback para el kit" a `context/KIT_FEEDBACK.md` (si ya hay una fila del mismo
  problema, suma a "Veces"). Si varios workers tropezaron con lo mismo, es una señal fuerte:
  dilo en el resumen a César.
- A César: tabla de PRs (número, salto patch/minor/major o ninguno, qué cambia, slot),
  orden de merge solo si una unidad depende de otra, decisiones abiertas y acciones
  manuales. Nada más.
- Pedidos que surgen después → `context/plans/pendientes.md`, no la tanda en curso.

Cuando César pide cambios en un PR o `main` avanzó: continúa al worker con `SendMessage`
(conserva su contexto) en vez de lanzar uno nuevo. El slot sigue siendo suyo hasta el merge.

Tras el merge de cada PR: `wt free <slot>`. Vuelve a `origin/main` detached y borra la rama
local si ya está mergeada; `node_modules` se queda. Si `free` aborta por cambios sin
commitear, pregúntale al worker qué son antes de tocar nada.

El PR `chore(release): versión` lo abre la Action y lo mergea César cuando quiere publicar:
no es de la tanda, ni tú ni los workers lo editan o mergean.

La ola no se cierra con PRs abiertos. Cuando César diga que están mergeados (compruébalo:
`gh pr view <n> --json state`), libera sus slots y sigue con §8.

## 8. QA de la ola

Cuando **todos** los PRs de la ola están mergeados. Una QA por ola, no por PR: lo que
nadie ha probado son las unidades juntas, en `main`, con sesión iniciada.

```bash
wt take qa/f0N-ola-N        # rama sin commits sobre origin/main: reserva el slot
```

```
Agent(
  subagent_type: "wave-qa",
  run_in_background: true,
  description: "QA ola N fase 0N",
  prompt: "Slot `C:\…\<repo>-wt\wt1` (main @ <sha>), puerto 4301. Carpeta principal: `…`.
           Fase 0N, ola N. PRs: #12 (W1 hero: <su 'Cómo probarlo' en 2 líneas>), #13 (…).
           Flujos con sesión o datos: <cuáles y qué rol los usa>.
           Costuras: <#12 y #13 tocan la misma página X>."
)
```

No hace falta repetirle lo que el agente ya trae: levanta su servidor con `bun run
qa:local` contra la base local (Supabase en Docker; nunca la real); inicia sesión con
`EMAIL_TEST`/`PASSWORD_TEST`, `ADMIN_EMAIL_TEST`/`ADMIN_PASSWORD_TEST` y
`<ROL>_EMAIL_TEST`/`<ROL>_PASSWORD_TEST` de `.env.test.local` sin ver los valores. Si Docker
no está abierto, lo dirá como acción de César: no lo arranques tú.

**Sin base local posible** (la máquina no tiene Docker, o el proyecto aún no tiene
`supabase/config.toml` ni migraciones): la ola no se queda bloqueada. Lánzalo igual, con
"sin base local: `qa:local -- --offline`" en el prompt; prueba como invitado con las
variables de la base apuntando a ninguna parte. En el cierre (§9), "QA: solo invitado —
<motivo>", y la QA con sesión de esa ola pasa a "Bloquea" hasta que haya base local.

Con el informe:
- Guárdalo en `context/plans/qa-ola-0N-N.md` y `wt free` del slot de QA.
- **Crítico o Alto** → unidad de arreglo al principio de la ola siguiente. Si bloquea lo que
  se construye encima, es una ola de arreglo propia antes de la siguiente planificada.
- **Medio o Bajo** → `context/plans/pendientes.md`.
- **Datos sin borrar** y **acciones de César** → "Bloquea" de `CURRENT_PHASE.md`.
- Su "Feedback para el kit" → `context/KIT_FEEDBACK.md`, como el de los workers.

Si hay flujos con login y `.env.test.local` no tiene cuentas de prueba: lánzalo igual
(prueba lo público y lo marca), y en el cierre pide a César que las ponga (`backend-build`
§2, Secretos).

## 9. Cerrar la ola y pasar a la siguiente

1. Plan de la fase: estado de la ola, fila de "Cierres", arreglos añadidos a la ola
   siguiente, y el **prompt de arranque** de la siguiente.
2. `CURRENT_PHASE.md`: "Ahora" con la fase y la ola siguiente; "Bloquea" con lo de la QA.
3. A César, y nada más:

```
**Fase 04 — Secciones · ola 2 de 3 cerrada**
PRs mergeados: #12 hero · #13 servicios
QA: 0 críticos · 1 alto · 2 medios — el alto pasa a la ola 3 (doble envío del formulario)
Bloquea: <datos sin borrar / cuentas que faltan / nada>

**Sigue: ola 3 de 3** — fix doble envío · `feat/testimonios` · `feat/precios`
Para lanzarla: "inicia la ola en otra sesión"
```

Si era la última ola, "Sigue" es la fase siguiente del track (su ola 1 empieza por §0).

4. Cuando César diga "inicia la ola/tanda en otra sesión" (o lo equivalente):
   - Comprueba antes que todo lo que la ola siguiente necesita está en disco (plan,
     `CURRENT_PHASE.md`, `pendientes.md`): la sesión nueva no ve esta conversación.
   - Si tienes la herramienta de la app para abrir otra sesión (en la app de escritorio,
     `start_session`), ábrela en la carpeta principal con el prompt de arranque como primer
     mensaje y dile a César cuál es. Esta sesión no lanza nada más.
   - Si no la tienes: el prompt de arranque en un bloque, para pegarlo en una sesión nueva
     abierta en el proyecto.

## 10. Lo que ya se aprendió (no lo redescubras)

- **Archivos locales compartidos:** los workers no editan `CURRENT_PHASE` ni
  `CONTENT_CHECKLIST` (se pisarían); escriben su propio `PHASE_LOG/<rama>.md` o lo
  entregan en el informe.
- **Primer uso en un proyecto:** `wt init` (4 slots; `-Count` para más). Cuesta un
  `bun install` por slot, una sola vez. `wt status` dice qué slot tiene qué rama.
- **Lo gitignored en el pool:** `wt` ya copió los `.env*` de la carpeta principal a cada
  slot (y los refresca en cada `take`); nunca se commitean. `context/` local no se copia: el
  prompt dice dónde está la carpeta principal.
- **Para que el pool vaya rápido** (acción manual de César, no del agente; recomiéndasela la
  primera vez): excluir de Windows Defender la carpeta de trabajo, la del pool
  (`..\<repo>-wt`) y `%USERPROFILE%\.bun\install\cache`; y activar en GitHub *Settings ›
  General › Automatically delete head branches*.
- **`.env` de producción:** los `feature-worker` verifican como invitados; no inician
  sesión, no crean cuentas ni escriben datos reales. Para estados que dependen de datos
  (rankings, listas largas), interceptan la respuesta en el navegador solo para depurar. La
  prueba con sesión y datos es de `wave-qa`, tras el merge (§8), con las cuentas de prueba.
- **Navegador compartido:** cada worker crea su propia pestaña y pasa su `tabId`.
- **Operaciones destructivas en la base** (DELETE de filas viejas): las escribe el worker,
  no las ejecuta; y el clasificador de seguridad puede bloquearlas también al orquestador
  → quedan como acción de César, con el SQL exacto.
- **Limpiar datos que el cliente vuelve a subir** (un ranking que el cliente resube en cada
  carga) no se arregla borrando filas: hace falta que el cliente nuevo invalide lo viejo y
  que clientes viejos cacheados escriban donde nadie lee (claves versionadas internas).
- **Playwright se corre con node**, no con bun (en Windows se cuelga).
