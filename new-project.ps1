<#
.SYNOPSIS
  Starts a project with the Web Agent Kit: creates the Next.js app with the kit's settings
  (TypeScript, Tailwind, App Router, Biome, React Compiler, bun) and copies the templates.

.EXAMPLE
  # New project (creates the folder)
  & "$env:USERPROFILE\Desktop\agents\web-agent-kit\new-project.ps1" -Path C:\Users\Admin\Documents\Work\my-project

.EXAMPLE
  # Project that already exists (only adds the kit's pieces; does not touch the app)
  & "...\web-agent-kit\new-project.ps1" -Path C:\Users\Admin\Documents\Work\melao -Existing

.PARAMETER NoVersion
  The project has no version or CHANGELOG: Changesets is not installed (.changeset/,
  release.yml, @changesets/cli).

.NOTES
  - It does not overwrite anything that exists (context/, scripts/, .github/...): it says so
    and skips it. That is why kit-update can run it on an old project to add what is missing.
  - Next.js 16 generates AGENTS.md + CLAUDE.md with "@AGENTS.md". It is kept: the kit's
    CLAUDE.md starts with that line so Claude keeps reading the rules for that Next version.
  - It does not commit: review with `git status` and make the first commit yourself.
#>
param(
  [Parameter(Mandatory)] [string] $Path,
  [switch] $Existing,
  [switch] $NoVersion
)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot

if (-not $Existing) {
  if (Test-Path $Path) { throw "$Path already exists. Use -Existing to add the kit to a created project." }
  $parent = Split-Path $Path -Parent
  $name = Split-Path $Path -Leaf
  New-Item -ItemType Directory -Force $parent | Out-Null
  Push-Location $parent
  try {
    # --biome and --react-compiler: the kit uses Biome (not ESLint) and React Compiler.
    # --typescript and --ts are the same. create-next-app already initializes git.
    bunx create-next-app@latest $name --ts --tailwind --app --biome --react-compiler `
      --import-alias "@/*" --use-bun --yes
    if ($LASTEXITCODE -ne 0) { throw "create-next-app failed" }
  } finally { Pop-Location }
}

if (-not (Test-Path (Join-Path $Path 'package.json'))) { throw "There is no package.json in $Path" }
Push-Location $Path
try {
  function CopyIfMissing($from, $to) {
    if (Test-Path $to) { Write-Host "  = $to already exists, left as is" -ForegroundColor Yellow; return }
    Copy-Item $from $to -Recurse
    Write-Host "  + $to"
  }

  Write-Host "Copying the kit into $Path"
  # If context/ was already there, the project followed an earlier kit version: it does not
  # get the current version (it is not migrated); the kit-update skill deduces it and updates it.
  $olderKit = Test-Path context
  CopyIfMissing "$kit\context-templates" 'context'
  CopyIfMissing "$kit\phases-templates" 'phases'
  New-Item -ItemType Directory -Force design, scripts, .github\workflows, tests\unit | Out-Null
  # `bun test ./tests/unit` fails if the folder does not exist; empty + --pass-with-no-tests passes.
  if (-not (Get-ChildItem tests\unit -Force)) { New-Item tests\unit\.gitkeep | Out-Null }
  foreach ($f in 'test-related.ts', 'pr-screenshots.ts', 'publish-pr-shots.sh', 'qa-local.ts', 'context-backup.sh') {
    CopyIfMissing "$kit\reference\scripts\$f" "scripts\$f"
  }
  CopyIfMissing "$kit\github-templates\pull_request_template.md" '.github\pull_request_template.md'
  CopyIfMissing "$kit\github-templates\workflows\ci.yml" '.github\workflows\ci.yml'
  # Version and CHANGELOG with Changesets: each PR brings its .changeset/*.md and the Action
  # keeps the version PR. That way two parallel PRs do not collide on `version` or CHANGELOG.md.
  if (-not $NoVersion) {
    CopyIfMissing "$kit\changeset-templates" '.changeset'
    CopyIfMissing "$kit\github-templates\workflows\release.yml" '.github\workflows\release.yml'
  }

  # .kit-version: which kit version the project starts with (the kit-update skill reads it
  # to compute the update path).
  if (Test-Path .kit-version) {
    Write-Host "  = .kit-version already exists ($((Get-Content .kit-version -Raw).Trim())), left as is" -ForegroundColor Yellow
  } elseif ($olderKit) {
    Write-Host "  = context/ was already there: no .kit-version. In a project session, /kit-update brings it up to date" -ForegroundColor Yellow
  } else {
    $version = (Get-Content "$kit\VERSION" -Raw).Trim()
    Set-Content .kit-version "$version`n" -NoNewline
    Write-Host "  + .kit-version ($version)"
  }

  # CLAUDE.md: the kit's, keeping the "@AGENTS.md" that Next.js 16 adds.
  $claude = Get-Content "$kit\CLAUDE.md.template" -Raw
  $current = if (Test-Path CLAUDE.md) { Get-Content CLAUDE.md -Raw } else { '' }
  if ($current -and $current.Trim() -ne '@AGENTS.md') {
    Write-Host "  = CLAUDE.md already has its own content, left as is" -ForegroundColor Yellow
  } else {
    $header = if (Test-Path AGENTS.md) { "@AGENTS.md`n`n" } else { '' }
    Set-Content CLAUDE.md ($header + $claude) -NoNewline
    Write-Host "  + CLAUDE.md (kit template$(if ($header) { ' + @AGENTS.md' }))"
  }

  # package.json scripts the skills use.
  $pkg = Get-Content package.json -Raw | ConvertFrom-Json
  $scripts = @{
    'test'            = 'bun test ./tests/unit --dots --pass-with-no-tests'
    'typecheck'       = 'next typegen && tsc --noEmit'
    'test:related'    = 'bun scripts/test-related.ts'
    'shots'           = 'node scripts/pr-screenshots.ts .pr-shots.json'
    'shots:publish'   = 'bash scripts/publish-pr-shots.sh .pr-shots'
    'qa:local'        = 'node scripts/qa-local.ts'
    'context:backup'  = 'bash scripts/context-backup.sh'
    'context:restore' = 'bash scripts/context-backup.sh --restore'
  }
  foreach ($k in $scripts.Keys) {
    if (-not $pkg.scripts.PSObject.Properties[$k]) {
      $pkg.scripts | Add-Member -NotePropertyName $k -NotePropertyValue $scripts[$k]
      Write-Host "  + script $k"
    }
  }
  ($pkg | ConvertTo-Json -Depth 20) + "`n" | Set-Content package.json -NoNewline

  # .gitignore: local PR screenshots.
  $ignore = if (Test-Path .gitignore) { Get-Content .gitignore -Raw } else { '' }
  if ($ignore -notmatch '\.pr-shots') {
    Add-Content .gitignore "`n# PR screenshots (web-agent-kit)`n.pr-shots/`n.pr-shots.json"
    Write-Host "  + .gitignore: .pr-shots"
  }
  # .qa/: measuring scripts, logs and QA sweeps. Inside the project so they resolve
  # Playwright from node_modules (from a temp folder they cannot), never committed.
  if ($ignore -notmatch '(?m)^/?\.qa/?\s*$') {
    Add-Content .gitignore "`n# QA scripts and logs (web-agent-kit)`n.qa/"
    Write-Host "  + .gitignore: .qa/"
  }
  # Test accounts (.env.test.local) never go to the repo. Next's .gitignore brings `.env*`
  # (new versions) or `.env*.local` (old ones); if neither is there, it is added.
  if ($ignore -notmatch '(?m)^\.env\*(\.local)?\s*$') {
    Add-Content .gitignore "`n# QA test accounts (web-agent-kit)`n.env*.local"
    Write-Host "  + .gitignore: .env*.local"
  }
  # The local working state of context/ (backed up to the context-state branch). The fixed
  # documents (PROJECT_CONTEXT, DESIGN_RULES, COLORS, DESIGN_TOKENS, TYPOGRAPHY, decisions/)
  # stay in git: losing the folder must not lose them. Only if context/ is not mentioned yet,
  # so a project's own choice is not overridden.
  if ($ignore -notmatch 'context/') {
    $local = @('context/CURRENT_PHASE.md', 'context/CONTENT_CHECKLIST.md', 'context/KIT_FEEDBACK.md',
      'context/GIT_STATE.md', 'context/*_INVENTORY.md', 'context/PHASE_LOG/', 'context/plans/')
    Add-Content .gitignore ("`n# local working state of context/ - backup: bun run context:backup (web-agent-kit)`n" + ($local -join "`n"))
    Write-Host "  + .gitignore: local files of context/"
  }

  # Worktrees Claude Desktop creates inside the project: they bring their own root biome.json
  # and broke `bun run lint` in the main folder. Out of git and out of Biome.
  if ($ignore -notmatch '\.claude/worktrees') {
    Add-Content .gitignore "`n# Claude Desktop worktrees (web-agent-kit)`n.claude/worktrees/"
    Write-Host "  + .gitignore: .claude/worktrees/"
  }
  if (Test-Path biome.json) {
    $biome = Get-Content biome.json -Raw | ConvertFrom-Json
    if (-not $biome.files) { $biome | Add-Member -NotePropertyName files -NotePropertyValue ([pscustomobject] @{}) }
    $before = $biome | ConvertTo-Json -Depth 20
    if ($biome.files.PSObject.Properties['ignore']) {
      # Biome 1.x
      if ($biome.files.ignore -notcontains '.claude/worktrees') { $biome.files.ignore += '.claude/worktrees' }
    } else {
      # Biome 2.x: files.includes with negation; without includes, "**" is what it processed before.
      if (-not $biome.files.PSObject.Properties['includes']) {
        $biome.files | Add-Member -NotePropertyName includes -NotePropertyValue @('**')
      }
      if ($biome.files.includes -notcontains '!**/.claude/worktrees') {
        $biome.files.includes = @($biome.files.includes) + '!**/.claude/worktrees'
      }
    }
    $after = $biome | ConvertTo-Json -Depth 20
    if ($after -ne $before) {
      $after + "`n" | Set-Content biome.json -NoNewline
      Write-Host "  + biome.json: .claude/worktrees excluded"
    }
  }

  # bash fails with a .sh in CRLF: git would convert it when cloning on Windows.
  if (-not (Test-Path .gitattributes) -or (Get-Content .gitattributes -Raw) -notmatch '\*\.sh') {
    Add-Content .gitattributes "* text=auto`n*.sh text eol=lf"
    Write-Host "  + .gitattributes: *.sh with LF"
  }

  # The scripts import 'bun' and '@playwright/test': without their types, `tsc` and
  # `next build` fail (tsconfig includes **/*.ts). Playwright's browsers are not downloaded
  # here: `bunx playwright install chromium` when screenshots or audits are needed.
  # @axe-core/playwright: the a11y gate uses it on every unit, and a pool worker does not add
  # dependencies (it ended up injecting axe from a CDN).
  $deps = @('@types/bun', '@playwright/test', '@axe-core/playwright')
  if (-not $NoVersion) { $deps += '@changesets/cli' }
  $missing = $deps | Where-Object {
    -not ($pkg.devDependencies -and $pkg.devDependencies.PSObject.Properties[$_])
  }
  if ($missing) {
    bun add -d @missing | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "bun add -d $missing failed" }
    Write-Host "  + devDependencies: $($missing -join ', ')"
  }

  # What was copied takes the project's format (quotes, semicolons, indentation).
  if ($pkg.devDependencies -and $pkg.devDependencies.PSObject.Properties['@biomejs/biome']) {
    $paths = @('package.json', 'scripts')
    if (Test-Path biome.json) { $paths += 'biome.json' }
    if (Test-Path .changeset) { $paths += '.changeset' }
    bunx biome check --write @paths | Out-Null
    Write-Host "  ~ formatted with the project's Biome: $($paths -join ', ')"
  }

  Write-Host "`nDone. Next:" -ForegroundColor Green
  Write-Host "  1. git status  -> review what was copied"
  Write-Host "  2. open Claude Code in $Path and type /project-kickoff"
  Write-Host "     (it asks whether to create the GitHub repo and the Vercel project, and with your yes it sets them up;"
  Write-Host "      have 'gh auth login' and 'bunx vercel login' done if you will want them)"
} finally { Pop-Location }
