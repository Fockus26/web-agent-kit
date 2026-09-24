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

.NOTES
  - No sobrescribe nada que ya exista (context/, scripts/, .github/…): lo avisa y lo salta.
  - Next.js 16 genera AGENTS.md + CLAUDE.md con "@AGENTS.md". Se conserva: el CLAUDE.md del
    kit empieza por esa línea para que Claude siga leyendo las reglas de la versión de Next.
  - No commitea: revisa con `git status` y haz el primer commit tú.
#>
param(
  [Parameter(Mandatory)] [string] $Ruta,
  [switch] $Existente
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
  Copiar "$kit\context-templates" 'context'
  Copiar "$kit\phases-templates" 'phases'
  New-Item -ItemType Directory -Force design, scripts, .github\workflows, tests\unit | Out-Null
  # `bun test ./tests/unit` falla si la carpeta no existe; vacía + --pass-with-no-tests pasa.
  if (-not (Get-ChildItem tests\unit -Force)) { New-Item tests\unit\.gitkeep | Out-Null }
  foreach ($f in 'test-related.ts', 'pr-screenshots.ts', 'publish-pr-shots.sh') {
    Copiar "$kit\reference\qa-scripts\$f" "scripts\$f"
  }
  Copiar "$kit\github-templates\pull_request_template.md" '.github\pull_request_template.md'
  Copiar "$kit\github-templates\workflows\ci.yml" '.github\workflows\ci.yml'

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

  # bash falla con un .sh en CRLF: git lo convertiría al clonar en Windows.
  if (-not (Test-Path .gitattributes) -or (Get-Content .gitattributes -Raw) -notmatch '\*\.sh') {
    Add-Content .gitattributes "* text=auto`n*.sh text eol=lf"
    Write-Host "  + .gitattributes: *.sh con LF"
  }

  # Los scripts importan 'bun' y '@playwright/test': sin sus tipos, `tsc` y `next build`
  # fallan (tsconfig incluye **/*.ts). Los navegadores de Playwright no se bajan aquí:
  # `bunx playwright install chromium` cuando haga falta capturar o auditar.
  $faltan = @('@types/bun', '@playwright/test') | Where-Object {
    -not $pkg.devDependencies.PSObject.Properties[$_]
  }
  if ($faltan) {
    bun add -d @faltan | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "bun add -d $faltan falló" }
    Write-Host "  + devDependencies: $($faltan -join ', ')"
  }

  # Lo copiado adopta el formato del proyecto (comillas, punto y coma, sangría).
  if ($pkg.devDependencies.PSObject.Properties['@biomejs/biome']) {
    bunx biome check --write package.json scripts | Out-Null
    Write-Host "  ~ formateado con el Biome del proyecto: package.json, scripts/"
  }

  Write-Host "`nListo. Siguiente:" -ForegroundColor Green
  Write-Host "  1. git status  → revisa y haz el primer commit"
  Write-Host "  2. (modo pr) crea el repo en GitHub y protege main"
  Write-Host "  3. abre Claude Code en $Ruta y escribe /project-kickoff"
} finally { Pop-Location }
