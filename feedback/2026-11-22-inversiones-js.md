# Informe de feedback — proyecto inversiones-js — kit 3.26.0 — 2026-11-22

Stack: Next.js 16 (App Router) · Postgres en VPS + Drizzle + Better Auth (migrado desde Firebase) · bun · Windows 10

Todas las filas tienen ×1; el orden es por cuántos puntos tiene cada pieza.

## reference/QA-PREVENTION.md
- [Prevención ×1] Bloqueo por cuenta saltado con intentos en paralelo (leer en `before`, sumar en `after`) → propuesta: reservar el intento atómico antes de comprobar la contraseña (`insert … on conflict do update … returning`) y limpiar solo en un acierto; test con 30 intentos en `Promise.all`.
- [Prevención ×1] Restablecer la contraseña no quitaba el bloqueo que promete el mensaje del 429 → propuesta: `emailAndPassword.onPasswordReset` limpia el contador de esa cuenta.
- [Prevención ×1] Errores de auth traducidos por status: el 403 de origen y el 400 de contraseña larga salían como "clave incorrecta" / "enlace vencido" → propuesta: traducir por el `code` del proveedor; solo el error de credenciales cuenta como fallo.
- [Prevención ×1] Un CHECK con columnas nulables pasa cuando la expresión da NULL → propuesta: `is null` / `is not null` explícitos y un test con NULL en una sola columna.
- [Prevención ×1] Un toggle que manda la lista completa de la última lectura: el segundo deshace el primero (típico al pasar de tiempo real a sondeo) → propuesta: operación por elemento en el servidor (`jsonb_set` por número) y fusionar lo guardado al editar el registro completo.
- [Prevención ×1] Hook de sondeo con error pegajoso: tras una primera carga fallida se descartan los datos buenos → propuesta: la siguiente lectura buena limpia el error y publica.
- [Prevención ×1] Fusionar una lista de estados (pagado / no pagado) entre formulario y base con un "o": una cuota desmarcada en otra pestaña vuelve a quedar pagada al guardar la edición → propuesta: para lo que el formulario no tocó, gana el estado de la base; si el plan no cambió, no se manda la lista. Test: desmarcar en A con el editor abierto en B y guardar B.
- [Prevención ×1] Un campo que escribe un proceso de fondo (un recordatorio que marca el chatbot) lo pisa el formulario de edición con el valor que leyó al abrir → propuesta: los campos de otro proceso no viajan en el formulario, los conserva el servidor. Test: marcarlo por SQL con el editor abierto y guardar.
- [Prevención ×1] "Cerrar sesión" que se traga el error: sin red o con 5xx se queda en "Saliendo…" para siempre y la sesión sigue → propuesta: propagar el fallo, avisar y reactivar el botón. Test con `route.abort()` sobre sign-out.
- [Repetición ×1] Volvieron a salir cuatro reglas que el kit ya tiene: diálogo que pisa un cambio hecho mientras tanto (3.ª vez, ahora contra el chatbot), sesión vencida que pierde lo escrito, fallo del servicio que dice "revisa tu conexión" (en pantallas de carga fallida) y spinner infinito → propuesta: la regla del diálogo debería nombrar también "un proceso de fondo" como el otro que escribe.
- [Prevención ×1] Un contenedor con scroll horizontal propio (subnav, fila de chips con `-mx-4`) dentro de un grid ensancha la página con la letra del navegador al 200 % → propuesta: `min-w-0` en el hijo directo del grid o flex que contiene un `overflow-x-auto`.
- [Prevención ×1] Botones con `whitespace-nowrap` en columnas fijas desbordan su caja con la letra al 200 % → propuesta: botones de acción de página en `flex flex-wrap` con hijos `flex-auto` (no `grid-cols-2`: una palabra larga no cabe) y `whitespace-normal min-h-11 h-auto`.
- [Prevención ×1] Las animaciones `zoom-in` de shadcn en dialog y select no respetan `prefers-reduced-motion` → propuesta (también en UI-LIBRARIES.md): al instalar shadcn, `motion-reduce:animate-none!` (con `!`: sin él gana `data-open:animate-in`; comprobado).
  Evidencia: Fockus26/inversiones-js#31

## reference/scripts/qa-local.ts
- [Hueco ×1] (Firebase, 3.13.0 paso 2) El script pasa el proyecto demo solo en `GCLOUD_PROJECT`; un seed que lo lee de `NEXT_PUBLIC_FIREBASE_PROJECT_ID` recibe el real de `.env.local` (Bun lo carga) y aborta → propuesta: pasar también `<prefix>FIREBASE_PROJECT_ID` en `emulatorEnv` del seed, o decirlo en el paso "rename or wrapper". `[Tech: firebase]`
- [Error ×1] (3.21.0) `env.NODE_ENV = "production"` en `--preview` rompe `tsc` en un proyecto Next (los tipos de Next hacen NODE_ENV de solo lectura) → propuesta: `Object.assign(env, { NODE_ENV: "production" })` en el script del kit. `[Tech: next]`
- [Fricción ×1] (Postgres) En un PC con HDD el `initdb` de `postgres:17` tardó más de 9 min: el script espera 2 min y aborta, y el entrypoint de la imagen se rindió una vez (`server did not start in time`) dejando el contenedor detenido → propuesta: esperar más (o hasta que el contenedor salga) y, si quedó `Exited` tras un init fallido, recrearlo en vez de `docker start`.
- [Fricción ×1] En Git Bash, `--warm /login,/productos` llega como `C:/Program Files/Git/login,...` (conversión de rutas de MSYS) y el calentado falla sin avisar; además `next dev` se colgó compilando `/login` (>20 min) y `--preview` sí funcionó → propuesta: documentar `MSYS_NO_PATHCONV=1` o normalizar el argumento en el script; sugerir `--preview` cuando el primer compilado pasa de N minutos.
- [Error ×1] (con EMAIL-TEMPLATES.md § Better Auth) El ejemplo de `lib/email/send.ts` usa `SMTP_PASS` y `EMAIL_FROM`, pero qa-local pasa `SMTP_PASS` y `SMTP_FROM` ("Nombre <dir>"); hubo que aceptar ambos nombres y ambos formatos → propuesta: un solo juego de nombres (`SMTP_PASS` + `EMAIL_FROM`) y que qa-local pase esos.

## tech/vps-postgres.md (+ tech/migrate-firebase-vps.md)
- [Hueco ×1] (§4 + migrate §3) `bunx auth@latest generate` terminó sin error y sin archivo: la config importa `next/server` (`after` del correo) y la CLI no la carga; hubo que escribir a mano las tablas de Better Auth → propuesta: recomendar una fábrica `crearAuth(db)` en un archivo sin imports de Next (sirve también para probar con PGlite) y que la CLI apunte a ella; o dar el esquema base de Better Auth en Drizzle en el kit. `[Tech: vps-postgres]`
- [Error ×1] (§ Better Auth hooks) En un hook `after`, `returned instanceof APIError` no reconoce el 400 de validación (clase de better-call): un pedido sin contraseña pasaba por acierto y borraba el contador de fallos → propuesta: usar `isAPIError()` de `better-auth/api` y tratar como acierto solo una respuesta con `token`. `[Tech: vps-postgres]`
- [Hueco ×1] (› Actions for César) Pone `BETTER_AUTH_URL` como acción de César sin decir qué valor lleva: el agente y la QA le preguntaron "el dominio" y César entendió que lo resolvía el VPS → propuesta: decir que el panel sigue en Vercel (el VPS solo tiene la base), que `BETTER_AUTH_URL` = dominio de producción en Vercel y que el agente lo saca de Vercel (`list_project_domains`) y lo sube en el corte. `[Tech: vps-postgres]`

## install-kit.ps1 -Project · new-project.ps1 -OnlyPieces · kit-update
- [Fricción ×1] Escriben en CRLF: tsconfig.json quedó en CRLF y sin el formato de Biome (lint rojo) y la copia del kit dejó 64 archivos `w/crlf`; el paso 3.21.0 de reescribir con `git reset --hard` lo bloquea el modo auto (y el CLAUDE.md lo prohíbe) → propuesta: escribir con LF y formatear tsconfig.json con Biome; en UPDATES, convertir solo los `w/crlf` con `sed -i 's/\r$//'` en vez de `reset --hard`.
- [Fricción ×1] (kit-update §8) Volvió a pasar en 3.26.0: 67 archivos de `.claude/` en CRLF en la copia de trabajo (git los guarda en LF, pero la revisión de piezas pide 0 `w/crlf`). Además `-OnlyPieces` ya refresca la copia del kit, así que el paso de §8 repite lo mismo → propuesta: que los dos escriban en LF (o normalicen al terminar) y que §8 diga que si `-OnlyPieces` corrió en el camino la copia ya está.
- [Hueco ×1] (kit-update › Piece check) La revisión mira el job de subproyectos en `ci.yml` pero no si `ci.yml` existe; este proyecto no tenía CI y nada lo marcaba → propuesta: fila "`.github/workflows/ci.yml` existe" en la revisión de piezas, con la plantilla del kit si falta.

## Plantillas de proyecto (CLAUDE.md, biome.json, globals)
- [Hueco ×1] (CLAUDE.md › Tech refs / "Qué leer") Al pedir "migrar la db al VPS" el agente preguntó qué motor usar: el CLAUDE.md no apunta a `tech/migrate-firebase-vps.md`, que ya fija Postgres + Drizzle + Better Auth → propuesta: fila "migrar al VPS → `tech/migrate-<origen>-vps.md`" en la tabla de la plantilla.
- [Hueco ×1] (biome.json · git-flow §2.1) La plantilla excluye `!**/.claude/worktrees`, así que dentro de un worktree de `.claude/worktrees/` `bun run lint` sale con "No files were processed" (exit 1) y no revisa nada; un `@import` mal puesto en `globals.css` solo salió pasando Biome con una copia del config sin la exclusión → propuesta: anclar la exclusión a la raíz (`!.claude/worktrees` relativo al config) o que git-flow diga cómo correr el lint desde un worktree.
- [Prevención ×1] (globals / DESIGN_RULES `::selection`) La regla global `::selection` fuera de `@layer base` gana a todas las utilidades `selection:` (lo que no está en capa gana a las capas): la regla del par invertido no se podía cumplir → propuesta: la plantilla pone `::selection` dentro de `@layer base`.
  Evidencia: Fockus26/inversiones-js#31

## Agentes design-qa y functional-qa
- [Fricción ×1] En paralelo, los dos escriben en `.qa/repro/` con la misma numeración: un glob de design-qa ejecutó los repros de auth de functional-qa (vació la tabla de intentos de login y cambió una contraseña de prueba) → propuesta: subcarpeta o prefijo por agente (`.qa/repro/design/`, `.qa/repro/functional/`) y nunca lanzar repros con glob.

## Lo que funcionó bien y no hay que tocar
- `tech/migrate-firebase-vps.md` + `vps-postgres.md`: la migración de Firebase a Postgres en el VPS salió en una tanda, con Firebase en solo lectura como vuelta atrás.
- `qa-local --postgres` con Mailpit: la QA de auth (bloqueo, restablecer contraseña, correos) se pudo hacer entera en local sin tocar el VPS.
- La QA de versión (functional-qa + design-qa) encontró defectos reales de pérdida de datos y de zoom al 200 % antes de producción.
