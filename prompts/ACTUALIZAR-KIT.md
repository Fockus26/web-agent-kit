# Actualizar un proyecto a la última versión del kit

El único prompt que hace falta para poner al día un proyecto, venga de la versión que venga.
Lee `.kit-version` del proyecto (o la deduce), calcula el camino en
[`ACTUALIZACIONES.md`](../ACTUALIZACIONES.md) y aplica cada versión en orden, en una rama y un
PR, con un commit por versión. No toca `main`.

Antes de pegarlo:

1. Ten la carpeta del kit **actualizada** en la máquina (clon con `git pull`, o la copia que
   te pasaron). No hace falta acceso al repo del kit.
2. Copia sus skills y agentes a la máquina (PowerShell):

   ```powershell
   $kit = "C:\Users\Admin\Documents\Work\web-agent-kit"   # o donde esté
   New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills","$env:USERPROFILE\.claude\agents" | Out-Null
   Copy-Item "$kit\.claude\skills\*" "$env:USERPROFILE\.claude\skills\" -Recurse -Force
   Copy-Item "$kit\.claude\agents\*" "$env:USERPROFILE\.claude\agents\" -Force
   ```

3. Cambia `{{RUTA_DEL_KIT}}` en el bloque por esa ruta.
4. Abre una sesión **nueva** de Claude Code en la carpeta del proyecto y pega el bloque.

---

```text
Actualiza este proyecto a la última versión del web-agent-kit.

El kit es la carpeta local {{RUTA_DEL_KIT}} (la llamo <kit>). Solo se lee y se copia desde
ella: no hagas git pull, no la clones y no la modifiques.

1. Versiones:
   - Destino: el contenido de <kit>\VERSION. Si no existe, para y dímelo (el kit es viejo).
   - Origen: `.kit-version` del proyecto. Si no existe, dedúcela con la tabla "Cómo saber la
     versión de un proyecto sin .kit-version" de <kit>\ACTUALIZACIONES.md y enséñame qué
     señales viste. Si se contradicen, pregúntame.
   - Si origen = destino: dímelo y termina.
   - Camino: todas las entradas de <kit>\ACTUALIZACIONES.md posteriores al origen, de la más
     vieja a la más nueva. Enséñamelo como lista (versión · qué cambia en una línea) antes de
     tocar nada.

2. Lee del proyecto: CLAUDE.md, context/GIT_STATE.md, .gitignore, package.json y
   `git log --oneline -10`. Y las memorias del proyecto
   (~/.claude/projects/<este proyecto>/memory/), por si alguna describe un flujo que el
   camino cambia.

3. Diagnóstico de todo el camino de una vez (sin cambiar nada): para cada versión, lo que
   pide su paso de diagnóstico. Una tabla por versión. Junta en UNA sola tanda de preguntas
   (AskUserQuestion) todo lo que las versiones piden preguntarme; no me preguntes versión a
   versión.

4. Rama según context/GIT_STATE.md: modo pr → `chore/kit-<destino>` desde origin/main
   actualizado; modo local → desde la base.

5. Aplica cada versión del camino en orden, siguiendo sus "Pasos" en <kit>\ACTUALIZACIONES.md
   (y los prompts que citen, solo los pasos indicados). Al terminar cada versión:
   - escribe su número en `.kit-version` (una línea, sin nada más),
   - commit solo de los archivos de esa versión:
     `chore(kit): actualiza a <versión> — <qué cambia en pocas palabras>`.
   Si una versión falla a mitad, para ahí: lo hecho queda en commits y `.kit-version` dice
   hasta dónde llegó.

6. Verificación al final: typecheck, lint, tests y build en verde.

7. Cierre según git-flow: push y PR con la plantilla, título
   `chore(kit): actualiza de <origen> a <destino>`. Sin changeset (es tooling). En el cuerpo:
   el camino, un resumen por versión, y en "Acciones manuales" lo que cada versión pida.
   En modo local: pausa de aprobación y merge como siempre.

8. Si alguna versión dejó trabajo de diseño o implementación pendiente (p. ej. pantallas de
   estado de la 3.3.0), no lo hagas aquí: déjalo en context/plans/pendientes.md y dame el
   texto para Claude Design si lo hay.

Informe final: URL del PR, camino aplicado, qué cambiaste (una línea por archivo), memorias
tocadas, preguntas que quedaron abiertas, pendientes creados y lo que no pudiste verificar.
Y anota en context/KIT_FEEDBACK.md cualquier paso de la migración que fuera confuso o
estuviera mal (tipo Hueco o Fricción, pieza "ACTUALIZACIONES.md <versión>").
```
