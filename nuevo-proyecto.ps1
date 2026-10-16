<#
.SYNOPSIS
  Arranca un proyecto con el Web Agent Kit: crea la app Next.js con la configuración del
  kit (TypeScript, Tailwind, App Router, Biome, React Compiler, bun) y copia las plantillas.

.EXAMPLE
  # Proyecto nuevo (crea la carpeta)
  & "$env:USERPROFILE\Desktop\agents\web-agent-kit\nuevo-proyecto.ps1" -Ruta C:\Users\Admin\Documents\Work\mi-proyecto

.EXAMPLE
  # Proyecto que ya existe (solo añade lo del kit; no toca la app)
  & "...\web-agent-kit\nuevo-proyecto.ps1" -Ruta C:\Users\Admin\Documents\Work\melao -Existente

.PARAMETER SinVersion
  El proyecto no lleva versión ni CHANGELOG: no instala Changesets (.changeset/,
  release.yml, @changesets/cli).

.NOTES
  - No sobrescribe nada que ya exista (context/, scripts/, .github/…): lo avisa y lo salta.
  - Next.js 16 genera AGENTS.md + CLAUDE.md con "@AGENTS.md". Se conserva: el CLAUDE.md del
    kit empieza por esa línea para que Claude siga leyendo las reglas de la versión de Next.
  - No commitea: revisa con `git status` y haz el primer commit tú.
#>
param(
  [Parameter(Mandatory)] [string] $Ruta,
  [switch] $Existente,
  [switch] $SinVersion
)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot

if (-not $Existente) {
  if (Test-Path $Ruta) { throw "$Ruta ya existe. Usa -Existente para añadir el kit a un proyecto creado." }
  $padre = Split-Path $Ruta -Parent
  $nombre = Split-Path $Ruta -Leaf
  New-Item -ItemType Directory -Force $padre | Out-Null
  Push-Location $padre
  try {
    # --biome y --react-compiler: el kit usa Biome (no ESLint) y React Compiler.
    # --typescript y --ts son lo mismo. create-next-app ya inicializa git.
    bunx create-next-app@latest $nombre --ts --tailwind --app --biome --react-compiler `
      --import-alias "@/*" --use-bun --yes
    if ($LASTEXITCODE -ne 0) { throw "create-next-app falló" }
  } finally { Pop-Location }
}

if (-not (Test-Path (Join-Path $Ruta 'package.json'))) { throw "No hay package.json en $Ruta" }
Push-Location $Ruta
try {
  function Copiar($origen, $destino) {
    if (Test-Path $destino) { Write-Host "  = $destino ya existe, no se toca" -ForegroundColor Yellow; return }
    Copy-Item $origen $destino -Recurse
    Write-Host "  + $destino"
  }

  Write-Host "Copiando el kit en $Ruta"
  # Si ya había context/, el proyecto seguía una versión anterior del kit: no se le pone la
  # versión actual (no está migrado); la skill kit-update la deduce y lo pone al día.
  $kitAnterior = Test-Path context
  Copiar "$kit\context-templates" 'context'
  Copiar "$kit\phases-templates" 'phases'
  New-Item -ItemType Directory -Force design, scripts, .github\workflows, tests\unit | Out-Null
  # `bun test ./tests/unit` falla si la carpeta no existe; vacía + --pass-with-no-tests pasa.
  if (-not (Get-ChildItem tests\unit -Force)) { New-Item tests\unit\.gitkeep | Out-Null }
  foreach ($f in 'test-related.ts', 'pr-screenshots.ts', 'publish-pr-shots.sh', 'qa-local.ts') {
    Copiar "$kit\reference\qa-scripts\$f" "scripts\$f"
  }
  Copiar "$kit\github-templates\pull_request_template.md" '.github\pull_request_template.md'
  Copiar "$kit\github-templates\workflows\ci.yml" '.github\workflows\ci.yml'
  # Versión y CHANGELOG con Changesets: cada PR trae su .changeset/*.md y la Action mantiene
  # el PR de versión. Así dos PRs en paralelo no chocan en `version` ni en CHANGELOG.md.
  if (-not $SinVersion) {
    Copiar "$kit\changeset-templates" '.changeset'
    Copiar "$kit\github-templates\workflows\release.yml" '.github\workflows\release.yml'
  }

  # .kit-version: con qué versión del kit arranca el proyecto (la skill kit-update la lee
  # para calcular el camino de actualización).
  if (Test-Path .kit-version) {
    Write-Host "  = .kit-version ya existe ($((Get-Content .kit-version -Raw).Trim())), no se toca" -ForegroundColor Yellow
  } elseif ($kitAnterior) {
    Write-Host "  = context/ ya existía: sin .kit-version. En una sesión del proyecto, /kit-update lo pone al día" -ForegroundColor Yellow
  } else {
    $version = (Get-Content "$kit\VERSION" -Raw).Trim()
    Set-Content .kit-version "$version`n" -NoNewline
    Write-Host "  + .kit-version ($version)"
  }

  # CLAUDE.md: el del kit, conservando el "@AGENTS.md" que pone Next.js 16.
  $claude = Get-Content "$kit\CLAUDE.md.template" -Raw
  $actual = if (Test-Path CLAUDE.md) { Get-Content CLAUDE.md -Raw } else { '' }
  if ($actual -and $actual.Trim() -ne '@AGENTS.md') {
    Write-Host "  = CLAUDE.md ya tiene contenido propio, no se toca" -ForegroundColor Yellow
  } else {
    $cabecera = if (Test-Path AGENTS.md) { "@AGENTS.md`n`n" } else { '' }
    Set-Content CLAUDE.md ($cabecera + $claude) -NoNewline
    Write-Host "  + CLAUDE.md (plantilla del kit$(if ($cabecera) { ' + @AGENTS.md' }))"
  }

  # Scripts de package.json que usan las skills.
  $pkg = Get-Content package.json -Raw | ConvertFrom-Json
  $scripts = @{
    'test'          = 'bun test ./tests/unit --dots --pass-with-no-tests'
    'typecheck'     = 'next typegen && tsc --noEmit'
    'test:related'  = 'bun scripts/test-related.ts'
    'shots'         = 'node scripts/pr-screenshots.ts .pr-shots.json'
    'shots:publish' = 'bash scripts/publish-pr-shots.sh .pr-shots'
    'qa:local'      = 'node scripts/qa-local.ts'
  }
  foreach ($k in $scripts.Keys) {
    if (-not $pkg.scripts.PSObject.Properties[$k]) {
      $pkg.scripts | Add-Member -NotePropertyName $k -NotePropertyValue $scripts[$k]
      Write-Host "  + script $k"
    }
  }
  ($pkg | ConvertTo-Json -Depth 20) + "`n" | Set-Content package.json -NoNewline

  # .gitignore: capturas locales del PR.
  $ignore = if (Test-Path .gitignore) { Get-Content .gitignore -Raw } else { '' }
  if ($ignore -notmatch '\.pr-shots') {
    Add-Content .gitignore "`n# capturas para PR (web-agent-kit)`n.pr-shots/`n.pr-shots.json"
    Write-Host "  + .gitignore: .pr-shots"
  }
  # Las cuentas de prueba (.env.test.local) nunca van al repo. El .gitignore de Next trae
  # `.env*` (versiones nuevas) o `.env*.local` (viejas); si no hay ninguno, se añade.
  if ($ignore -notmatch '(?m)^\.env\*(\.local)?\s*$') {
    Add-Content .gitignore "`n# cuentas de prueba de la QA (web-agent-kit)`n.env*.local"
    Write-Host "  + .gitignore: .env*.local"
  }

  # Worktrees que Claude Desktop crea dentro del proyecto: traen su propio biome.json raíz y
  # rompían `bun run lint` en la carpeta principal. Fuera de git y fuera de Biome.
  if ($ignore -notmatch '\.claude/worktrees') {
    Add-Content .gitignore "`n# worktrees de Claude Desktop (web-agent-kit)`n.claude/worktrees/"
    Write-Host "  + .gitignore: .claude/worktrees/"
  }
  if (Test-Path biome.json) {
    $biome = Get-Content biome.json -Raw | ConvertFrom-Json
    if (-not $biome.files) { $biome | Add-Member -NotePropertyName files -NotePropertyValue ([pscustomobject] @{}) }
    $antes = $biome | ConvertTo-Json -Depth 20
    if ($biome.files.PSObject.Properties['ignore']) {
      # Biome 1.x
      if ($biome.files.ignore -notcontains '.claude/worktrees') { $biome.files.ignore += '.claude/worktrees' }
    } else {
      # Biome 2.x: files.includes con negación; sin includes, "**" es lo que procesaba antes.
      if (-not $biome.files.PSObject.Properties['includes']) {
        $biome.files | Add-Member -NotePropertyName includes -NotePropertyValue @('**')
      }
      if ($biome.files.includes -notcontains '!**/.claude/worktrees') {
        $biome.files.includes = @($biome.files.includes) + '!**/.claude/worktrees'
      }
    }
    $despues = $biome | ConvertTo-Json -Depth 20
    if ($despues -ne $antes) {
      $despues + "`n" | Set-Content biome.json -NoNewline
      Write-Host "  + biome.json: fuera .claude/worktrees"
    }
  }

  # bash falla con un .sh en CRLF: git lo convertiría al clonar en Windows.
  if (-not (Test-Path .gitattributes) -or (Get-Content .gitattributes -Raw) -notmatch '\*\.sh') {
    Add-Content .gitattributes "* text=auto`n*.sh text eol=lf"
    Write-Host "  + .gitattributes: *.sh con LF"
  }

  # Los scripts importan 'bun' y '@playwright/test': sin sus tipos, `tsc` y `next build`
  # fallan (tsconfig incluye **/*.ts). Los navegadores de Playwright no se bajan aquí:
  # `bunx playwright install chromium` cuando haga falta capturar o auditar.
  # @axe-core/playwright: la puerta a11y lo usa en cada unidad, y un worker del pool no
  # añade dependencias (acababa inyectando axe desde un CDN).
  $deps = @('@types/bun', '@playwright/test', '@axe-core/playwright')
  if (-not $SinVersion) { $deps += '@changesets/cli' }
  $faltan = $deps | Where-Object {
    -not ($pkg.devDependencies -and $pkg.devDependencies.PSObject.Properties[$_])
  }
  if ($faltan) {
    bun add -d @faltan | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "bun add -d $faltan falló" }
    Write-Host "  + devDependencies: $($faltan -join ', ')"
  }

  # Lo copiado adopta el formato del proyecto (comillas, punto y coma, sangría).
  if ($pkg.devDependencies -and $pkg.devDependencies.PSObject.Properties['@biomejs/biome']) {
    $rutas = @('package.json', 'scripts')
    if (Test-Path biome.json) { $rutas += 'biome.json' }
    if (Test-Path .changeset) { $rutas += '.changeset' }
    bunx biome check --write @rutas | Out-Null
    Write-Host "  ~ formateado con el Biome del proyecto: $($rutas -join ', ')"
  }

  Write-Host "`nListo. Siguiente:" -ForegroundColor Green
  Write-Host "  1. git status  → revisa lo copiado"
  Write-Host "  2. abre Claude Code en $Ruta y escribe /project-kickoff"
  Write-Host "     (pregunta si crea el repo en GitHub y el proyecto en Vercel, y con tu sí los configura;"
  Write-Host "      ten 'gh auth login' y 'bunx vercel login' hechos si los vas a querer)"
} finally { Pop-Location }
