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

**Si ya existe una fila del mismo problema, no se duplica: se suma 1 a "Veces" y se
actualiza la fecha.** Lo que se repite es lo que más vale arreglar.

## Registro

| # | Fecha | Tipo | Veces | Pieza del kit | Qué pasó (1 línea) | Propuesta (1 línea) |
|---|---|---|---|---|---|---|
| 1 | {{AAAA-MM-DD}} | {{Corrección}} | 1 | {{skill git-flow §2.1.1}} | {{ej. las capturas no incluían el estado hover que César pidió}} | {{ej. que .pr-shots.json pida estados interactivos por defecto}} |

## Informe para el kit

Cuando César pida "el informe para el kit" (o al cerrar la fase 09), el agente:

1. Agrupa las filas por pieza del kit y ordena por **Veces** (lo repetido primero).
2. Devuelve un bloque de código listo para pegar en una sesión abierta en la carpeta del kit:

```text
Informe de feedback — proyecto <nombre> — kit <versión de .kit-version> — <fecha>

## <pieza del kit> (skill / plantilla / script / prompt)
- [<Tipo> ×<Veces>] <qué pasó> → propuesta: <qué cambiar en el kit>
  Evidencia: <rama/PR/archivo donde se vio, si sirve>

## Lo que funcionó bien y no hay que tocar
- <1-3 líneas>
```

3. Marca las filas incluidas con `→ informe <fecha>` en "Propuesta" (no las borra).
