# Informe de feedback — proyecto inversiones-js — kit 3.12.0 — 2026-10-22

Stack: Next.js 16 · Firebase Auth + Firestore (SDK cliente, emuladores) · bun · Windows 10

## QA: cierre de unidades y agentes de QA
- [Hueco ×1] Seis PRs de funcionalidad hechos en sesiones en la nube (inversiones-js #7–#10) se mergearon sin functional-qa ni design-qa. Ningún paso las lanzó, y la deuda salió de golpe semanas después: 3 hallazgos altos de pérdida de datos (diálogos que pisaban cambios concurrentes, años de 2 dígitos guardados como 1926). → propuesta: que el cierre en la nube (cloud-session) y git-flow exijan functional-qa/design-qa cuando la unidad cierra un flujo o una página, o que lo dejen anotado como pendiente en CURRENT_PHASE.
  Evidencia: Fockus26/inversiones-js#19
- [Hueco ×1] La descripción de wave-qa ("Supabase en Docker") hizo creer que hacía falta Docker para probar con base real en un proyecto Firebase. → propuesta: describir la QA local por stack (Supabase → Docker; Firebase → emuladores + Java) en wave-qa y en la plantilla de CLAUDE.md.
- [Hueco ×1] design-qa exige una galería `/estados?screen=…` que ninguna skill pide crear, así que la pantalla 500 quedó sin auditar. → propuesta: que frontend-build cree la galería (solo en dev, 404 en producción) al implementar las pantallas de estado.
  Evidencia: Fockus26/inversiones-js#19

## reference/qa-scripts/qa-local (Firebase) + plantilla de tests de reglas
- [Fricción ×1] En frío (la primera vez en la máquina) los emuladores tardan más de 90 s y `qa-local` aborta. Además, `initializeTestEnvironment` en `beforeAll` pasa de los 5 s por defecto de bun, así que `emulators:test` falla en la primera corrida. → propuesta: esperar 240 s en `qa-local` y poner `beforeAll(..., 30_000)` en la plantilla de tests de reglas.
  Evidencia: Fockus26/inversiones-js#19

## Comprobación de piezas / CI (subproyectos)
- [Hueco ×1] Un subproyecto con su propio package.json (`bot/`) nunca tuvo `bun install`: su typecheck fallaba en main y nadie lo vio, porque CI no lo corre. → propuesta: que la comprobación de piezas detecte package.json anidados y que CI corra su typecheck y sus tests.
  Evidencia: Fockus26/inversiones-js#20

## new-project.ps1 -OnlyPieces
- [Fricción ×1] Añadió `* text=auto` a un `.gitattributes` que ya tenía `* text=auto eol=lf`, lo que anula el LF. Además, su paso final `bunx biome` falló porque `bunx` no está en el PATH de pwsh, y `.claude/settings.json` quedó sin formatear (lint en rojo). → propuesta: añadir `*.sh text eol=lf` solo si no hay ya una regla `eol=lf` global, y formatear con `bun x biome`.

## Lo que funcionó bien y no hay que tocar
- functional-qa y design-qa contra los emuladores (`qa:local`) encontraron fallos reales y reproducibles, y su re-verificación por SendMessage tras los arreglos fue muy eficaz.
- `qa-local` con cuentas de `.env.test.local` y proyecto `demo-*`: cero riesgo para producción.
