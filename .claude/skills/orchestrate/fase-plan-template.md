# Fase {{0N}} — {{Nombre}} · plan en olas

> Lo escribe `orchestrate` una vez, al empezar la fase. Cada ola se ejecuta en **su propia
> sesión**: la sesión que arranca una ola lee este archivo y nada más del plan. Se actualiza
> al cerrar cada ola (estado, PRs, QA, lo que pasa a la siguiente).
> Carpeta principal: `{{RUTA_ABSOLUTA}}` · Archivo de la fase: `phases/{{0N-NOMBRE}}.md`

## Olas

| Ola | Unidades (rama · qué · archivos principales) | Depende de | Estado |
|---|---|---|---|
| 1 | {{`feat/hero` · sección hero · `components/sections/Hero.tsx`}} | — | {{pendiente · en curso · QA · cerrada}} |
| 2 | {{…}} | ola 1 | pendiente |

Regla de corte: unidades que tocan los mismos archivos van en olas distintas; lo
transversal, en la última. Una ola cabe en una sesión: si pasa de ~4-5 unidades, se parte.

## Ola en curso: {{N}}

- Brief y prompts: `context/plans/orquestacion-{{fecha}}.md` / `…-prompts.md`
- PRs: {{#12 W1 hero · #13 W2 servicios}} — {{abiertos | mergeados}}
- QA: {{pendiente | informe en context/plans/qa-ola-0N-N.md}}

## Cierres

| Ola | PRs | QA (C · A · M · B) | Pasa a la siguiente | Datos sin borrar |
|---|---|---|---|---|
| 1 | {{#12, #13}} | {{0 · 1 · 2 · 0}} | {{fix QA-1: doble envío del formulario}} | {{ninguno}} |

## Prompt de arranque de la próxima ola

```
/orchestrate ola {{N+1}} de la fase {{0N}}. Plan: context/plans/fase-{{0N}}-{{nombre}}.md
```
