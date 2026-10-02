---
name: git-flow
description: Flujo de ramas y commits del kit. Úsala siempre que se vaya a empezar una unidad de trabajo (fase, sección, componente, feature) y siempre que una unidad de trabajo termine y esté lista para revisión. Tiene dos modos según context/GIT_STATE.md - "pr" (rama → push → Pull Request que César revisa y mergea; lo normal con repo en GitHub) y "local" (pausa de aprobación → commit → merge a la base). Cubre ramas, Conventional Commits, verificación, capturas, poda de context/, changesets (versión/changelog) y la regla de push.
---

# Git Flow

Este es el flujo de git **obligatorio** de todos los proyectos del kit. Ningún agente
commitea por su cuenta ni empieza a escribir código en la rama que esté activa por casualidad.

Hay dos momentos en los que esta skill se activa: **al abrir** una unidad de trabajo y **al
cerrarla**. Entre esos dos momentos no se toca git para nada.

---

## 0. Estado de ramas: `context/GIT_STATE.md`

Antes de crear cualquier rama, lee `context/GIT_STATE.md`. Dice el **modo** (`pr` o
`local`) y cuál es la **rama base** de la unidad que vas a abrir.

- **Modo `pr`** (repo con remoto y `main` protegida): la base es siempre `main`
  actualizada; el cierre es la sección **2A**. No hay pausa antes del commit: la revisión
  de César es el PR.
- **Modo `local`**: rama madre opcional, pausa de aprobación, merge local; el cierre es la
  sección **2B**.

Si el archivo no existe, pregúntale a César el modo una vez y créalo desde la plantilla
del kit (`context-templates/GIT_STATE.md`). Forma mínima en modo `local`:

```markdown
# Git State

## Rama madre activa
`{{rama o "ninguna — las unidades salen directo de main"}}`

## Rama base de la próxima unidad
`{{main | nombre-de-la-rama-madre}}`

## Ramas de trabajo abiertas
| Rama | Base | Unidad | Estado |
|---|---|---|---|
```

Este archivo es la fuente de verdad de "¿a dónde mergeo cuando termine?". Nunca lo deduzcas
de `git branch --show-current`: si algo salió mal antes, esa rama puede no ser la correcta.

---

## 1. Al ABRIR una unidad de trabajo

### 1.1 Decidir si hace falta rama madre (solo modo `local`)

En modo `pr` no hay ramas madre: cada unidad sale de `main` y vuelve por su PR. Un bloque
grande se parte en varios PR pequeños (y, si son muchos a la vez, lo reparte la skill
`orchestrate`).

En modo `local`, pregúntale a César **una sola vez por bloque de trabajo**, no por cada componente:

- **Proyecto pequeño / trabajo suelto** (una landing, un fix, dos o tres componentes):
  las ramas de trabajo salen directo de `main`. No hay rama madre.
- **Bloque grande** (integrar todo el diseño, el módulo de autenticación completo, un
  checkout entero): se crea una **rama madre** desde `main`, y cada pieza sale como
  **sub-rama** de esa madre.

Ejemplo de bloque grande:

```
main
 └── design/integration            ← rama madre (base de todas las de abajo)
      ├── design/hero              ← sub-rama, base = design/integration
      ├── design/navbar
      └── design/pricing
```

Cuando creas una rama madre, actualiza `GIT_STATE.md` para que todas las unidades
siguientes salgan de ella sin volver a preguntar.

### 1.2 Crear la rama

```bash
git checkout <rama-base>
git pull --ff-only origin <rama-base>   # solo si la base ya existe en remoto
git checkout -b <tipo>/<descripcion-kebab-case>
```

En un **slot del pool de worktrees** (unidad delegada por `orchestrate`), la rama ya viene
creada: la hizo `wt take` desde `origin/main`. No crees otra ni cambies de rama.

**Tipos válidos:** `feat`, `fix`, `refactor`, `style`, `docs`, `chore`, `perf`, `test`,
`design`, `a11y`, `seo`.

Reglas del nombre: minúsculas, sin acentos, sin espacios, máximo ~5 palabras después del tipo.

| Bien | Mal |
|---|---|
| `feat/auth-magic-link` | `feature/Autenticación con magic link` |
| `design/hero` | `hero` |
| `fix/footer-broken-links` | `fix/varias-cosas` |

En modo `local`, registra la rama nueva en la tabla de `GIT_STATE.md` con su base y su
estado `abierta` (en modo `pr` el estado es `gh pr list`; no hay tabla que mantener).

### 1.3 Confirmar y arrancar

Dile a César en una línea: rama creada, cuál es su base, y qué se va a hacer en ella.
A partir de aquí, git no se vuelve a tocar hasta que la unidad esté terminada.

---

## 2. Al CERRAR una unidad de trabajo

### 2.1 Puertas previas (no negociables)

Antes de siquiera mencionar un commit:

1. **Si la unidad tocó UI:** la skill `a11y` ya tiene que haber corrido y estar en verde, o
   con sus hallazgos abiertos explícitamente aceptados por César. Sin eso, no se cierra.
2. **Si la unidad cerró una sección con contenido, una página, o inicializó el repo:** la
   skill `seo` ya tiene que haber corrido.
3. `bun run build` (o el comando de build del proyecto) pasa sin errores.
4. `bunx tsc --noEmit` y el linter pasan, si el proyecto los tiene configurados.
5. **Tests:** durante el trabajo bastó `bun run test:related`; aquí va la suite completa
   (`bun run test`, con `--dots`). CI la vuelve a correr en el PR.
6. **Changeset**, si el proyecto lleva versión (tiene `.changeset/`): si quien usa el sitio
   nota el cambio, agrega `.changeset/<desc>.md` (ver 2.1.3). No toques `version` ni
   `CHANGELOG.md`: los genera el PR de versión. Docs, tests, CI y refactors: sin changeset.
7. **Capturas**, si cambió algo visible (ver 2.1.1).
8. **Podar `context/`** (ver 2.1.2).
9. **Feedback para el kit**: repasa la unidad. ¿César corrigió algo que hiciste siguiendo el
   kit, te pidió lo mismo por segunda vez, hizo a mano un paso que el kit podría hacer, o el
   kit no decía qué hacer? Fila en `context/KIT_FEEDBACK.md` (o suma 1 a "Veces" si ya
   existe). Si no hubo nada, no se escribe nada. Un worker lo pone en su informe.

Si alguna falla, no es momento de commitear: arréglalo o repórtalo.

#### 2.1.1 Capturas para la revisión

Si la unidad cambió algo visible y el sitio está corriendo:

1. Escribe `.pr-shots.json` (gitignored) con los estados que cambiaron: móvil (375) y
   escritorio (1280), claro y oscuro (`"scheme": "both"`), y "antes" solo si ayuda a ver
   el cambio. Para llegar a un estado usa `steps` (clics, esperas) o `storage`.
2. `bun run shots` (node + Playwright; no con bun: en Windows se cuelga).
3. Modo `pr`: `bun run shots:publish` → pega el markdown que imprime en la sección
   "Capturas" del PR. Modo `local`: da las rutas de los PNG en la pausa de aprobación.

**No abras las imágenes** para revisarlas: tu verificación ya la hiciste midiendo el DOM,
y cada imagen vista cuesta muchos tokens. Si una captura falla, no bloquea: se dice en el
PR ("Capturas: no disponibles — <motivo>").

#### 2.1.2 Podar `context/` antes de cerrar

```bash
wc -c CLAUDE.md context/CURRENT_PHASE.md              # tope ~8000 / ~4000
grep -rh "^# D" context/decisions/ | awk 'length > 200'   # cabeceras que son párrafos
```

- La narrativa de la unidad (qué, verificado, no verificado, hallazgos) → `PHASE_LOG/<rama>.md`.
- En `CURRENT_PHASE.md` queda la fila de la unidad con su estado y el enlace; lo cerrado
  de unidades anteriores que siga ahí, se mueve.
- Decisiones: un archivo `decisions/D0NN-<tema>.md` por decisión, con su cabecera de una
  línea. No hay índice compartido que editar: dos PRs que deciden cosas no chocan.

#### 2.1.3 Changesets: versión y CHANGELOG sin conflictos

`bunx changeset` hace preguntas y no sirve para un agente: el archivo se escribe a mano.
Nombre en kebab-case, descriptivo y único (`.changeset/repetir-combinacion.md`):

```md
---
"<name de package.json>": minor
---

Ahora puedes repetir una combinación desde el historial.
```

Salto: **major** rompe datos guardados o quita algo · **minor** función nueva · **patch**
arreglo. El texto, en lenguaje de usuario. Dos PRs en paralelo no chocan: cada uno trae su
archivo.

Al llegar a `main`, la Action `release.yml` abre (o actualiza) el PR
`chore(release): versión`, que junta los changesets, sube `version` y escribe el
`CHANGELOG.md`. **Lo abre la Action y lo mergea César** cuando quiere publicar; ningún agente
lo edita ni lo mergea. En modo `local` no hay Action: cuando César pide publicar,
`bunx --bun changeset version` en la base y el commit `chore(release): versión` pasa por la
pausa de aprobación como cualquier otro.

#### Migrar un proyecto existente a Changesets

En un PR propio, `chore/changesets`, sin mezclar con otra cosa:

1. `bun add -d @changesets/cli`.
2. Copia del kit `changeset-templates/` como `.changeset/` y
   `github-templates/workflows/release.yml` a `.github/workflows/`.
3. `CHANGELOG.md` y `version` se quedan como están: la Action continúa desde ahí (la
   versión nueva va encima de la última entrada).
4. Añade `workflow_dispatch:` a los `on:` de `.github/workflows/ci.yml`: `release.yml` lo
   usa para correr el CI sobre el PR de versión (lo abre `GITHUB_TOKEN`, que no dispara
   `pull_request`), y así ese PR tiene el check `ci` sin saltarse la protección.
5. Acción manual de César en GitHub: *Settings › Actions › General › Allow GitHub Actions
   to create and approve pull requests*.

Los PRs que ya estaban abiertos con su subida de versión se ajustan al sincronizar con
`main`: quitan su cambio de `version`/`CHANGELOG.md` y agregan su changeset.

---

## 2A. Cierre en modo `pr`

En tu rama puedes commitear y empujar **sin pedir permiso**: la aprobación de César es su
revisión del PR.

```bash
git add <archivos concretos de la unidad>          # nunca -A a ciegas
git commit -m "<tipo>(<alcance>): <descripción>"   # uno o varios, Conventional Commits
git push -u origin <rama>
gh pr create --base main --title "<tipo>(<alcance>): <descripción>" --body-file <archivo>
```

El cuerpo sigue `.github/pull_request_template.md`: qué cambia, por qué, cómo probarlo,
**capturas**, cómo se verificó y qué no, decisiones tomadas con su alternativa, y
**acciones manuales** (SQL, dashboards, orden de despliegue).

Después:

- **Nunca** `gh pr merge`, nunca auto-merge, nunca push a `main`. El merge (squash) es de César.
- ¿Cambios pedidos en el PR? Nuevos commits en la misma rama + push. Sin amend ni
  force-push sobre lo empujado.
- ¿`main` avanzó y hay conflicto? `git fetch origin && git merge origin/main` (merge, no
  rebase), resuelve y vuelve a pasar la verificación. Conflicto típico cuando hay PRs en
  paralelo: los índices de `context/` (se conservan las filas de los dos lados).
- El PR `chore(release): versión` lo abre la Action; lo mergea César; ningún agente lo edita
  ni lo mergea.
- Tras el merge: `git switch main && git pull`. Ojo: si el PR dejó de trackear archivos,
  el pull los borra del disco — cópialos fuera antes si hacen falta.

## 2B. Cierre en modo `local`

### 2.2 Pausa de aprobación — OBLIGATORIA

**Nunca commitees sin aprobación explícita de César.** Preséntale esto y **detente**:

```
## Listo para revisión — <unidad>

**Rama:** <rama-de-trabajo>  ·  **Base:** <rama-base>

### Qué se hizo
- <2-5 bullets concretos>

### Archivos tocados
- <ruta> — <qué cambió en una línea>

### Verificaciones
- a11y: <✅ sin hallazgos / ⚠️ N hallazgos abiertos, cuáles>
- seo: <✅ / N/A>
- build / typecheck / lint: <✅ / ❌>

### Cómo revisarlo
<ruta o URL local exacta donde mirarlo — ej. `bun dev` → http://localhost:3000/#pricing>

### Commit propuesto
`<tipo>(<alcance>): <descripción>`

¿Lo apruebo y sigo con el merge, o hay algo que ajustar?
```

Espera respuesta. "Se ve bien", "dale", "aprobado" cuentan como aprobación. El silencio no.
Si César pide cambios, se aplican y se vuelve a presentar este mismo bloque desde cero.

### 2.3 Commit

Conventional Commits: `<tipo>(<alcance>): <descripción>`

- Modo imperativo en español: "agrega", no "agregado" ni "agregando".
- Primera línea < 72 caracteres, sin punto final.
- Cuerpo opcional tras una línea en blanco, para el "por qué" si no es obvio.
- `git add` **solo los archivos de esta unidad**. Nunca `git add -A` a ciegas: si hay
  archivos sueltos de otra cosa, se quedan fuera y lo mencionas.

```bash
git add <archivos concretos>
git commit -m "<tipo>(<alcance>): <descripción>"
```

**Si el diff mezcla temas sin relación causal** (un fix de accesibilidad en un componente
viejo + una feature nueva de pagos), divídelo en dos commits antes de mergear, y dilo. No
fuerces todo a un commit por comodidad.

### 2.4 Merge a la rama base

```bash
git checkout <rama-base>
git merge --no-ff <rama-de-trabajo>
```

`--no-ff` siempre: conserva visible en el historial que hubo una unidad de trabajo separada.

Si hay conflicto: **para y avisa**. No resuelvas conflictos por tu cuenta sin mostrarle a
César qué lado se queda con qué. Un merge mal resuelto es la forma más silenciosa de perder
trabajo suyo.

### 2.5 Push — la regla clave

```
¿La rama base es main (o master)?
├── NO  → git push origin <rama-base>          ← push automático, ya está
└── SÍ  → NO HAGAS PUSH. Se lo dices a César.
```

- **Base ≠ main** (es una rama madre como `design/integration`): commit → merge → **push**.
  El push a una rama madre es seguro y mantiene el trabajo respaldado en remoto.
- **Base = main**: commit → merge → **y ahí te detienes**. Reporta:

  ```
  ✅ Mergeado a main localmente. No hice push — main lo empujas tú cuando quieras.
     Cuando estés listo: git push origin main
  ```

Esto aplica también cuando se cierra una **rama madre completa** contra `main`: se mergea,
no se empuja.

### 2.6 Cierre

- Actualiza la fila de la rama en `GIT_STATE.md` a `mergeada`.
- **No borres la rama de trabajo.** Borrar ramas es destructivo y es decisión de César.
  Si se acumulan muchas, ofrécele la lista de las ya mergeadas para que él decida.
- Reporta en una línea: qué se commiteó, a dónde se mergeó, y si se hizo push o no.

---

## 3. Prohibiciones absolutas

Nunca ejecutes, ni siquiera si parece la salida más rápida de un problema:

- `git reset --hard`
- `git push --force` / `--force-with-lease`
- `git checkout .` / `git restore .` / `git clean -f`
- `git branch -D` / `git branch -d`
- `git rebase` sobre ramas ya empujadas
- `git commit --amend` sobre un commit ya empujado
- `git stash drop` / `git stash clear`

Única excepción: `wt free` (skill `orchestrate`) borra con `git branch -d` la rama de un slot
ya mergeada; nunca con `-D`.

Si crees que uno de estos es la solución, **descríbeselo a César con qué se perdería
exactamente** y deja que él lo ejecute. Cuando algo se enreda, la salida segura casi siempre
es una rama nueva, no reescribir historia.

---

## 4. Ejemplo completo

Bloque grande: integrar el diseño de una landing.

```bash
# ── Abrir el bloque ────────────────────────────────
git checkout main
git checkout -b design/integration          # rama madre
# GIT_STATE.md: rama madre activa = design/integration

# ── Unidad 1: el hero ──────────────────────────────
git checkout -b design/hero                 # base = design/integration
# ...se implementa, corre a11y, corre build...
# → PAUSA: se le presenta a César. Él aprueba.
git add components/sections/Hero.tsx components/ui/Button.tsx
git commit -m "feat(hero): implementa sección hero con CTA principal"
git checkout design/integration
git merge --no-ff design/hero
git push origin design/integration          # base ≠ main → push ✅

# ── Unidad 2: pricing ──────────────────────────────
git checkout -b design/pricing
# ...mismo ciclo...

# ── Cerrar el bloque contra main ───────────────────
git checkout main
git merge --no-ff design/integration
# base = main → SIN push. Se le avisa a César.
```
