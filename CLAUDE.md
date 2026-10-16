# web-agent-kit — mantenimiento del kit

Este repo **es el kit**, no un proyecto. Aquí no se construye ningún sitio: se mejoran las
skills, agentes, plantillas, scripts y prompts que usan los proyectos. (La plantilla que va a
cada proyecto es `CLAUDE.md.template`; este archivo no se copia a ningún lado.)

Mapa: `README.md` (qué es cada pieza) · `GUIA.md` (cómo se usa) · `ACTUALIZACIONES.md`
(versiones y migraciones) · `VERSION` (versión actual) · `feedback/` (informes de los
proyectos ya procesados).

## Cuando llega feedback de los proyectos

Llega de dos formas, las dos desde `context/KIT_FEEDBACK.md` de un proyecto:

- **PRs con la etiqueta `kit-feedback`** (lo normal desde la 3.6.0): la skill `kit-feedback`
  de cada proyecto sube su informe como `feedback/<fecha>-<proyecto>.md`. Cuando César pide
  "revisa el feedback": `gh pr list --label kit-feedback --state open`, y el archivo de cada
  uno con `gh pr diff <n>`.
- Un "Informe de feedback" pegado en el chat (proyectos que aún no tienen la skill).

1. **Triaje**, en una tabla, sin cambiar nada: por cada punto — pieza del kit afectada
   (archivo y sección), si ya está resuelto en la versión actual (búscalo: el proyecto puede
   ir atrasado; su versión va en la cabecera del informe), y la propuesta concreta de cambio.
   **Consolidado entre informes:** el mismo problema en varios proyectos es una fila, con
   "Veces" sumadas y la columna "Proyectos". Ordena por "Veces": lo repetido primero.
   Marca lo que es **propio de un proyecto** o de un stack que el kit no cubre, y no debe
   generalizarse.
2. César elige qué entra. Si un punto admite varias soluciones razonables: 3 opciones con
   ventaja y desventaja real.
3. Implementa lo elegido en una rama (`feat/…` o `fix/…`), cambiando el mínimo de piezas y
   manteniendo su estilo: español, tono directo, reglas con su porqué, sin relleno.
4. **Versión** (ver el final de `ACTUALIZACIONES.md`): sube `VERSION` y añade la entrada
   arriba con qué cambió y **los pasos para un proyecto en la versión anterior**. Si el
   cambio solo afecta a skills/agentes (se instalan globales), los pasos pueden ser
   "ninguno en el proyecto; reinstalar skills".
5. Actualiza `README.md`/`GUIA.md` si cambia algo que César hace o ve.
6. Commit (Conventional Commits, en español), push y PR. César mergea. En el cuerpo, los PRs
   de feedback que atiende (`Atiende: #12, #14`).
7. **Cerrar el círculo:** en cada PR de feedback, un comentario con qué entró (y en qué PR)
   y qué no y por qué (`gh pr comment`). César los mergea: quedan en `feedback/` como
   histórico, y un punto que vuelva a llegar se compara con lo que ya se decidió ahí.

## Reglas al editar el kit

- Lo que el agente de un proyecto lee **siempre** (`CLAUDE.md.template` ≤ 8 KB,
  `CURRENT_PHASE` ≤ 60 líneas) se mantiene corto: lo largo va a `reference/` y se cita.
- Cada cambio que un proyecto existente necesite aplicar **tiene** su entrada en
  `ACTUALIZACIONES.md`; si no, los proyectos viejos se quedan atrás sin saberlo.
- Toda regla nueva dice por qué existe (el incidente o la medición que la motivó).
- Consulta Context7 antes de escribir código o APIs de librerías en las guías.
- `nuevo-proyecto.ps1`: probarlo en una carpeta temporal (`-Existente` sobre un
  `package.json` mínimo) antes de dar el cambio por bueno.
