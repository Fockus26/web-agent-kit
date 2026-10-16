## {{W#}} — `{{rama}}`

Eres el worker **{{W#}}**. Rama: `{{rama}}`. Slot y puerto: los del mensaje con el que te
lanzan (`wt take`). Decisiones: rango **{{D0NN–D0NN}}**, un archivo
`context/decisions/D0NN-<tema>.md` por cada una. Filas de CONTENT_CHECKLIST: **{{NN}}**.

Primero lee el brief común: `{{ruta}}/context/plans/orquestacion-{{fecha}}.md`.
Decisiones previas que te condicionan: {{D0NN (qué dice en 5 palabras), D0NN (…)}} —
`cat context/decisions/D0NN-*.md` de cada una, no leas la carpeta entera.

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
- {{Si es un arreglo medible: el mismo guion de medición en `main` (antes) y en tu rama
  (después), con los dos resultados en el PR. Así queda probado que el fallo existía y que
  ya no.}}

### Cierre
Changeset: {{patch | minor | major | ninguno}} — {{texto en lenguaje de usuario}}.
En el PR, "Decisión tomada / alternativa" para: {{…}}. Acciones manuales: {{…}}.
Informe final según el brief.

---
