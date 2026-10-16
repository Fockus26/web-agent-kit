# Kit feedback — {{NOMBRE_DEL_PROYECTO}}

> Lo que el **web-agent-kit** hizo mal, de más o de menos en este proyecto, para mejorarlo.
> No es el diario del proyecto: es material para el kit. Se busca con `grep`, no se lee por
> defecto. Kit en el que arrancó / al que se actualizó: ver `.kit-version`.

## Cuándo se anota (lo hace el agente, sin que se lo pidan)

| Tipo | Señal |
|---|---|
| **Corrección** | César corrige algo que el agente hizo siguiendo el kit ("no, así no", "otra vez el…", revierte un cambio) |
| **Repetición** | César tuvo que pedir lo mismo por segunda vez, o hacer a mano un paso que el kit podría hacer |
| **Hueco** | El kit no decía qué hacer y el agente tuvo que improvisar o preguntar algo que debería estar resuelto |
| **Fricción** | Un paso del kit costó mucho para lo que aportó (tokens, tiempo, ceremonia), o una instrucción estaba mal |

No se anota: errores del agente que el kit ya prohíbe con claridad (eso es otra cosa), ni
preferencias de este proyecto solo (van a `decisions/`).

**Si ya existe una fila del mismo problema, no se duplica: se suma 1 a "Veces", se
actualiza la fecha y, si estaba marcada como enviada (`→ PR …`), se quita la marca** (así
el próximo envío la lleva con la cuenta nueva). Lo que se repite es lo que más vale arreglar.

## Registro

| # | Fecha | Tipo | Veces | Pieza del kit | Qué pasó (1 línea) | Propuesta (1 línea) |
|---|---|---|---|---|---|---|
| 1 | {{AAAA-MM-DD}} | {{Corrección}} | 1 | {{skill git-flow §2.1.1}} | {{ej. las capturas no incluían el estado hover que César pidió}} | {{ej. que .pr-shots.json pida estados interactivos por defecto}} |

## Enviarlo al kit

Cuando César lo pida (o al cerrar la fase 09): skill **`kit-feedback`** (`/kit-feedback`).
Arma el informe con las filas sin enviar, agrupado por pieza del kit y con lo repetido
primero, y abre un PR en el repo del kit con la etiqueta `kit-feedback`. Las filas enviadas
quedan marcadas con `→ PR <owner/repo#N>` en "Propuesta" (no se borran).
