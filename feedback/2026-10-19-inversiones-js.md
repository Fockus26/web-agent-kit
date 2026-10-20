# Informe de feedback — proyecto inversiones-js — kit 3.9.0 — 2026-10-19

Stack: Next.js 16 · Firebase (Auth + Firestore, emuladores) · bun · Windows

## UPDATES.md 3.7.0 + new-project.ps1 -Existing (comprobación de piezas)
- [Fricción ×1] La comprobación de piezas manda correr `new-project.ps1 -Existing`, que además crea `phases/`, `design/`, `ci.yml` y la plantilla de PR; en un proyecto en marcha solo hacían falta scripts, dependencias y `.gitignore`, y hubo que hacerlo a mano → propuesta: un modo `-OnlyPieces` (o separar la parte de piezas) que no copie fases ni CI.

## reference/scripts/test-related.ts
- [Hueco ×1] El glob `tests/**` incluye `tests/rules` (tests de reglas que necesitan el emulador); al cambiar `package.json` corre todo y falla sin emulador → propuesta: parametrizar `TEST_GLOBS` (variable o `--dir`) o documentar el ajuste para proyectos con tests de integración.

## Lo que funcionó bien y no hay que tocar
- El registro en `KIT_FEEDBACK.md` con marcas de envío evita reenviar lo ya reportado (las 8 filas del informe del 2026-10-16 no se repitieron).
