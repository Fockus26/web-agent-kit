# Informe de feedback — proyecto Iglesia Maranatha — kit 3.25.0 — 2026-11-22

Stack: Next.js 16 (App Router) + TypeScript · Postgres (Drizzle) + Better Auth · bun · Windows 10 (Git Bash / PowerShell)

60 puntos (filas 5–64 de `context/KIT_FEEDBACK.md`; las 1–4 ya fueron en el informe del 2026-10-16).
Casi todo sale de la fase de migración MUI → shadcn/ui en 5 olas de workers en paralelo y del QA de versión 09.

## orchestrate — brief-template (servidor, Playwright, backend simulado, trampas) — ×19
- [Fricción ×5] Con 3–4 slots en paralelo, la primera compilación de `next dev` tardó de 40 s a más de 5 min; `networkidle` y hasta `load` (fuentes de Google sin red) colgaron los scripts; un servidor colgado tras un corte siguió ocupando el puerto; rellenar el login antes de hidratar falla → propuesta: en el brief (reglas 6–7), calentar rutas con `curl` antes de medir, `waitUntil: "commit"`/`"load"` con espera a un elemento y timeout largo, mirar el puerto con `Get-NetTCPConnection` y matar solo el proceso propio; un helper de login para `qa:local`.
- [Fricción ×3] En disco lento la 1ª compilación de `next dev` tarda ~3 min y `chromium.launch()` agota 180 s → propuesta: sugerir `--disable-gpu` y `timeout` alto en los scripts `.qa` (regla 7).
- [Hueco ×3] Sin `DATABASE_URL` el paso 2 de pagos responde `not_configured`; `next/font/google` sin red atasca la primera compilación ~30 min y las capturas salen con fuente de respaldo → propuesta: § "Simular el backend" trae un mock del loader de opciones (aquí `getCheckoutOptions`) y avisa de las fuentes (o fuentes locales en dev). `[Tech: nextjs]`
- [Prevención ×2] Workers tradujeron `sx` con valores arbitrarios `text-[44px]` y el spacing de MUI ×8 en vez de ×4 → propuesta: la tabla de traducción tokens → clases dice "`p: n` → `p-n` (n × 4 px)" y prohíbe `[…]` explícitamente, con su alternativa.
- [Fricción ×1] En dev, `page.locator('[role="dialog"]')` choca con el overlay de errores de Next → propuesta: recomendar `getByRole('dialog', { name })` o `aria-label` en los scripts `.qa`. `[Tech: nextjs]`
- [Fricción ×1] En Git Bash un heredoc sin comillas dentro de un `for`, con «», rompió el parseo del comando entero → propuesta: recomendar Write para archivos multilínea y no generar archivos dentro de bucles de shell.
- [Fricción ×1] Borrar la página temporal mientras corría typecheck dejó un TS6053 falso por `.next/types` → propuesta: borrar la página temporal antes del typecheck final y limpiar `.next/types`.
- [Fricción ×1] `next typegen` (typecheck) con el dev vivo dejó una ruta del panel en 404 hasta reiniciar; con Docker + dev el typecheck tardó ~50 min → propuesta: el brief pide typecheck y suite con el servidor parado en olas con Docker.
- [Hueco ×1] El brief pedía bajar los contenedores al terminar, pero `qa-<paquete>-pg`/`-mailpit` los comparten todos los slots → propuesta: el worker solo para su servidor; el orquestador baja los contenedores al cerrar la ola.
- [Prevención ×1] Los recorridos con datos (confirmar/rechazar pagos) cambiaron la base y las capturas "después" no comparan con las de "antes" → propuesta: capturar el "después" antes de los recorridos, o resembrar.

## orchestrate — SKILL (§0 plan, §1 mapeo, §3 cruces, §4 lanzamiento, prompts) — ×17
- [Corrección ×4] El orquestador citó `tests/unit/tokens.test.ts` como guardia y no existe en este repo → propuesta: verificar con `ls` cada test que se cita como trampa en un prompt.
- [Fricción ×4] 4 workers con dev server + suites a la vez saturaron la máquina (1,4 GB libres, dev sin responder 15 min, suites con timeouts falsos): 3 de 4 PRs salieron sin capturas ni axe y hubo que pedirlas en una segunda ronda escalonada → propuesta: fijar en §4 un tope de 2 servidores de desarrollo a la vez (como Docker/build) y un plan B sin servidor: compilar el CSS + `renderToStaticMarkup` + Playwright sobre `file://`.
- [Hueco ×1] §1: el prompt pedía `secondary[500]` para el anillo de foco y no pasa 3:1 sobre blanco; el worker tuvo que cambiarlo → propuesta: al pedir un color de foco/borde, calcular su contraste contra los fondos reales antes de escribir el prompt.
- [Hueco ×1] §1: el prompt pidió ver la lista de métodos de pago en el navegador, pero el slot no tiene las variables de pago ni base: sale "no habilitado" → propuesta: al mapear, comprobar qué configura el `.env` del slot; si falta, pedir la verificación por test o en el preview del PR.
- [Hueco ×1] §3: quitar una prop (`sx` de `Logo`) en una unidad rompió el typecheck de otra que la pasaba hasta que esa mergeó → propuesta: al mapear cruces, si una API pierde una prop, ordenar el merge o dejar un adaptador temporal.
- [Hueco ×1] §4: dos unidades que tocan el mismo archivo de roles duplicaron un helper (`withAlpha`) → propuesta: el brief fija también quién exporta los helpers de un archivo compartido.
- [Hueco ×1] §4: el brief fijó `max-w-prose` como token; en Tailwind v4 la utilidad estática `max-w-prose` (65ch) gana a `--container-prose` y el worker tuvo que renombrarlo a `max-w-reading` → propuesta: avisar de que `prose`/`screen`/`none` no sirven como nombre de contenedor, o validarlo con un test. `[Tech: tailwind]`
- [Fricción ×1] §4: D108–D110 chocó con un PR mergeado mientras corría la ola → propuesta: reservar IDs contra `origin/main` y los PRs abiertos justo antes de lanzar.
- [Error ×1] §0: el plan de fase citó D108–D110 para la ola 1 cuando fue D109–D111 (D108 ya existía) → propuesta: al escribir el plan, comprobar los IDs con `git ls-tree origin/main context/decisions/`.
- [Mejora ×1] §4 (Docker sí): Docker Desktop estaba apagado y nadie lo dijo; arrancarlo y recuperar Postgres costó ~25 min al worker → propuesta: el orquestador corre `docker version` antes de lanzar una unidad con Docker.
- [Fricción ×1] Ola que quita dependencias: `rm -rf node_modules/@mui` (~40 000 archivos) tras `bun remove` tardó más de 1 h en Windows y ralentizó typecheck y servidor → propuesta: dejar las carpetas huérfanas o un `bun install` limpio al final; nunca borrarlas a mano.

## QA-PREVENTION.md — ×11
- [Prevención ×1] Barra de carga que abre con `popstate`: Chrome lo dispara en `#ancla` y en atrás/adelante el router ya cambió el pathname antes del listener; quedó pegada 10 s → propuesta: cerrar comparando contra la URL comprometida (pathname+search) al abrir, nunca solo "cambió el pathname después".
- [Prevención ×1] Barra de carga que solo escucha clics en `<a>`: `router.push` no la abre → propuesta: navegar con `<Link>` o envolver el router.
- [Prevención ×1] `scrollbar-gutter: stable` en `<html>` + overlay con scroll bloqueado deja una franja vacía junto a Drawer/backdrop → propuesta: quitar el gutter con un modal abierto o compensar el ancho.
- [Prevención ×1] Con Radix: `scrollbar-gutter: stable` + bloqueo de scroll deja una franja de 12 px sin cubrir en modales y bandas a sangre (misma familia que la anterior) → propuesta: anular la compensación (`body[data-scroll-locked]{margin-right:0}`) y probar con scrollbars visibles (`ignoreDefaultArgs: ['--hide-scrollbars']`).
- [Prevención ×1] Snackbar hermano de un Drawer/Dialog abierto queda bajo `aria-hidden` y no se anuncia → propuesta: mostrar el error de la acción dentro del modal mientras esté abierto.
- [Prevención ×1] `motion-reduce:animate-none` de shadcn pierde contra `data-open:animate-in` → propuesta: regla global de reduced-motion por `data-slot`; la puerta a11y mide `animationName` con `reducedMotion: 'reduce'`. `[Tech: shadcn]`
- [Prevención ×1] Una superficie oscura fija (modal) hereda `--secondary` del modo claro: texto a 3.70:1 → propuesta: toda superficie oscura fija lleva un `data-surface="…"` y ese bloque redefine `--secondary`/`--primary`.
- [Prevención ×1] §2: reintento tras respuesta perdida choca con la clave única y se muestra como error: el usuario puede volver a pagar → propuesta: un duplicado idéntico a un registro `pending` responde `ok`; probar con `route.fetch()` + `route.abort()` y reenvío.
- [Prevención ×1] §1: el cliente valida más laxo que el servidor y el error genérico apunta a otro campo u otro paso → propuesta: mismo esquema Zod por campo en el cliente; límites de fecha al date picker; `invalid_input` dice qué campo.
- [Prevención ×1] §5: el foco cae en `<body>` cuando la acción confirmada borra el botón que abrió el diálogo → propuesta: ConfirmDialog de borrado con destino de foco explícito (`onCloseAutoFocus` + `preventDefault()`).
- [Prevención ×1] §1: un archivo de 0 bytes pasa como "sin archivo" → propuesta: `File` con `size === 0` se rechaza con su mensaje, en cliente y servidor.

## feature-worker / entorno de los slots (Windows) — ×11
- [Fricción ×5] Cortes de red (ENOTFOUND) pararon a los 4 workers de una ola de 2 a 4 veces cada uno; se reanudaron con SendMessage mirando git + `.qa/progress.md` → propuesta: el prompt del worker pide actualizar `.qa/progress.md` tras cada paso y commits `wip:` frecuentes; el orquestador reanuda sin relanzar.
- [Fricción ×2] El primer compile de dev + Playwright supera el timeout de 120 s de Bash; `MSYS_NO_PATHCONV` olvidado rompió un baseline; esperar con `until …; sleep` costó muchas llamadas → propuesta: el template pide lanzar los scripts largos en segundo plano y esperar el archivo de salida (o `Monitor`).
- [Fricción ×2] `bunx shadcn@latest` se colgó dos veces (el CLI tarda >2 min) → propuesta: `bun add -d shadcn` y `node node_modules/shadcn/dist/index.js`. `[Tech: shadcn]`
- [Fricción ×1] `wt take`: el `.qa/` del slot trae archivos de unidades anteriores (incluido `shots/`) y el publicador sube cualquier PNG → propuesta: `wt take` vacía `.qa/shots/` (o todo `.qa/`) al asignar.
- [Fricción ×1] En auto mode se deniega al worker matar por PID sus propios procesos node huérfanos → propuesta: documentar cómo limpiar los procesos propios del slot.

## Scripts de capturas (pr-screenshots.ts, shots:publish / publish-pr-shots.sh) — ×7
- [Fricción ×3] `publish-pr-shots.sh` publica PNG viejos de la carpeta; choca al empujar la rama `pr-shots` con varios slots; heredocs con backticks fallan → propuesta: avisar/fallar con PNG más viejos que la rama, más reintentos con espera; scripts con Write en `.qa/`.
- [Hueco ×2] `pr-screenshots.ts` hace clic antes de que React hidrate (Radix no abre; reintentos >1 h) y `.pr-shots/` arrastra PNG de la unidad anterior del slot → propuesta: esperar un selector hidratado (`[data-state]`) con `waitUntil: "commit"` (nunca `networkidle` en dev) y limpiar la carpeta al empezar.
- [Fricción ×1] El script de capturas no logró abrir un diálogo tras la hidratación (timeout de `waitFor`, 4 intentos) → propuesta: espera de hidratación o un ejemplo fiable de `steps` que abre un modal.
- [Fricción ×1] `shots:publish` publica en el README las capturas viejas de otras unidades que quedaron en `.pr-shots/`; hubo que filtrar a mano → propuesta: publicar solo los estados del `.pr-shots.json` actual.

## kit-update / UPDATES.md / install-kit.ps1 — ×6
- [Fricción ×2] §1: leyó `.kit-version` de la copia local (rama vieja, 3.9.0) y planeó 13 versiones; `origin/main` ya estaba en 3.21.0 → propuesta: leer la versión del proyecto con `git show origin/<base>:.kit-version` tras `git fetch`, no del working tree.
- [Fricción ×2] §9: `install-kit -Project` escribe la copia en CRLF (65 archivos) y `bun install` se colgó en un worktree de `.claude/worktrees/` (50 min en 15 paquetes; se enlazó el `node_modules` de un slot con el mismo `bun.lock`) → propuesta: que install-kit escriba LF; en kit-update, reusar `node_modules` de un slot con el mismo `bun.lock` o dejar la verificación al CI.
- [Hueco ×1] §7 / `new-project.ps1` (biome.json): con la unidad en `.claude/worktrees/<x>`, la exclusión `!**/.claude/worktrees` hace que Biome ignore todo el worktree: `bun run lint` no comprueba nada → propuesta: excluir solo desde la raíz (`!.claude/worktrees`) o decir que lint se verifica fuera de `.claude/worktrees`.
- [Hueco ×1] UPDATES.md 3.10.0–3.20.0: muchos pasos piden reemplazar el mismo script (`qa-local.ts`) o correr `-OnlyPieces` en cada versión; en un salto largo solo se puede hacer una vez con la versión publicada → propuesta: decir en §8 que en un salto de varias versiones los reemplazos de scripts y `-OnlyPieces` se aplican una vez y las demás se registran como "ya al día".

## reference/scripts/qa-local.ts — ×5
- [Fricción ×2] Con la máquina lenta, "warming /" (y el warm-up de sign-up) hace timeout y el script sale con código 1 aunque el servidor Next sigue vivo → propuesta: tolerar el timeout (aviso en vez de fallo, reintentar el sign-up) o subirlo con una variable de entorno.
- [Corrección ×1] `env.NODE_ENV = "production"` rompe `tsc` en un proyecto Next (NODE_ENV es readonly en los tipos) → propuesta: asignarlo con cast `(env as Record<string, string | undefined>).NODE_ENV`. `[Tech: nextjs]`
- [Hueco ×1] La rama Postgres no asigna `ROLE_BY_ENV` (la de Supabase sí): `ADMIN_EMAILS` queda con los correos reales; al reemplazar el script se perdía el parche del proyecto (UPDATES 3.24.0) → propuesta: añadir el bucle `ROLE_BY_ENV` tras el `Object.assign(env, …)` de la rama Postgres. `[Tech: vps-postgres]`
- [Bug ×1] `docker start` falla con "socket no permitido" justo tras arrancar Docker Desktop, y la espera de 5 min no alcanza a un Postgres en recuperación de fsync → propuesta: reintentar `docker start` 2–3 veces y seguir esperando si el log dice "syncing data directory" / "starting up".

## UI-LIBRARIES.md › shadcn / STACK-NEXTJS.md › Tailwind — ×5 `[Tech: shadcn / tailwind]`
- [Fricción ×1] El registro actual (radix-nova, new-york-v4) importa `cn` del paquete npm `cn` y lo añade a `package.json`; `aliases.utils` no lo redirige → propuesta: añadir la trampa y un test guard (`shadcn-config.test.ts`).
- [Hueco ×1] `init` en v4 apunta a un `tailwind.config.ts` huérfano, mete `@layer base` y `.dark` y cambia a Geist → propuesta: ampliar la lista de "qué restaurar" tras `init`.
- [Hueco ×1] `shadcn add dialog` pregunta si sobrescribir `button.tsx` y se queda esperando; lucide-react ≥ 1.0 ya no trae logos de marca (Instagram, YouTube) → propuesta: documentar `echo n | … add <x> -y` y que los logos van en un `brand-icons.tsx` propio.
- [Hueco ×1] Medir un toast sobre un modal Radix con `elementFromPoint` da falso negativo (`body` con `pointer-events: none`); grillas con `role=row/cell` disparan reglas de Biome que `Box` no disparaba → propuesta: anotar ambas trampas en la guía de migración a shadcn.
- [Hueco ×1] STACK-NEXTJS › Tailwind: con `--container-*` reseteado, `max-w-md` cae a `--spacing-md`; `--font-heading` de `next/font` choca con la clave de tema (se resuelve con `@theme inline reference`, que Biome 2.4 no parsea) → propuesta: documentar las tres cosas.

## design-qa (agente y design-qa.ts) — ×2
- [Fricción ×1] El zoom por `document.body.style.zoom` da scroll horizontal falso (no dispara media queries) → propuesta: medir el equivalente real (viewport 640 y 320) en el ejemplo del kit.
- [Error ×1] Escribir el informe con heredoc sin comillas en Git Bash ejecutó las comillas invertidas como comandos (sin daño) → propuesta: reforzar "Write/Edit siempre para el informe".

## wave-qa / scripts/run-on-main.sh — ×2
- [Fricción ×1] `run-on-main.sh` no sirve para repros que necesitan servidor: levantarlo dentro del comando se colgó >10 min; el FAIL se sacó revirtiendo archivos con `git checkout <sha> -- <paths>` → propuesta: opción `--serve <puerto>` que arranque y espere el dev de main, o documentar el truco.
- [Hueco ×1] El repro buscaba rol `button`; el arreglo correcto lo volvió enlace y rompió el script por diseño → propuesta: los repros localizan por texto sin fijar el rol cuando el arreglo puede cambiarlo.

## git-flow (CI) — ×1
- [Fricción ×1] `gh pr checks --watch` pasa de 120 s y obliga a sondear → propuesta: indicar `timeout` ≥ 170 s o `run_in_background`.

## backend-build (seed de QA) — ×1
- [Mejora ×1] El seed local no trae pagos; cada QA del panel los inserta por SQL → propuesta: seed con pagos pendientes y confirmados.

## Lo que funcionó bien y no hay que tocar
- La migración MUI → shadcn/ui en 5 olas con el pool de worktrees cerró completa; reanudar workers tras cortes con SendMessage + git + `.qa/progress.md` evitó relanzarlos.
- `qa:local` con Postgres + Mailpit en Docker y cuentas de `.env.test.local`: el QA nunca tocó la base real ni pidió iniciar sesión a mano.
- functional-qa y design-qa del QA de versión 09 encontraron defectos reales (las 13 filas de Prevención) antes del release.
