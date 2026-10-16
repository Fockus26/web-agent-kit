# Actualizar un proyecto a la última versión del kit

Desde la 3.6.0 esto lo hace la skill **`kit-update`**; este prompt ya no se pega. Lo que
hacía (calcular el camino con `ACTUALIZACIONES.md` y aplicarlo en una rama y un PR, un
commit por versión) está ahora en `.claude/skills/kit-update/SKILL.md`, junto con la
comparación de versiones contra el kit publicado.

1. Instala el kit en la máquina (una vez, y cada vez que quieras traer lo nuevo):

   ```powershell
   powershell -ExecutionPolicy Bypass -File "<ruta del kit>\instalar-kit.ps1" -Pull
   ```

2. Abre una sesión **nueva** de Claude Code en la carpeta del proyecto y escribe:

   ```
   /kit-update
   ```

Compara la versión del proyecto (`.kit-version`), la de las skills instaladas y la de
`origin/main` del kit. Si coinciden, te dice que está al día; si las skills están viejas, las
reinstala y te pide otra sesión; si el proyecto va atrás, lo pone al día en un PR.
