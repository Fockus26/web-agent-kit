---
name: kit-update
description: Pone al día un proyecto con la última versión del web-agent-kit. Úsala cuando César pida "actualiza el kit", "¿está al día el kit?", "/kit-update", o cuando un proyecto lleve una versión del kit anterior a la de main. Compara la versión del proyecto (.kit-version), la de las skills instaladas y la de origin/main del kit (clon local + git fetch); si todo coincide dice que está al día y termina, si las skills están viejas las reinstala y pide sesión nueva, y si el proyecto va atrás calcula el camino en ACTUALIZACIONES.md y lo aplica en una rama y un PR, un commit por versión.
---

# Actualizar el kit en un proyecto

Se corre en una sesión abierta **en la carpeta del proyecto**. Lee el kit desde su clon
local, siempre como está en `origin/main` (lo publicado), nunca desde una rama a medias.
No toca `main` del proyecto: todo va en una rama y un PR.

## 0. Dónde está el kit

`~/.claude/web-agent-kit.json` lo escribe `instalar-kit` al instalar:

```json
{ "ruta": "C:\\...\\web-agent-kit", "version": "3.6.0", "instalado": "2026-10-16" }
```

- `ruta` = el clon del kit (lo llamo `<clon>`). `version` = la de las skills instaladas.
- Si el archivo no existe (instalación anterior a la 3.6.0 o a mano): busca el clon en
  `~/Desktop/agents/web-agent-kit` y, si no está, pregúntale la ruta a César. Las skills
  instaladas cuentan como versión desconocida (= viejas).
- Si `<clon>` no es un repo git con remoto `origin`: para y dilo. Sin clon no hay cómo
  comparar (en otra máquina: `git clone https://github.com/Fockus26/web-agent-kit.git` e
  `instalar-kit`).

## 1. Las tres versiones

```bash
git -C "<clon>" fetch origin --quiet
git -C "<clon>" show origin/main:VERSION          # publicada (destino)
git -C "<clon>" status --porcelain --branch       # rama actual y cambios sin commitear
```

| Versión | De dónde |
|---|---|
| **Publicada** | `origin/main:VERSION` del clon |
| **Skills instaladas** | `version` de `~/.claude/web-agent-kit.json` |
| **Proyecto** | `.kit-version` del proyecto. Si no existe, dedúcela con la tabla "Cómo saber la versión de un proyecto sin `.kit-version`" de `ACTUALIZACIONES.md` y enseña las señales; si se contradicen, pregunta |

Enséñalas en una línea: `proyecto 3.4.0 · skills 3.5.0 · publicada 3.6.0`.

## 2. Qué toca hacer

**a) Proyecto = publicada:** "El proyecto está al día con el kit <versión>." Si además las
skills instaladas son más viejas, di que conviene reinstalarlas (paso b) y termina.

**b) Skills instaladas < publicada:** las skills nuevas solo se cargan al abrir sesión, y
las migraciones las usan. Antes de migrar nada:

- Si el clon está en `main` sin cambios (`## main...origin/main` y nada más en el
  `status`): instálalas desde ahí, que hace antes el `git pull --ff-only`:
  `powershell -ExecutionPolicy Bypass -File "<clon>\instalar-kit.ps1" -Pull`
  (macOS/Linux: `bash "<clon>/instalar-kit.sh" --pull`).
- Si el clon está en otra rama o con cambios (César está editando el kit): no lo toques.
  Dile que vuelva a `main` en el kit o que corra el instalador cuando termine.

Después para: "Abre una sesión nueva en este proyecto y escribe `/kit-update` otra vez."
No sigas con las skills viejas cargadas.

**c) Proyecto > publicada:** algo raro (se actualizó desde una rama del kit sin mergear).
Dilo y pregunta; no toques nada.

**d) Proyecto < publicada y skills al día:** sigue con el paso 3.

## 3. Copia de lectura del kit

Los pasos de migración leen y copian archivos de `<kit>`. `<kit>` es:

- `<clon>`, si está en `main` sin cambios y al día con `origin/main` (el paso 2b ya hizo el
  pull);
- si no, una copia de `origin/main` en el scratchpad, sin tocar el clon:
  `mkdir -p "<scratchpad>/kit" && git -C "<clon>" archive origin/main | tar -x -C "<scratchpad>/kit"`.

Del kit solo se lee y se copia: no hagas commits, pulls ni cambios en él.

## 4. Camino

Todas las entradas de `<kit>/ACTUALIZACIONES.md` posteriores a la versión del proyecto, de
la más vieja a la más nueva. Enséñalo como lista (versión · qué cambia en una línea) antes
de tocar nada.

## 5. Contexto del proyecto

Lee `CLAUDE.md`, `context/GIT_STATE.md`, `.gitignore`, `package.json` y
`git log --oneline -10`. Y las memorias del proyecto
(`~/.claude/projects/<este proyecto>/memory/`), por si alguna describe un flujo que el
camino cambia.

## 6. Diagnóstico de todo el camino, sin cambiar nada

Para cada versión, lo que pide su paso de diagnóstico: una tabla por versión. Junta en
**una sola tanda** de preguntas (AskUserQuestion) todo lo que las versiones piden
preguntar; no preguntes versión a versión.

Si un paso edita un archivo que el proyecto no tiene (p. ej. `context/COLORS.md` en un
proyecto que arrancó corto), créalo solo con las secciones que pide ese paso y dilo en el
diagnóstico.

## 7. Rama

Según `context/GIT_STATE.md`: modo `pr` → `chore/kit-<publicada>` desde `origin/main`
actualizado; modo `local` → desde la base.

## 8. Aplicar cada versión, en orden

Sigue sus "Pasos" en `<kit>/ACTUALIZACIONES.md` (y los prompts que citen, solo los pasos
indicados). El paso "piezas globales / instalar-kit" ya está hecho (paso 2). Al terminar
cada versión:

- escribe su número en `.kit-version` (una línea, sin nada más);
- commit solo de los archivos de esa versión:
  `chore(kit): actualiza a <versión> — <qué cambia en pocas palabras>`.

Si una versión falla a mitad, para ahí: lo hecho queda en commits y `.kit-version` dice
hasta dónde llegó.

`CLAUDE.md` del proyecto no pasa de 8 KB (`wc -c CLAUDE.md`). Si un paso lo hace pasar,
sustituye el párrafo viejo que el paso reemplaza en vez de sumar, y si aun así no cabe,
pregunta qué parte propia del proyecto se mueve a `context/`.

## 9. Verificación y cierre

- Typecheck, lint, tests y build en verde.
- Cierre según `git-flow`: push y PR con la plantilla, título
  `chore(kit): actualiza de <origen> a <destino>`. Sin changeset (es tooling). En el cuerpo:
  el camino, un resumen por versión, y en "Acciones manuales" lo que cada versión pida.
  En modo `local`: pausa de aprobación y merge como siempre.
- Si una versión dejó trabajo de diseño o implementación pendiente (p. ej. pantallas de
  estado de la 3.3.0), no lo hagas aquí: va a `context/plans/pendientes.md`, y dale a César
  el texto para Claude Design si lo hay.

## Informe final

URL del PR, camino aplicado, qué cambió (una línea por archivo), memorias tocadas,
preguntas abiertas, pendientes creados y lo que no se pudo verificar.

Y anota en `context/KIT_FEEDBACK.md` cualquier paso de la migración que fuera confuso o
estuviera mal (tipo Hueco o Fricción, pieza "ACTUALIZACIONES.md <versión>"). Se envía al
kit con `/kit-feedback`.
