## {{W#}} — `{{rama}}`

Eres el worker **{{W#}}**. Rama: `{{rama}}`. Puerto: **{{43NN}}**. Decisiones:
`context/decisions/{{NN}}-{{tema}}.md`, rango **{{D0NN–D0NN}}**. Filas de CONTENT_CHECKLIST:
**{{NN}}**.

Primero lee el brief común: `{{ruta}}/context/plans/orquestacion-{{fecha}}.md`.
Decisiones previas que te condicionan: {{D0NN (qué dice en 5 palabras), D0NN (…)}} —
búscalas con `grep` en `DECISIONS_INDEX.md`, no leas el índice entero.

### Qué pide César
> "{{cita literal del pedido}}"

{{Interpretación, si la cita es ambigua: "Entiendo X porque Y".}}

### Dónde está
- `{{src/.../Archivo.tsx:NN}}` — {{qué hay ahí hoy}}
- `{{src/.../otro.ts:NN-NN}}` — {{…}}

### Enfoque decidido
{{Lo que ya decidió el orquestador o César, para que el worker no lo re-decida. Si hay
opciones que quedan a su criterio, dilo explícitamente.}}

### Trampas conocidas
- {{ej. "el merge se queda con el menor: si no marcas la versión, lo viejo resucita"}}
- {{ej. "hay un test que vigila los imports de X: corre ese test"}}
- {{ej. "otra unidad cambia las constantes de arriba de Y.tsx: no las toques"}}

### Cómo verificar
- {{qué medir, en qué anchos/temas, qué estados, con qué datos}}
- {{tests nuevos que se esperan}}

### Cierre
Versión {{PATCH | MINOR | MAJOR (por qué)}}. Entrada del CHANGELOG en lenguaje de usuario.
En el PR, "Decisión tomada / alternativa" para: {{…}}. Acciones manuales: {{…}}.
Informe final según el brief.

---
