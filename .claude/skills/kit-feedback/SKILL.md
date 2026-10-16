---
name: kit-feedback
description: Envía al web-agent-kit el feedback acumulado en context/KIT_FEEDBACK.md del proyecto, como un Pull Request en el repo del kit (sin clonarlo ni tocar la copia local). Úsala cuando César pida "envía el feedback al kit", "el informe para el kit", "/kit-feedback", o al cerrar la fase 09. Arma el informe agrupado por pieza del kit (lo repetido primero), lo sube como feedback/<fecha>-<proyecto>.md en una rama feedback/… con gh api, abre el PR con la etiqueta kit-feedback y marca las filas enviadas.
---

# Enviar feedback al kit

Se corre en una sesión abierta **en la carpeta del proyecto**. El resultado es un PR en el
repo del kit con un archivo nuevo; ahí se acumulan los informes de todos los proyectos hasta
que César abre una sesión en el kit y pide revisarlos (el `CLAUDE.md` del kit dice cómo).

Por qué un PR y no un bloque para pegar: los informes pegados se perdían en el chat o
llegaban de uno en uno. Como PRs se ven todos juntos, se revisan a la vez y lo que se repite
entre proyectos salta a la vista.

Por qué sin clonar: la copia local del kit puede estar a mitad de una rama de César. El PR
se crea entero con `gh api` contra GitHub.

## 1. Qué hay para enviar

Lee `context/KIT_FEEDBACK.md`. Se envían las filas del registro cuya "Propuesta" **no**
termina en `→ informe <fecha>` ni en `→ PR <…>` (ya enviadas). Si no queda ninguna: dilo y
termina.

Si César no pidió enviarlo (lo sugieres tú al cerrar la fase 09), enséñale el resumen del
paso 2 y espera su sí.

## 2. El informe

Agrupa las filas por pieza del kit y ordena por **Veces** (lo repetido primero; dentro de
una pieza, igual).

```markdown
# Informe de feedback — proyecto <nombre> — kit <.kit-version> — <AAAA-MM-DD>

Stack: <framework · base/auth · gestor de paquetes · SO> (una línea; ayuda a separar lo
general de lo propio de un stack)

## <pieza del kit> (skill / plantilla / script / prompt, con sección)
- [<Tipo> ×<Veces>] <qué pasó> → propuesta: <qué cambiar en el kit>
  Evidencia: <owner/repo#PR, rama o archivo, si sirve>

## Lo que funcionó bien y no hay que tocar
- <1-3 líneas>
```

- **Nombre:** el `#` de `CLAUDE.md` o el `name` de `package.json`. En la ruta del archivo,
  en kebab-case.
- **Evidencia:** PRs como `owner/repo#N` (un `#N` suelto apuntaría a un PR del kit).
- **Nada sensible:** el repo del kit lo ven otros. Sin secretos, sin URLs de entornos
  privados, sin datos de clientes ni de usuarios; el nombre del cliente solo si ya es el
  nombre del proyecto.

Escríbelo en el scratchpad como `<AAAA-MM-DD>-<proyecto>.md`.

## 3. El PR en el kit

Repo del kit: el `origin` del clon que dice `~/.claude/web-agent-kit.json` (`ruta`;
`git -C "<ruta>" remote get-url origin` → `owner/repo`). Si no hay archivo ni clon:
`Fockus26/web-agent-kit`.

`gh auth status` primero; sin sesión, para y dilo.

```bash
repo="Fockus26/web-agent-kit"          # el que salió arriba
rama="feedback/<proyecto>-<AAAA-MM-DD>"
archivo="feedback/<AAAA-MM-DD>-<proyecto>.md"
local="<scratchpad>/<AAAA-MM-DD>-<proyecto>.md"

# rama libre: si existe, añade -2, -3…
gh api "repos/$repo/git/ref/heads/$rama" --silent 2>/dev/null && echo "ocupada"

sha=$(gh api "repos/$repo/git/ref/heads/main" --jq .object.sha)
gh api -X POST "repos/$repo/git/refs" -f ref="refs/heads/$rama" -f sha="$sha" --silent
gh api -X PUT "repos/$repo/contents/$archivo" --silent \
  -f message="docs(feedback): <proyecto> — kit <versión>" \
  -f branch="$rama" \
  -f content="$(base64 < "$local" | tr -d '\n')"

gh label create kit-feedback --repo "$repo" --color C5DEF5 \
  --description "Informe de feedback de un proyecto" --force >/dev/null
gh pr create --repo "$repo" --base main --head "$rama" --label kit-feedback \
  --title "docs(feedback): <proyecto> — kit <versión>" --body-file "<scratchpad>/cuerpo.md"
```

Cuerpo del PR (corto; el detalle está en el archivo):

```markdown
Informe de feedback de **<proyecto>** (kit <versión>, <fecha>).

- <N> puntos: <n> Hueco · <n> Fricción · <n> Corrección · <n> Repetición
- Lo más repetido: <pieza> (×<n>), <pieza> (×<n>)

Se procesa en una sesión abierta en el kit: "revisa el feedback".
```

## 4. Marcar lo enviado

En `context/KIT_FEEDBACK.md`, añade `→ PR <owner/repo#N>` al final de la "Propuesta" de
cada fila enviada. No las borres: si el problema vuelve a pasar, se suma 1 en "Veces" de la
misma fila y se quita la marca, así el próximo envío lo lleva con la cuenta nueva.

## Informe final

URL del PR, cuántos puntos se enviaron y las 3 piezas más repetidas.
