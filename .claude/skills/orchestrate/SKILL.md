---
name: orchestrate
description: Orquestador de tandas. Úsala cuando César llega con una lista de varias cosas a la vez (features, fixes, pedidos de diseño) y quiere que se resuelvan en paralelo en worktrees. Mapea cada pedido al código, agrupa por archivos que se tocan, ordena en olas, reserva números (decisiones, puertos, filas), hace de una vez las preguntas que bloquean, escribe un brief común y un prompt por unidad, lanza workers feature-worker en segundo plano y consolida sus informes y PRs.
---

# Orquestar una tanda

Tú planificas; los workers ejecutan. Tu trabajo caro (leer código, decidir agrupaciones,
escribir prompts precisos) se hace **una vez**; cada worker arranca en frío y solo lee lo
que su prompt le señala. Por eso tú vas con esfuerzo alto y ellos con medio (ver
`reference/TOKEN-ECONOMY.md` §11-12).

Requisito: el agente `feature-worker` instalado (`~/.claude/agents/` o `.claude/agents/`)
**antes de abrir la sesión**. Los agentes se cargan al arrancar: uno creado a mitad de
sesión da "Agent type not found" hasta que se abre una sesión nueva.

---

## 1. Mapear cada pedido al código

Por cada punto de la lista, localiza dónde vive (grep, rangos, no archivos enteros): qué
archivos toca, qué decisiones previas lo condicionan (`grep` en `DECISIONS_INDEX.md`),
qué trampas conocidas hay. Anota ruta:línea — irá al prompt.

Señales de que un pedido es más grande de lo que parece:
- Toca datos guardados o la base (merge, migraciones, columnas) → necesita tests de la capa
  pura y probablemente acción manual.
- Cambia una regla que afecta datos ya existentes (p. ej. un castigo que vuelve
  incomparables los tiempos guardados) → pregunta qué hacer con lo viejo.
- Es transversal (estilos de foco, hover, tokens) → toca muchos archivos: va al final.
- Es de otro sistema (plantilla de correo en un dashboard, config externa) → no es un PR:
  el worker prepara los archivos y César los aplica.

## 2. Preguntar lo que bloquea — una vez, al principio

Los workers corren en segundo plano y **no pueden preguntar**. Todo lo que cambie qué
hacen se pregunta ahora, en una sola tanda (máx. 4 preguntas, con opción recomendada):

- ¿Pueden levantar su propio servidor de desarrollo (cada uno en su puerto)?
- ¿Pueden aplicar cambios **aditivos** en la base (columnas nuevas) vía MCP, o los deja
  escritos para César?
- Decisiones de producto que el pedido deja abiertas y que cambian el diseño de la unidad.

Lo demás (detalles visuales, copy) lo decide el worker de forma conservadora y lo deja
explicado en el PR con su alternativa.

## 3. Agrupar y ordenar

- **Agrupa** lo que toca los mismos archivos o gira alrededor de la misma pieza (ranking:
  top N + avatares + skeleton + la regla que lo alimenta = una unidad).
- **Separa** lo independiente: cada unidad = una rama = un PR, revisable en poco tiempo.
- **Olas:** unidades que se pisan (mismos archivos) van en olas distintas; lo transversal
  (estilos globales, cabeceras compartidas de modales) va en la última, sobre `main` ya
  actualizado.
- Una unidad sin código de repo (plantilla externa) corre sin worktree ni PR.

## 4. Reservar números

Para que las unidades en paralelo no choquen, asigna a cada una:

| Qué | Ejemplo |
|---|---|
| Rama | `feat/ranking-top20` |
| Archivo de decisiones y rango de IDs | `decisions/18-ranking.md`, D075–D079 |
| Filas de `CONTENT_CHECKLIST` | 26–27 |
| Puerto del servidor | 4331 |

Versiones: cada PR con cambio visible sube versión; varias en paralelo **van a chocar** en
`package.json`/`CHANGELOG.md`. Regla para el worker: parte de la versión de `main`; al
sincronizar, si otra ya tomó su número, sube la suya por encima y deja su entrada arriba.
Tú recomiendas a César un **orden de merge por versión ascendente**.

## 5. Escribir el brief y los prompts — en disco

Dos archivos en `context/plans/` (local):

- `orquestacion-<fecha>.md` — **brief común** (plantilla: `brief-template.md` en esta
  carpeta): tabla de unidades, olas, números reservados y las reglas de la tanda.
- `orquestacion-<fecha>-prompts.md` — **un prompt por unidad** (plantilla:
  `unit-prompt-template.md`): qué pidió César (cita literal), dónde está el código
  (ruta:línea), decisiones que condicionan, trampas conocidas, enfoque ya decidido,
  cómo verificar, cierre.

En disco y no solo en el mensaje: sobreviven a un reinicio de sesión y al worker le basta
con "tu prompt es la sección W3 de ese archivo" — lo escribes una vez, no dos.

Guarda también una memoria del proyecto que apunte a esos dos archivos y diga en qué ola
va la tanda.

## 6. Lanzar

```
Agent(
  subagent_type: "feature-worker",
  isolation: "worktree",          # salvo unidades sin código de repo
  run_in_background: true,
  description: "W3 modales",
  prompt: "Tu prompt completo es la sección '## W3 — …' de <ruta>/orquestacion-<fecha>-prompts.md.
           Léela entera y síguela. Resumen para orientarte: …(3-4 líneas)"
)
```

Todas las unidades de una ola en el **mismo mensaje** (corren en paralelo). No sondees:
te avisan al terminar.

## 7. Consolidar

Cuando llega cada informe:

- Copia su `PHASE_LOG` y los archivos locales que dejó (SQL, plantillas) a la carpeta
  principal si el worker no pudo escribir ahí (un worktree en sandbox no suele poder).
- Actualiza `CURRENT_PHASE.md` (una fila por PR, tablero corto) y `CONTENT_CHECKLIST.md`.
- A César: tabla de PRs (número, versión, qué cambia), **orden de merge recomendado**,
  decisiones abiertas y acciones manuales. Nada más.
- Pedidos que surgen después → `context/plans/pendientes.md`, no la tanda en curso.

Cuando César pide cambios en un PR o `main` avanzó: continúa al worker con `SendMessage`
(conserva su contexto) en vez de lanzar uno nuevo.

Ola siguiente: cuando las unidades de las que depende estén mergeadas.

## 8. Lo que ya se aprendió (no lo redescubras)

- **Archivos locales compartidos:** los workers no editan `CURRENT_PHASE` ni
  `CONTENT_CHECKLIST` (se pisarían); escriben su propio `PHASE_LOG/<rama>.md` o lo
  entregan en el informe.
- **Un worktree nuevo no tiene lo gitignored** (`.env`, `context/` local): el prompt dice
  dónde está la carpeta principal y que el `.env` se copia, nunca se commitea.
- **`.env` de producción:** los workers verifican como invitados; no crean cuentas ni
  escriben datos reales. Para estados que dependen de datos (rankings, listas largas),
  interceptan la respuesta en el navegador solo para depurar.
- **Navegador compartido:** cada worker crea su propia pestaña y pasa su `tabId`.
- **Operaciones destructivas en la base** (DELETE de filas viejas): las escribe el worker,
  no las ejecuta; y el clasificador de seguridad puede bloquearlas también al orquestador
  → quedan como acción de César, con el SQL exacto.
- **Limpiar datos que el cliente vuelve a subir** (un ranking que el cliente resube en cada
  carga) no se arregla borrando filas: hace falta que el cliente nuevo invalide lo viejo y
  que clientes viejos cacheados escriban donde nadie lee (claves versionadas internas).
- **Playwright se corre con node**, no con bun (en Windows se cuelga).
