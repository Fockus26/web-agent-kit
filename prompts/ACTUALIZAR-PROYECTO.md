# Actualizar un proyecto que seguía la versión anterior del kit

Se pega en Claude Code, **abierto en la carpeta del proyecto** (sesión nueva, para que cargue
las skills actualizadas). Hace el cambio en una rama y abre un PR; no toca `main`.

Qué cambió en el kit:

- **Worktrees:** `orchestrate` ya no crea y borra un worktree por unidad. Usa un pool fijo
  (`..\<repo>-wt\wt1..wtN`) que gestiona `wt.ps1`; `node_modules` se queda en cada slot.
- **Versión y CHANGELOG:** ningún PR toca `version` ni `CHANGELOG.md`. Cada PR con cambio
  visible agrega un `.changeset/<desc>.md` y una Action mantiene el PR
  `chore(release): versión`, que César mergea cuando quiere publicar.

---

```text
Este proyecto sigue la versión anterior del web-agent-kit. El kit cambió dos cosas y hay que
alinear el proyecto. El kit está en C:\Users\Admin\Documents\Work\web-agent-kit.

Lee primero, en ~/.claude/skills/ (ya están actualizadas):
- git-flow/SKILL.md §1.2, §2.1 (paso 6), §2.1.3 y "Migrar un proyecto existente a Changesets"
- orchestrate/SKILL.md §6, §7 y §8
Y del proyecto: CLAUDE.md, context/GIT_STATE.md, package.json y `git log --oneline -15`.

1. Diagnóstico (sin cambiar nada): dime en una tabla qué hay hoy:
   - si el proyecto lleva versión/CHANGELOG (hay CHANGELOG.md o se ha subido `version`),
   - si ya existe .changeset/ o .github/workflows/release.yml,
   - PRs abiertos (`gh pr list`) que suben `version` o tocan CHANGELOG.md,
   - planes en context/plans/ con una tanda a medias que reserve versiones o puertos,
   - si .gitignore ignora `.env*` (el pool solo copia los que git ignora),
   - menciones del flujo viejo: `grep -rn -i "changelog\|versión\|worktree\|isolation\|orden de merge" CLAUDE.md context/ .github/`,
   - memorias de este proyecto (~/.claude/projects/<este proyecto>/memory/) que hablen de
     subir versión, orden de merge por versión o worktrees nuevos.
   Si el proyecto NO lleva versión, pregúntame antes si la adoptamos; si digo que no, salta
   los pasos de Changesets.

2. Rama según context/GIT_STATE.md (modo pr: `chore/changesets` desde origin/main).

3. Changesets (si lleva versión), siguiendo la guía de migración de git-flow:
   - `bun add -d @changesets/cli`
   - copia <kit>\changeset-templates\ como .changeset\ y
     <kit>\github-templates\workflows\release.yml a .github\workflows\
   - no toques CHANGELOG.md ni `version`: la Action sigue desde ahí
   - si el proyecto usa Biome: `bunx biome check --write .changeset`
   - comprueba con `bunx --bun changeset status` que lee la config (que avise de que faltan
     changesets es normal en este PR; no corras `changeset version`)

4. Alinea los archivos del proyecto con las plantillas del kit (compara con
   <kit>\CLAUDE.md.template, <kit>\github-templates\pull_request_template.md y
   <kit>\context-templates\PHASE_LOG\README.md; cambia solo lo del flujo, conserva lo propio
   del proyecto):
   - CLAUDE.md: la línea "Versión: nadie toca `version` ni `CHANGELOG.md`…" en la sección de
     git, y el párrafo de lo gitignored ("Los slots del pool de worktrees… traen los `.env*`
     copiados, pero no context/ local"). Tope 8 KB.
   - .github/pull_request_template.md: la casilla de versión pasa a changeset.
   - context/PHASE_LOG/README.md (local): cabecera con changeset en vez de versión.
   - Cualquier otra mención del diagnóstico que describa el flujo viejo.
   - Registra la decisión en context/decisions/ + una línea en DECISIONS_INDEX.md:
     "Versión con Changesets; PR de versión lo abre la Action y lo mergea César".

5. Memorias del proyecto: actualiza o borra las que describan el flujo viejo (subir versión en
   cada PR, orden de merge por versión, worktree nuevo por unidad, copiar el .env a mano).

6. Verificación: typecheck, lint, tests y build en verde (es un cambio de tooling, pero el
   lint de Biome ve .changeset/config.json).

7. Cierre según git-flow: commit `chore: adopta changesets y el pool de worktrees del kit`
   (solo los archivos de esta unidad), push y PR con la plantilla. Sin changeset propio (es
   tooling). En "Acciones manuales" del PR pon:
   - GitHub › Settings › Actions › General › "Allow GitHub Actions to create and approve pull
     requests" (ya hecho si César lo dice)
   - GitHub › Settings › General › "Automatically delete head branches"
   - Los PRs abiertos que suben versión (lista del diagnóstico): al sincronizar con main,
     quitan su cambio de `version`/CHANGELOG.md y agregan su changeset.

8. No corras `wt init` ahora: lo hace orchestrate la primera vez que lance una tanda.

Informe final: URL del PR, qué cambiaste (una línea por archivo), memorias tocadas, PRs
abiertos que hay que ajustar y lo que no pudiste verificar.
```
