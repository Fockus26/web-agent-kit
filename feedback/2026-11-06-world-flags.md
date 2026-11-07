# Informe de feedback — proyecto world-flags — kit 3.17.0 — 2026-11-06

Stack: Astro 7 estático + React 19 · Postgres en VPS (Drizzle + Better Auth) · Bun · Windows

## `reference/QA-PREVENTION.md` (clases de defecto que cazó la QA y no la prevención)
- [Hueco ×1] Reloj monótono mezclado con reloj de pared: una duración de `Date.now()` restada a una marca de `performance.now()` hacía que un salto de hora o el reposo del equipo descontara tiempo del cronómetro; lo cazó `functional-qa` → propuesta: regla "fechar las pausas en el mismo reloj que el cronómetro, con suelo en el inicio"; probar con `page.clock.setSystemTime`.
- [Hueco ×1] Métrica restada de un reloj con varias pausas medida en tiempo de pared (la inactividad se contaba con el modal de salir abierto) → propuesta: regla "medir sobre el tramo en que el reloj corría de verdad"; probar dejando abierto el modal de salir el tiempo del umbral.
- [Hueco ×1] Aviso global sobre "la última partida/operación" que sobrevive a la siguiente y tapa sus controles → propuesta: regla "borrarlo al empezar la siguiente o pintarlo solo en su vista"; probar provocándolo y empezando otra sin cerrarlo.
- [Hueco ×1] Fechas del cliente en el futuro: una ventana "hace menos de X" o un recorte "los N últimos" por fecha, sin tope hacia el futuro, dejó una función bloqueada meses por un reloj adelantado (también al fusionar progreso) → propuesta: regla "ignorar o recortar fechas posteriores a `now + tolerancia` al leer, registrar y fusionar".
- [Hueco ×1] Etiqueta con número ("Práctica diaria (n)") y la acción que la ejecuta calculadas con datos distintos (recalculados frente a guardados) → propuesta: regla "la misma función y los mismos datos para el número y la acción".
- [Hueco ×1] Sincronización entre pestañas por el evento `storage`: escrituras intermedias (un estado provisional y luego el corregido) y datos escritos antes que la clave que dice de quién son hicieron que la otra pestaña fusionara estados a medias o datos de otra cuenta → propuesta: regla "cada `setItem` de la clave es un estado completo; lo que dice de quién son los datos se escribe antes que los datos".
- [Hueco ×1] Efectos que anuncian ("acaba de pasar") disparados por datos adoptados de otra pestaña: el aviso salía en todas → propuesta: regla "distinguir el cambio hecho aquí del adoptado y anunciar solo el primero".

## `UPDATES.md` 3.16.0
- [Fricción ×1] Paso 2: pide sustituir una línea que este `CLAUDE.md` no tenía y "no añadir líneas", con el archivo ya en 8,4 KB; hubo que recortar reglas del proyecto para dejarlo en 8 KB → propuesta: prever el caso "la línea no existe": añadirla y decir qué compensar. (Mismo patrón que se reportó para 3.15.0 paso 5 en el informe anterior.)
- [Fricción ×1] Paso 4: "Replace `scripts/vps-env.ts`, run it" no distingue un proyecto con usuarios reales; ejecutado tal cual con `<project>` deja el dev contra la base real (la tabla de `tech/vps-postgres.md` sí dice `<project>_dev`), y el proyecto ni tenía el script porque migró antes de que existiera → propuesta: "añádelo si falta", remitir a la tabla de entornos y preguntar por `_dev` si hay usuarios reales. `[Tech: vps-postgres]`

## Skill `kit-update` §2b
- [Fricción ×1] El clon del kit estaba en una rama ya mergeada y sin cambios, y la skill trata ese caso igual que "César está editando el kit": se para y pide volver a `main` a mano → propuesta: si la rama está contenida en `origin/main` y el árbol está limpio, hacer el switch a `main` e instalar sin parar.

## `.gitignore` de plantilla / `new-project.ps1` / plantilla de `CLAUDE.md`
- [Hueco ×1] `context/QA_LEDGER.md` (registro de QA propuesto en el informe anterior) aparece sin trackear: la plantilla no lo ignora y `CLAUDE.md` no dice si va en git → propuesta: añadirlo a la lista de `context/` local del `.gitignore` y del `CLAUDE.md`.

## `reference/tech/vps-postgres.md`
- [Hueco ×1] `kit-db create <base>` imprime las URLs con la contraseña y la guía no avisa; si lo lanza un agente, acaban en el transcript → propuesta: indicar `kit-db create <base> >/dev/null` y luego `vps:env`. `[Tech: vps-postgres]`

## Lo que funcionó bien y no hay que tocar
- El registro de QA + "sin QA de la resolución" (informe anterior) cortó los bucles de QA: las rondas de esta tanda solo tocaron lo cambiado.
- `functional-qa` adversarial sigue encontrando clases reales (relojes, pestañas, fechas futuras) que ahora alimentan QA-PREVENTION.
