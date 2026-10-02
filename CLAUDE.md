# web-agent-kit — mantenimiento del kit

Este repo **es el kit**, no un proyecto. Aquí no se construye ningún sitio: se mejoran las
skills, agentes, plantillas, scripts y prompts que usan los proyectos. (La plantilla que va a
cada proyecto es `CLAUDE.md.template`; este archivo no se copia a ningún lado.)

Mapa: `README.md` (qué es cada pieza) · `GUIA.md` (cómo se usa) · `ACTUALIZACIONES.md`
(versiones y migraciones) · `VERSION` (versión actual).

## Cuando César pega un "Informe de feedback" de un proyecto

Viene de `context/KIT_FEEDBACK.md` de un proyecto (formato en
`context-templates/KIT_FEEDBACK.md`).

1. **Triaje**, en una tabla, sin cambiar nada: por cada punto — pieza del kit afectada
   (archivo y sección), si ya está resuelto en la versión actual (búscalo: el proyecto puede
   ir atrasado), y la propuesta concreta de cambio. Ordena por "Veces": lo repetido primero.
   Marca lo que es **propio de ese proyecto** y no debe generalizarse.
2. César elige qué entra. Si un punto admite varias soluciones razonables: 3 opciones con
   ventaja y desventaja real.
3. Implementa lo elegido en una rama (`feat/…` o `fix/…`), cambiando el mínimo de piezas y
   manteniendo su estilo: español, tono directo, reglas con su porqué, sin relleno.
4. **Versión** (ver el final de `ACTUALIZACIONES.md`): sube `VERSION` y añade la entrada
   arriba con qué cambió y **los pasos para un proyecto en la versión anterior**. Si el
   cambio solo afecta a skills/agentes (se instalan globales), los pasos pueden ser
   "ninguno en el proyecto; reinstalar skills".
5. Actualiza `README.md`/`GUIA.md` si cambia algo que César hace o ve.
6. Commit (Conventional Commits, en español), push y PR. César mergea.

## Reglas al editar el kit

- Lo que el agente de un proyecto lee **siempre** (`CLAUDE.md.template` ≤ 8 KB,
  `CURRENT_PHASE` ≤ 60 líneas) se mantiene corto: lo largo va a `reference/` y se cita.
- Cada cambio que un proyecto existente necesite aplicar **tiene** su entrada en
  `ACTUALIZACIONES.md`; si no, los proyectos viejos se quedan atrás sin saberlo.
- Toda regla nueva dice por qué existe (el incidente o la medición que la motivó).
- Consulta Context7 antes de escribir código o APIs de librerías en las guías.
- `nuevo-proyecto.ps1`: probarlo en una carpeta temporal (`-Existente` sobre un
  `package.json` mínimo) antes de dar el cambio por bueno.
