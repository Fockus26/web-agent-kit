# Informe de feedback — proyecto kit-deploy — kit 3.25.0 — 2026-11-22

Stack: Next.js 16 · Postgres + Drizzle + Better Auth (passkey + TOTP) · bun · Windows 10 (pool de worktrees con PowerShell 7)

## Skill `security-review` desde un slot del pool
- [Fricción ×9] Lee `git status`/`git diff` de la carpeta principal (vacío o de otra rama) en lugar del slot del worker; los workers lo rehacen a mano sobre `git diff origin/main...HEAD` → propuesta: que la skill acepte una ruta de diff o una rama como argumento, o que use el cwd del worktree. Ya se pasó `.qa/review.diff` por argumento y la skill lo ignoró igual.
  Evidencia: Fockus26/kit-deploy#82, #83
- [Bug ×1] Lo mismo en W5: la rehizo con un subagente sobre el diff del slot → propuesta: la misma; mientras tanto, el brief dice que el worker revise `.qa/review.diff` directamente sin invocar la skill.

## `orchestrate` › brief y prompts de workers
- [Fricción ×3] Con 5 slots ocupados en una laptop, la suite completa tarda ~450 s y typecheck >3 min; timeouts espurios de 5 s en tests del agente → propuesta: escalonar las suites completas (o que CI sea la corrida completa) y subir el timeout de esos tests.
- [Fricción ×2] Un corte de red (ENOTFOUND) cortó a un worker y a un QA a la vez; se reanudaron con SendMessage → propuesta: el brief insiste en informes parciales y commits tempranos (lo tenían, y reanudar fue barato).
- [Hueco ×1] §4: "Migración: ninguna" para una unidad que agrega una acción de auditoría; el CHECK lista las acciones, así que necesita migración → propuesta: reservar número de migración siempre que el prompt pida una acción de auditoría o un valor de enum nuevo.
- [Fricción ×1] §4: "Docker: sí (solo install test)" + "Build local: no" se contradicen: el install test corre `next build` en Docker; con otro install test en paralelo, apt tardó >30 min → propuesta: un install test cuenta como build local; uno solo a la vez entre sesiones, o imagen base con Postgres preinstalado.
- [Hueco ×1] Regla 13: un subagente que espera >10 min: Monitor expira y los `until` hay que relanzarlos cada 2 min; el PR salió con el install test PENDIENTE → propuesta: abrir el PR con los checks largos marcados pendientes y actualizar con `gh pr edit`; el orquestador es dueño del resultado final.
- [Fricción ×1] Playwright sobre `qa:local` en dev: cada ruta tardó 1–3 min en compilar en frío → propuesta: timeouts ≥10 min o `qa:local -- --preview`.
- [Fricción ×1] Un worker marcó una decisión como reemplazada en la carpeta principal (la ensució) y luego la rehízo en el slot → propuesta: los archivos versionados (decisiones incluidas) solo se editan en el slot.
- [Fricción ×1] Parar el `qa:local --preview` de un slot: `pkill -f` bloqueado por el clasificador; matar solo el listener deja el servidor huérfano → propuesta: parar por PID desde `netstat -ano` del puerto (`taskkill /T`); avisar que `--preview` reconstruye en cada cambio.
- [Fricción ×1] Un worker corrió `biome lint` solo en los archivos tocados y CI falló en un script nuevo de `scripts/qa/` → propuesta: `bunx biome check <cada archivo nuevo o tocado>`, `scripts/` incluido.
- [Hueco ×1] Dos slots con build local a la vez: `next build` se colgó y tardó 17 min → propuesta: nunca "Build local: sí" a dos slots al mismo tiempo.
- [Fricción ×1] Los comandos en primer plano pasan a segundo plano a ~180 s aunque el `timeout` sea mayor → propuesta: el brief dice que se espere solo con `run_in_background` + notificación.
- [Fricción ×1] Regla 9: `bun test` pasado por `| tail` bajo `timeout` terminó sin salida y exit 0 (falso verde) → propuesta: siempre `> .qa/x.log 2>&1` y leer el archivo, también para un solo archivo de test.
- [Fricción ×1] Regla 11: esperar typecheck sin `sleep` exigió armar un Monitor o un `until`; dos vueltas extra → propuesta: el brief trae la línea exacta (`until grep -q '^exit' .qa/x.log; do sleep 3; done` con run_in_background).
- [Fricción ×1] Build de producción de `qa:local --preview` ~15 min en una máquina cargada para una unidad solo de CSS → propuesta: el brief da el tiempo esperado; permitir `next dev` para unidades de CSS puro.

## `reference/QA-PREVENTION.md`
- [Hueco ×1] Tablas: `td` con `[overflow-wrap:anywhere]` parte palabras de estado y SHAs letra a letra en móvil; `min-w-48` en rem dentro de filas flex desborda con fuente al 200 % → propuesta: nowrap en celdas de tokens cortos + tabla `min-w-max`, `anywhere` solo en texto libre; `min-w-0` en filas flex; probar con `Page.setFontSizes` 32 px.
- [Hueco ×1] Colores forzados: un botón primario relleno sin borde desaparece; alturas sueltas `h-8`/`h-10` se saltan el token de control → propuesta: variantes rellenas con `border border-transparent`; el check del kit busca alturas sueltas bajo `md:`.
- [Hueco ×1] Formularios con Server Actions: un Radix Select controlado se reinicia con el `form.reset()` de React tras la acción (se emitió el token del proyecto equivocado); un aviso de éxito colgado de `onCloseAutoFocus` de una fila que se desmonta; `useActionState` sin try/catch manda los fallos de red al error boundary → propuesta: tres reglas de prevención + la guarda `scripts/qa/select-after-rejected-submit.mjs` como plantilla.
- [Hueco ×1] Combobox Popover+Command: Tab desde el buscador queda atrapado (FocusScope `loop` con un solo enfocable) → propuesta: Tab desde el buscador cierra el popover y mueve el foco al campo siguiente.
- [Hueco ×1] Control propio con input oculto: el `required` nativo no aplica; tras el «Falta…» del servidor el foco cae en `<body>` → propuesta: bloquear el envío en el cliente y enfocar el control; tras un rechazo del servidor, enfocar el primer campo con error.
- [Hueco ×1] Credencial externa caducada: un 401/403 de GitHub muestra el mismo aviso que una caída y no registra nada → propuesta: texto distinto para credencial caducada; registrar el estado una vez, nunca el valor.

## `qa:local` y ayudantes de QA
- [Fricción ×1] Docker Desktop colgado ~25 min; `qa:local` falló a los 30 s → propuesta: esperar/reintentar la conexión al daemon con un mensaje claro.
- [Fricción ×1] Postgres de QA ~10 min en recuperación tras volver Docker; `qa:local` se rindió con "Sin Docker…" → propuesta: detectar "database system is in recovery" y esperar más, con ese mensaje.
- [Bug ×1] Un `.qa/session-a.json` viejo de otra base se tomó como válido (el repro se colgó 10 min en /login); setup-accounts suponía que la cuenta B existía → propuesta: `signedIn` comprueba la URL final; `qa:local` sin `--no-reset` borra `.qa/session*.json`; cuenta B opcional.
- [Bug ×1] Localizadores de combobox cmdk: `getByRole('combobox',{name:…})` también encuentra el input de cmdk; `getByLabel` no lo encuentra → propuesta: ayudantes con `exact: true` o placeholder.

## Pool de worktrees (`wt.ps1`)
- [Fricción ×1] Un slot empezó con el `.qa/` del worker anterior (scripts, sesión caducada) → propuesta: `wt take` / `wt free` limpian `.qa/` entre unidades.

## `scripts/pr-screenshots.ts` + `publish-pr-shots.sh`
- [Bug ×1] `waitFor` sobre un selector dentro de una sección con Suspense expiró aunque el elemento existía; `shots:publish` subió los PNG de la unidad anterior que quedaban en `.pr-shots/` → propuesta: arreglar waitFor; limpiar `.pr-shots/` antes de `shots` (o que `wt take` lo limpie).

## Kit `design-qa.ts`
- [Bug ×1] Una hoja medida a mitad de animación dio un desborde falso a 300 ms; no hay fase fija de corte de palabra con Range → propuesta: esperar `animationend` antes de medir `position: fixed`; agregar la fase de corte de palabra con Range.

## `UPDATES.md` 3.23.0 paso 2 + `kit-update` §8
- [Fricción ×1] `new-project.ps1 -OnlyPieces` ya refrescó `.claude/skills`, `agents` y `kit-reference`, así que el paso `install-kit --project .` no tenía nada que hacer y la copia del kit quedó sin commit junto a los archivos de 3.23.0 → propuesta: decir que `-OnlyPieces` refresca la copia del kit y que se commitea aparte al final.

## `tech/migrate-*-vps.md` › copiar variables desde Vercel `[Tech: vercel]`
- [Hueco ×1] Vercel devuelve `[SENSITIVE]` para variables sensibles; la copia guardó ese texto literal en 9 secretos y nada falló hasta que un correo no llegó → propuesta: tras copiar, comprobar que ningún valor sea `[SENSITIVE]` ni vacío; `kit-deploy env set` rechaza ese literal.

## Lo que funcionó bien y no hay que tocar
- El pool de worktrees + brief compartido en disco: dos unidades de auth en paralelo con un archivo compartido fijado byte a byte se mezclaron sin conflicto (Fockus26/kit-deploy#82, #83).
- Mergear en un slot libre las ramas de la ola antes del merge y correr typecheck/lint/tests/build juntas detecta choques sin depender del CI.
