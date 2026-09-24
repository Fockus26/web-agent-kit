# Economía de tokens

Reglas de obligado cumplimiento para todos los agentes y skills del kit. El objetivo es que
cada tarea cueste lo que tiene que costar: **el contexto justo para hacerla bien, ni un
archivo más.**

> Lo que más tokens gastó en el primer proyecto real (World Flags) no fue el código: fue
> **leer contexto que no hacía falta** en cada arranque. `CURRENT_PHASE.md` llegó a 38 KB
> (debía caber en una pantalla) y `DECISIONS_INDEX.md` a 31 KB, y la regla "lee estos 5
> archivos antes de empezar" hacía que cada sesión pagara ~20.000 tokens antes de tocar
> una línea. Las reglas 1–3 existen por eso.

---

## 1. Lectura por niveles — no "lee todo antes de empezar"

| Nivel | Qué | Cuándo |
|---|---|---|
| **Siempre** | `CLAUDE.md` (se carga solo) + `context/CURRENT_PHASE.md` | Toda sesión |
| **Según la tarea** | Lo que diga la tabla "Qué leer según la tarea" de `CLAUDE.md` | Solo si la tarea es de ese tipo |
| **Buscar, no leer** | `DECISIONS_INDEX.md`, `CONTENT_CHECKLIST.md`, inventarios, `PHASE_LOG/`, `decisions/` | `grep` por la palabra o el ID; se abre solo el archivo/rango que sale |

Ejemplos:

```bash
grep -n "ranking\|leaderboard" context/DECISIONS_INDEX.md     # ¿hay algo decidido sobre esto?
grep -rn "D042" context/decisions/                              # el detalle de una decisión citada
grep -n "Modal" context/COMPONENTS_INVENTORY.md                 # ¿existe ya un componente?
```

Si una unidad la prepara un orquestador, el prompt ya trae las rutas, líneas e IDs de
decisión relevantes: **se lee eso y nada más** (ver skill `orchestrate`).

## 2. Presupuesto de tamaño de `context/`

Un archivo que se lee siempre tiene que ser corto; los que se consultan con `grep` pueden
crecer, pero cada fila tiene que ser una línea.

| Archivo | Tope | Qué se hace al pasarlo |
|---|---|---|
| `CLAUDE.md` | ~8 KB | Lo que no es regla ni mapa se va a `context/` o a `docs/` |
| `CURRENT_PHASE.md` | **~60 líneas / 4 KB** | Lo cerrado se mueve a `PHASE_LOG/<rama>.md`; aquí queda una línea con el enlace |
| `DECISIONS_INDEX.md` | Sin tope, **1 fila = 1 línea ≤ 160 caracteres** | El detalle va al archivo de `decisions/`, nunca a la fila |
| `CONTENT_CHECKLIST.md` | Sin tope, filas cortas | Las resueltas se marcan `Hecho`; no se reescriben párrafos |
| Cualquier otro de lectura "siempre" | 4 KB | Partirlo |

Comprobación rápida (la corre `git-flow` al cerrar cada unidad):

```bash
wc -c CLAUDE.md context/CURRENT_PHASE.md    # >8000 / >4000 → podar antes del PR
awk 'length > 200' context/DECISIONS_INDEX.md | head   # filas que son párrafos
```

## 3. `CURRENT_PHASE.md` es un tablero, no un diario

Solo tres cosas: **qué está abierto ahora** (PRs/ramas con su estado en una línea),
**qué bloquea** (acciones del dueño), y **qué sigue**. La narrativa de lo que se hizo, lo
que se verificó y lo que no, va a `PHASE_LOG/<rama>.md` al cerrar la unidad. Si al cerrar
una unidad ves que el archivo creció, podarlo es parte del cierre, no una tarea aparte.

## 4. El servidor de desarrollo

**Por defecto lo levanta César.** Cuando un paso necesita el sitio corriendo, se pide y se
espera; si dice que no, se sigue sin esa verificación y se marca como no verificado.

**Excepción autorizada por tanda** (la usa `orchestrate` con workers en paralelo): si César
lo autoriza, cada agente levanta el suyo **en segundo plano**, en su worktree y **en su
propio puerto**, no lee sus logs salvo que algo falle, y lo apaga al terminar. La
autorización vale para esa tanda, no para siempre.

Por qué la regla existe: un servidor en primer plano escupe logs de compilación a cada
cambio y cada línea pasa por el contexto; uno huérfano sigue ocupando el puerto.

## 5. Tests: los afectados en el bucle, todos en CI

- **Mientras se trabaja:** solo los tests afectados por el cambio, con salida mínima:
  ```bash
  bun run test:related        # scripts/test-related.ts: elige por el grafo de imports, usa --dots
  ```
  Elige por dependencias reales, no por el nombre: un cambio en logros no corre el test del
  tutorial… salvo que el tutorial importe algo de logros, que es justo cuando sí debe correr.
  Si cambian dependencias, `tsconfig` o la config del bundler, corre todo.
- **Antes de abrir el PR:** la suite unitaria completa, con `--dots` (un punto por test que
  pasa; detalle solo de los que fallan). En verde son un par de líneas.
- **CI corre siempre todo.** La selección por grafo es una heurística (no ve lo que un test
  lee con `fs` salvo por nombre, ni efectos globales): acelera el bucle, no sustituye a la
  suite. Para e2e, lo mismo con `playwright test --only-changed=origin/main` primero y la
  suite completa después.

## 6. Capturas: al disco, no al contexto

- Una captura **vista** por el agente cuesta muchísimo más que medir el DOM. Para verificar
  estructura, contraste, desbordes o foco: mediciones del DOM (texto).
- Las capturas para el PR se **generan a disco y se publican sin abrirlas**
  (`bun run shots` + `bun run shots:publish`, scripts en `scripts/`). Son para quien revisa.
- El agente solo abre una imagen cuando el hallazgo es visual y no se puede medir.

## 7. No releas lo que ya leíste

El contenido de un archivo que ya está en la conversación no se vuelve a leer. Después de
editar, **no releas para verificar**: si la edición hubiera fallado, la herramienta habría
dado error.

## 8. Lee lo justo

- Un archivo grande: el rango que necesitas, no las 2.000 líneas.
- Buscar algo: `grep` con el patrón, no leer archivos completos a ver si está.
- Explorar: lista nombres primero, abre solo lo que resulte relevante.

## 9. Una unidad, una vez

Lo que más tokens gasta no es un archivo largo: es implementar una sección entera con un
dato inventado y tener que rehacerla. De ahí "si falta un dato del handoff, se pregunta" y
"3 opciones antes de implementar lo ambiguo". Un worker en segundo plano que no puede
preguntar elige lo conservador y lo deja explicado en el PR.

## 10. Salidas concisas

- No repitas en prosa el código que acabas de escribir.
- No narres lo que vas a hacer antes de hacerlo.
- El formato de entrega de cada skill ya es el resumen: no agregues otro encima.
- Comandos con salida larga: filtra (`| tail -20`, `--dots`, `--quiet`) en vez de leerla entera.

## 11. Aislar lo ruidoso en subagentes

Barridos de QA, exploraciones amplias y unidades completas delegadas corren como
subagentes: su ruido (capturas, salidas de axe, trazas, logs) se queda en su contexto y a
la sesión principal vuelve solo el informe. El precio: un subagente arranca en frío, así
que **el prompt tiene que traer el contexto mínimo suficiente** (rutas, líneas, decisiones,
trampas conocidas) para que no lo redescubra leyendo el repo entero.

## 12. Esfuerzo según el papel

El orquestador (planifica, agrupa, redacta prompts, consolida) justifica un esfuerzo alto.
Los workers que ejecutan un prompt bien especificado rinden igual con esfuerzo medio. Se
fija en la definición del agente (`effort:` en el frontmatter de `.claude/agents/*.md`).

## 13. Sesiones separadas por bloque

Una sesión larguísima acumula todo el historial en cada turno. Es más barato cerrar y abrir
una sesión nueva entre bloques grandes: el estado vive en `context/` y en la memoria del
proyecto, no en la conversación.
