# Migrar un proyecto a decisiones por archivo y CI en el PR de versión

Se pega en Claude Code, **abierto en la carpeta del proyecto** (sesión nueva, para que cargue
las skills actualizadas). Hace el cambio en una rama y abre un PR; no toca `main`.

El kit llega como **carpeta local ya actualizada** (no hace falta acceso al repo del kit).
Antes de pegar el prompt:

1. Pon la carpeta del kit en cualquier sitio de la máquina, por ejemplo
   `C:\kits\web-agent-kit`.
2. Actualiza las skills y agentes de la máquina desde esa carpeta (PowerShell):

   ```powershell
   $kit = "C:\kits\web-agent-kit"   # la carpeta que te pasaron
   New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills","$env:USERPROFILE\.claude\agents" | Out-Null
   Copy-Item "$kit\.claude\skills\*" "$env:USERPROFILE\.claude\skills\" -Recurse -Force
   Copy-Item "$kit\.claude\agents\*" "$env:USERPROFILE\.claude\agents\" -Force
   ```

3. En el bloque de abajo, cambia `{{RUTA_DEL_KIT}}` por esa ruta.
4. Abre una sesión **nueva** de Claude Code en la carpeta del proyecto y pega el bloque.

Qué cambió en el kit:

- **Decisiones:** ya no hay `context/DECISIONS_INDEX.md` ni archivos por tema
  (`decisions/01-colores.md`). Cada decisión es su propio archivo
  `context/decisions/D0NN-<tema>.md` y su primera línea es la fila del índice
  (`# D0NN · Categoría · Resumen · Estado`). El índice se saca con
  `grep -rh "^# D" context/decisions/`. Así dos PRs que registran decisiones no chocan, igual
  que los changesets con el CHANGELOG.
- **CI del PR de versión:** el PR `chore(release): versión` lo abre `GITHUB_TOKEN`, que no
  dispara `pull_request`, y se quedaba sin el check `ci` (había que mergearlo con bypass).
  Ahora `release.yml` lanza `ci.yml` con `workflow_dispatch` sobre la rama del PR.

Si el proyecto no usa Changesets (no tiene `.github/workflows/release.yml`), la parte de CI
no aplica: haz solo la de decisiones.

---

```text
Este proyecto sigue una versión anterior del web-agent-kit. El kit cambió dos cosas y hay que
alinear el proyecto: las decisiones pasan a un archivo por decisión (sin DECISIONS_INDEX.md) y
el CI corre sobre el PR de versión.

El kit actualizado es la carpeta local {{RUTA_DEL_KIT}} (la llamo <kit>). Es una copia que
me pasaron, no un repo: no hagas git pull, no la clones de ningún sitio y no la modifiques;
solo se lee y se copia desde ella. Antes de nada, comprueba que es la versión nueva:
debe existir <kit>\prompts\MIGRAR-DECISIONES-Y-CI.md y NO debe existir
<kit>\context-templates\DECISIONS_INDEX.md. Si no se cumple, para y dímelo.

Lee primero, del kit:
- <kit>\context-templates\decisions\README.md (formato nuevo y sección "Migrar")
- <kit>\github-templates\workflows\ci.yml y release.yml
Y del proyecto: CLAUDE.md, context/GIT_STATE.md, .gitignore y `git log --oneline -10`.

1. Diagnóstico (sin cambiar nada): dime en una tabla qué hay hoy:
   - si existe context/DECISIONS_INDEX.md, cuántas filas de decisión tiene
     (`grep -c "^| D[0-9]" context/DECISIONS_INDEX.md`) y qué archivos hay en context/decisions/,
   - cuántas secciones de decisión hay en esos archivos (`grep -rc "^## D[0-9]" context/decisions/`)
     y qué IDs están en uno de los dos lados y no en el otro,
   - si context/decisions/ y DECISIONS_INDEX.md van en git o son locales (.gitignore y
     `git ls-files context/`),
   - si existen .github/workflows/release.yml y ci.yml, y si ci.yml ya tiene workflow_dispatch,
   - PRs abiertos (`gh pr list`) que tocan DECISIONS_INDEX.md o context/decisions/
     (`gh pr view <n> --json files -q '.files[].path'`),
   - citas del formato viejo: `grep -rn "DECISIONS_INDEX\|decisions/[0-9]" --exclude-dir=node_modules --exclude-dir=.git .`,
   - memorias de este proyecto (~/.claude/projects/<este proyecto>/memory/) que hablen de
     DECISIONS_INDEX o de mergear el PR de versión con bypass.
   Si hay IDs sin detalle o detalle sin fila, dímelo antes de seguir: no inventes el que falte.

2. Rama según context/GIT_STATE.md (modo pr: `chore/decisiones-y-ci` desde origin/main
   actualizado; modo local: la rama desde la base).

3. Decisiones, siguiendo la sección "Migrar" de decisions/README.md del kit:
   - Por cada `## D0NN — <título>` de los archivos viejos, crea
     context/decisions/D0NN-<tema-kebab>.md. Primera línea:
     `# D0NN · <Categoría> · <Resumen> · <Estado>`, con Categoría, Resumen y Estado sacados de
     su fila de DECISIONS_INDEX.md (si la fila no tiene categoría, usa el tema del archivo
     viejo). Resumen de una línea (cabecera ≤ 160 caracteres); si la fila era un párrafo, lo
     que sobra va al cuerpo. Debajo, el cuerpo sin cambios, sin la línea `**Estado:**`.
   - Una fila del índice sin sección de detalle: archivo con la cabecera y
     `**Decisión:** <el resumen de la fila>` como cuerpo.
   - Copia <kit>\context-templates\decisions\README.md sobre context/decisions/README.md.
   - Comprueba que no se pierde nada:
     `ls context/decisions/D*.md | wc -l` = número de IDs distintos del índice viejo, y
     `grep -rh "^# D" context/decisions/ | sort` lista todos, en orden, sin huecos que no
     estuvieran antes. Enséñame el resultado.
   - Borra context/DECISIONS_INDEX.md y los NN-<tema>.md viejos (con `git rm` si iban en git).
   - Cambia las citas `decisions/NN-<tema>.md` por el archivo nuevo o el ID, en context/,
     phases/, .github/ y CLAUDE.md. No reescribas PHASE_LOG/ cerrados: ahí basta con que el
     ID siga siendo buscable.

4. CLAUDE.md (tope 8 KB), comparando con <kit>\CLAUDE.md.template; cambia solo lo del flujo,
   conserva lo propio del proyecto:
   - "Buscar, no leer": `decisions/` (un archivo por decisión) en vez de DECISIONS_INDEX.md,
     y el ejemplo `grep -rhi "^# D.*modal" context/decisions/`.
   - "Qué va al repo": quita DECISIONS_INDEX.
   - Cualquier otra mención del formato viejo que salga en el grep del paso 1.

5. CI (solo si existe .github/workflows/release.yml):
   - ci.yml: añade `workflow_dispatch:` a los `on:`, con el comentario del kit. No toques sus
     pasos ni sus variables: son propios del proyecto.
   - release.yml: añade, como en el del kit, `actions: write` en permissions, `id: changesets`
     en el paso de changesets/action y el paso final "CI del PR de versión". Si el
     release.yml del proyecto no tiene cambios propios frente al del kit, cópialo entero.
   - Valida la sintaxis: `bunx --bun js-yaml .github/workflows/ci.yml` y lo mismo con
     release.yml.
   - Si el nombre del job del CI no es `ci` o el check requerido de main tiene otro nombre
     (`gh api repos/{owner}/{repo}/branches/main/protection -q .required_status_checks.contexts`,
     puede dar 403 en repos privados sin Pro), dímelo: el check que se lanza tiene que
     llamarse igual que el requerido.

6. Memorias del proyecto: actualiza o borra las que describan DECISIONS_INDEX.md o el bypass
   del PR de versión.

7. Verificación: typecheck, lint, tests y build en verde (con Biome, `bunx biome check`
   ve los .md y .yml que toque la config).

8. Cierre según git-flow: commit `chore: decisiones por archivo y CI en el PR de versión`
   (solo los archivos de esta unidad), push y PR con la plantilla. Sin changeset propio (es
   tooling). En "Acciones manuales" del PR pon:
   - Los PRs abiertos que tocaban DECISIONS_INDEX.md (lista del diagnóstico): al sincronizar
     con main, su fila pasa a ser la cabecera de un archivo D0NN-<tema>.md nuevo y su cambio
     al índice se descarta. Si hay pocos, mejor mergear este PR cuando no quede ninguno.
   - Al mergear este PR, release.yml corre ya con el paso nuevo y el PR de versión (si hay
     changesets pendientes) debería recibir el check `ci`. Si no aparece: revisa el run de
     "Release" en Actions, y como salida Actions › CI › Run workflow sobre
     `changeset-release/main`.

Informe final: URL del PR, cuántas decisiones migraste (y si faltaba algo), qué cambiaste
(una línea por archivo), memorias tocadas, PRs abiertos que hay que ajustar y lo que no
pudiste verificar.
```
