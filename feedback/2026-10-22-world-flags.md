# Informe de feedback — proyecto world-flags — kit 3.9.0 — 2026-10-22

Stack: Astro 7 (estático + una isla React 19) · Supabase (auth + sync) · Bun · Windows 10

> Nota sobre tipos: este registro usa, además de Hueco/Fricción/Corrección/Repetición, etiquetas
> propias (Coste, Método, Fallo, Mejora, Instrucción, Improvisación, Proceso, Prevención). Se
> mantienen tal cual; en el cuerpo del PR van agrupadas en las cuatro del kit.

## `orchestrate` §8 + `wave-qa` (bucle de QA y alcance)
- [Coste ×4] 4 rondas seguidas de QA de cierre (10-20, 10-21, 10-22 y la siguiente) encontraron casi siempre **la misma clase** de fallo: texto al 200 % a 320 px que se recorta (filas sin `flex-wrap`, `truncate` en nombres, texto fuera de su botón, avisos `fixed` más altos que la pantalla, palabras troceadas). Cada ronda medía un poco más fino y destapaba otra tanda; los workers solo arreglaban las instancias listadas, no la clase → propuesta: cuando un hallazgo es de una **clase**, la unidad de arreglo barre la clase entera con `grep` del patrón y con un **script de medida automático y versionado** (`tests/e2e/reflow-200.spec` o `.qa/` compartido: viewport, `overflow:hidden`, texto fuera de su caja, `fixed` bajo el alto de pantalla, palabra troceada por `Range`). Lo corren los workers antes del PR; la QA ya no barre la clase a mano.
- [Coste ×3] Cada QA de cierre volvía a recorrer flujos ya verificados (registro, login, dos pestañas, axe de todas las pantallas, 404…) aunque sus archivos no habían cambiado → propuesta: **registro de QA** (`context/QA_LEDGER.md`: flujo × condición × commit × archivos clave). La QA solo prueba (a) lo nunca verificado y (b) las filas cuyo `git diff --name-only <commit>..main` ∩ archivos clave no está vacío, y al terminar actualiza el registro. `orchestrate` §8 le pasa esa lista calculada, no "todo lo de la ola + recorrido completo".
- [Coste ×3] Tras cada QA con hallazgos se lanzaba otra QA para comprobar los arreglos, que encontraba más → bucle sin fin → propuesta: sin QA de la resolución. Cada hallazgo trae su **script de reproducción** (lo deja la QA en `.qa/`); el worker lo corre antes/después y adjunta el resultado al PR, y eso cierra el hallazgo. La siguiente QA solo existe si llega funcionalidad nueva.
- [Proceso ×1] "Critical/High → ola siguiente" abría una ola nueva por cada QA → propuesta: los hallazgos de la QA se resuelven en la **misma ola** (mismos slots), cerrados por su worker con el script de reproducción, sin segunda QA (anexo §5).
  Evidencia: el dueño lo fijó como regla en este proyecto el 2026-10-22 (sin re-QA de arreglos; QA solo de lo no verificado o cambiado).

## `orchestrate` (brief, reglas de unidad, modelo)
- [Mejora ×3] "Intercepta Supabase" no dice cómo: dos workers copiaron un `lib.mjs` de mocks de otro slot y dedujeron el build con `PUBLIC_SUPABASE_URL=http://127.0.0.1:9`; otro heredó scripts `.qa/` obsoletos (el tutorial tapaba la app, nombre de botón cambiado) → propuesta: un `scripts/qa/mock-supabase.mjs` compartido + helper para abrir la app con el tutorial ya visto, nombrados en el brief con el comando de build exacto.
- [Coste ×2] "Resolver todo en la misma tanda" + "bugs de paso" de cada worker generaba 2–3 vueltas por PR (SendMessage → nuevo hallazgo de paso → otra vuelta) → propuesta: presupuesto por unidad. El worker arregla lo de su clase/zona en la **primera** vuelta (pedírselo en el prompt: "si ves la misma clase en otro sitio, arréglalo ya"); lo que surja después y sea Bajo va a `backlog.md`. Los Bajos nunca abren ola por sí solos.
- [Instrucción ×1] "Docker solo si la otra unidad terminó": el worker no puede saber si terminó → propuesta: "Docker sí/no" explícito en el prompt, o un lock file (`.qa/docker.lock`) que la unidad crea y borra.
- [Instrucción ×1] "Todos los snackbars de `src/components/app/`" dejó fuera uno con la misma anatomía en otra carpeta → propuesta: que el brief diga "todos los componentes con esta anatomía" o liste las rutas tras un `grep`; cuerpo del PR siempre con `--body-file`.
- [Coste ×1] Todos los workers corrían con el mismo modelo grande; unidades mecánicas gastaron 100–280 k tokens que un modelo menor habría cubierto → propuesta: medidor de modelo/effort por unidad (rúbrica Alcance·Ambigüedad·Riesgo·Verificación, `ESCALAR:` y calibración). Propuesta completa en el anexo.

## `qa-local.ts`
- [Fricción ×3] El primer `supabase start` falla (`StatusDbNotRunningError`, red `supabase_network_*` inexistente) y el segundo funciona → propuesta: reintentar una vez; al terminar, `supabase stop` y comprobar `supabase status` limpio.
- [Improvisación ×2] `qa:local` deja `astro dev` separado (demonio en Astro 7) y sale con 0; no queda claro pararlo con `bun x astro dev stop` (ni `astro preview stop`, que también se separa); el `db reset` tarda ~4 min sin mostrar progreso → propuesta: regla común "parar con `bun x astro dev stop` en el slot" y que el script imprima progreso.
- [Mejora ×1] Para Playwright contra build hubo que hacer build + preview a mano con `PUBLIC_SUPABASE_*` locales → propuesta: modo `qa:local -- --preview`.
- [Fricción ×1] El límite local de 2 correos por hora (`email_sent`) impide repetir pruebas de registro → propuesta: que `qa:local` suba ese límite en la base local (`supabase/config.toml`).

## Brief / guía de QA (entorno Windows y métodos de medida)
- [Fallo ×3] Python escribió CRLF y convirtió escapes `\u`; heredoc + backticks dentro de `node -e "..."` ejecutaron comandos → propuesta: brief "usar Edit/Write o un `.mjs`; nunca Python `open(...,'w')` ni backticks en `node -e`".
- [Método ×2] (skill `a11y`) `el.focus()` por script no activa el foco visible de React Aria (falso "sin anillo"); `synthesizeScrollGesture` táctil no desplaza en headless (falso negativo) → propuesta: tabular de verdad o pulsar una tecla antes; arrastre con `Input.dispatchTouchEvent`.
- [Fallo ×1] `curl` desde Git Bash convierte caracteres fuera del BMP en "??" y da 201 falsos → propuesta: probar la API con un script de bun/node con `fetch`, nunca `curl`.
- [Método ×1] Medir en `requestAnimationFrame` da falsos positivos (estados que nunca se pintan) → propuesta: leer en un `ResizeObserver` creado después del de la app.
- [Método ×1] Las medidas de desborde no detectan palabras troceadas dentro de un botón que no desborda ("Países" en 5 trozos) → propuesta: medir con un `Range` por palabra (más de una línea de rects y la palabra cabría sola); `serve.mjs` estático + diff de firmas antes/después, reutilizables en `.qa/`.
- [Fricción ×1] `hyphens-auto` cambia los cortes a tamaño normal en Chromium con diccionario, contra "sin cambios a tamaño normal" → propuesta: comparar con capturas píxel a píxel antes de usarlo.

## `frontend-build` / `feature-worker` (componentes nuevos)
- [Prevención ×1] La misma clase de fallo (reflow al 200 %) se reintroducía al crear piezas nuevas → propuesta: checklist de construcción. Fila de botones ⇒ `flex-wrap` + botón que parte texto; nombres ⇒ nunca `truncate` sin alternativa; contenedor `fixed` ⇒ `max-height` + scroll interno; títulos ⇒ `wrap-anywhere`. Pasar el script de medida (primer punto de este informe) al cerrar la pieza.

## Lo que funcionó bien y no hay que tocar
- El pool de slots (`wt.ps1`) con workers en segundo plano: varias unidades en paralelo sin pisarse.
- `qa:local` contra Supabase en Docker: QA real sin tocar la base de producción, una vez arrancado.
- Changesets escritos a mano + PR de versión de la Action: "Novedades" sin texto inventado.

---

## Anexo — Medidor de modelo y effort por subagente

Objetivo: que cada subagente (feature-worker, wave-qa, design-qa, functional-qa) corra con el modelo y effort **más baratos que cumplan la tarea**.

### 1. Rúbrica (la puntúa el orquestador al escribir cada prompt)

| Eje | 0 | 1 | 2 |
|---|---|---|---|
| **Alcance** | 1–2 archivos, líneas dadas | 3–6 archivos de una zona | transversal / muchas pantallas |
| **Ambigüedad** | enfoque decidido en el prompt | elegir entre 2 enfoques conocidos | diseñar la solución |
| **Riesgo** | copy, CSS, docs, lista de datos | lógica de UI, tests puros | auth, sesión, concurrencia, datos guardados, seguridad, migraciones con datos |
| **Verificación** | tests unitarios bastan | navegador con mocks | base local + varias pestañas/estados |

| Total | Modelo · effort | Ejemplos de esta tanda (tokens reales) |
|---|---|---|
| 0–2 | `haiku` · low | ampliar una lista de datos (99 k con opus/low, sobraba) |
| 3–4 | `sonnet` · medium | filas `flex-wrap`, avisos al 200 % (219 k y 281 k con opus/medium) |
| 5–6 | `opus` · medium | sondeo de confirmación + enlace caducado (184 k) |
| 7–8 | `opus` · high | marca de cierre entre pestañas, carreras (255 k: encontró una carrera real) |

**Regla de riesgo:** con Riesgo = 2 el mínimo es `opus` aunque el total sea bajo.

QA: `wave-qa` con registro de QA → `sonnet`/medium; si el alcance incluye auth/datos entre pestañas → `opus`/medium. `design-qa` de medidas → `sonnet`/low–medium con el script versionado.

### 2. Escalado y degradado
- El worker empieza en el nivel de la rúbrica. Si falla las puertas dos veces o la tarea pide una decisión de diseño no prevista, termina con `ESCALAR: <motivo>` sin seguir gastando.
- El orquestador relanza esa unidad un nivel arriba en el **mismo slot y rama** (`SendMessage` no cambia el modelo).
- Ajustes mecánicos sobre un PR de un agente opus: mejor un worker nuevo `haiku`/low sobre la rama.

### 3. Calibración
Cada worker cierra su informe con `Calibración: <tipo de unidad> · <modelo>/<effort> · <tokens> · puertas a la 1.ª: sí/no · escalado: sí/no`. Se recoge vía `/kit-feedback`; si un tipo pasa siempre a la primera, baja un nivel; si escala a menudo, sube.

### 4. Implementación en el kit
1. `skills/orchestrate/reference/MODEL-EFFORT.md` con la rúbrica, la tabla y §2 (fuente única).
2. `orchestrate` §4: columna **Modelo · effort (puntuación)** por unidad; §6: pasar `model` y `effort` a `Agent(...)`; §7: manejar `ESCALAR:`.
3. `unit-prompt-template.md` y `brief-template.md`: campo `Modelo/effort: <x> (A·B·R·V = n)`.
4. Agentes: frontmatter por defecto conservador (`model: sonnet`, `effort: medium`) que el orquestador sobrescribe; cuerpo con `ESCALAR:` y la línea de calibración.
5. `kit-feedback`: agrupar las líneas de calibración por tipo de unidad.
6. `UPDATES.md`: entrada de versión para que `/kit-update` lo lleve a los proyectos.

### 5. Hallazgos de la QA dentro de la misma ola
Si la QA de cierre trae hallazgos, las unidades de arreglo forman parte **de esa ola** (mismos slots, sin otra ola ni otra sesión) y la ola cierra al mergearse esos PRs, sin segunda QA. `orchestrate` §8 cambia "Critical/High → unidad al inicio de la ola siguiente" por "→ unidad de arreglo en esta ola, cerrada por su worker con el script de reproducción".
