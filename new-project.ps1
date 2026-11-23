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

.PARAMETER OnlyPieces
  For a project already under way (implies -Existing): only the pieces the skills take for
  granted (scripts/, package.json scripts and devDependencies, .gitignore, Biome, the kit
  copy in .claude/). It does not copy context/, phases/, design/, .github/, .changeset/,
  CLAUDE.md or .kit-version. Why: kit-update's piece check used -Existing and two projects
  got phases/ and CI they did not need (inversiones-js, world-flags).

.PARAMETER NoVersion
  The project has no version or CHANGELOG: Changesets is not installed (.changeset/,
  release.yml, @changesets/cli).

.PARAMETER Stack
  next (default) or wordpress. wordpress (implies -Existing and -NoVersion; creates the folder
  and `git init` if it does not exist, and a minimal package.json if there is none): the
  WordPress variants of CLAUDE.md, the PR template and CI, docker-compose.yml, .env.example,
  scripts/pull-site.sh and php-lint.sh, the WordPress .gitignore lines. It skips
  create-next-app, test:related, qa:local, @types/bun and Changesets, which assume Next/bun.
  Why: InspecChile adopted the kit with -OnlyPieces and got pieces that cannot run on
  WordPress (reference/tech/wordpress-adopt.md).

.PARAMETER Client
  With -Stack wordpress: the client's slug (lowercase, hyphens). Copies the plugin skeleton as
  wp-content/plugins/<client>-site/ with its names, only if that folder does not exist.

.EXAMPLE
  # WordPress site (an existing repo or a new folder)
  & "...\web-agent-kit\new-project.ps1" -Path C:\Users\Admin\Documents\Work\inspechile -Stack wordpress -Client inspechile

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
  [switch] $NoVersion,
  [switch] $OnlyPieces,
  [ValidateSet('next', 'wordpress')] [string] $Stack = 'next',
  [ValidatePattern('^[a-z0-9]+(-[a-z0-9]+)*$')] [string] $Client
)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot
$wp = $Stack -eq 'wordpress'
$wpKit = "$kit\reference\tech\wordpress"
if ($OnlyPieces) { $Existing = $true }
if ($wp) {
  $Existing = $true
  $NoVersion = $true
  if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Force $Path | Out-Null }
  if (-not (Test-Path (Join-Path $Path '.git'))) {
    git -C $Path init -q -b main
    Write-Host "  + git init"
  }
  # bun is still the JS tooling (Playwright for shots and a11y, sass): a minimal package.json.
  $pkgPath = Join-Path $Path 'package.json'
  if (-not (Test-Path $pkgPath)) {
    $pkgName = (Split-Path (Resolve-Path $Path) -Leaf).ToLower() -replace '[^a-z0-9-]', '-'
    Set-Content $pkgPath "{`n  `"name`": `"$pkgName`",`n  `"private`": true,`n  `"scripts`": {}`n}`n" -NoNewline
    Write-Host "  + package.json (minimal)"
  }
}

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
  # What the kit copies is written with LF: the kit's working copy on Windows is CRLF, and
  # with the project's `eol=lf` Biome failed on format and git status showed the files as
  # modified with no diff (melao). $copied collects them for that pass at the end.
  $copied = [System.Collections.Generic.List[string]]::new()
  function CopyIfMissing($from, $to) {
    if (Test-Path $to) { Write-Host "  = $to already exists, left as is" -ForegroundColor Yellow; return }
    Copy-Item $from $to -Recurse
    $copied.Add($to)
    Write-Host "  + $to"
  }
  # An .env.example the project already has gets the kit's keys it lacks, appended: skipping
  # the file left every kit variable out and they were merged by hand (InversionesJL22).
  function MergeEnvExample($from, $to) {
    if (-not (Test-Path $to)) { CopyIfMissing $from $to; return }
    $have = Get-Content $to | ForEach-Object { if ($_ -match '^\s*#?\s*([A-Za-z_][A-Za-z0-9_]*)=') { $Matches[1] } }
    $new = Get-Content $from | Where-Object { $_ -match '^\s*#?\s*([A-Za-z_][A-Za-z0-9_]*)=' -and $have -notcontains $Matches[1] }
    if (-not $new) { Write-Host "  = $to already has every kit key" -ForegroundColor Yellow; return }
    $text = [IO.File]::ReadAllText((Resolve-Path $to))
    $sep = if ($text -and -not $text.EndsWith("`n")) { "`n" } else { '' }
    [IO.File]::AppendAllText((Resolve-Path $to), "$sep`n# web-agent-kit (see $(Split-Path $from -Leaf) in the kit for what each one is)`n$($new -join "`n")`n")
    Write-Host "  + ${to}: $(@($new).Count) kit key(s) added"
  }
  function ToLf($path) {
    if (-not (Test-Path $path)) { return }
    $files = if (Test-Path $path -PathType Container) { Get-ChildItem $path -Recurse -File -Force } else { Get-Item $path }
    foreach ($f in $files) {
      if ($f.Extension -notmatch '^\.(md|ts|tsx|js|mjs|json|sh|yml|yaml|toml|txt|css|scss|php|cnf|example|template)$') { continue }
      $text = [IO.File]::ReadAllText($f.FullName)
      if ($text.Contains("`r`n")) { [IO.File]::WriteAllText($f.FullName, $text.Replace("`r`n", "`n")) }
    }
  }

  Write-Host "Copying the kit into $Path"
  # If context/ was already there, the project followed an earlier kit version: it does not
  # get the current version (it is not migrated); the kit-update skill deduces it and updates it.
  # A context/ of the project's own (plans, notes) is not a kit: it used to be taken for an
  # earlier version, and every template and .kit-version were skipped (workout).
  $olderKit = (Test-Path context\CURRENT_PHASE.md) -or (Test-Path context\PHASE_LOG)
  if (-not $OnlyPieces) {
    if ((Test-Path context) -and -not $olderKit) {
      Get-ChildItem "$kit\context-templates" -Force | ForEach-Object { CopyIfMissing $_.FullName "context\$($_.Name)" }
    } else {
      CopyIfMissing "$kit\context-templates" 'context'
    }
    CopyIfMissing "$kit\phases-templates" 'phases'
    New-Item -ItemType Directory -Force design, .github\workflows | Out-Null
  }
  New-Item -ItemType Directory -Force scripts | Out-Null
  if ($wp) {
    # test:related needs a TS import graph and qa:local Supabase/Firebase: not in WordPress.
    foreach ($f in 'pr-screenshots.ts', 'publish-pr-shots.sh', 'context-backup.sh', 'cloud-setup.sh') {
      CopyIfMissing "$kit\reference\scripts\$f" "scripts\$f"
    }
    foreach ($f in 'pull-site.sh', 'php-lint.sh') { CopyIfMissing "$wpKit\$f" "scripts\$f" }
    CopyIfMissing "$wpKit\docker-compose.yml" 'docker-compose.yml'
    MergeEnvExample "$wpKit\env.example" '.env.example'
    New-Item -ItemType Directory -Force local | Out-Null
    CopyIfMissing "$wpKit\local\mu-plugins" 'local\mu-plugins'
    CopyIfMissing "$wpKit\local\mysql-client.cnf" 'local\mysql-client.cnf'
    if ($Client) {
      $plugin = "wp-content\plugins\$Client-site"
      if (Test-Path $plugin) {
        Write-Host "  = $plugin already exists, left as is (take from $wpKit\plugin what it lacks)" -ForegroundColor Yellow
      } else {
        New-Item -ItemType Directory -Force (Split-Path $plugin) | Out-Null
        Copy-Item "$wpKit\plugin" $plugin -Recurse
        Rename-Item "$plugin\acme-site.php" "$Client-site.php"
        $snake = $Client -replace '-', '_'
        $title = (($Client -split '-') | ForEach-Object { $_.Substring(0, 1).ToUpper() + $_.Substring(1) }) -join ' '
        foreach ($f in Get-ChildItem $plugin -Recurse -File -Include *.php) {
          $text = [IO.File]::ReadAllText($f.FullName)
          $text = $text.Replace('ACME_SITE', "$($snake.ToUpper())_SITE").Replace('acme_site', "${snake}_site").
            Replace('acme-site', "$Client-site").Replace('Acme Site', "$title Site")
          [IO.File]::WriteAllText($f.FullName, $text)
        }
        $copied.Add($plugin)
        Write-Host "  + $plugin (skeleton: assets by filemtime, acf-json, migrations)"
      }
      foreach ($f in 'docker-compose.yml', '.env.example') {
        if ((Test-Path $f) -and (Get-Content $f -Raw).Contains('acme-site')) { (Get-Content $f -Raw).Replace('acme-site', "$Client-site") | Set-Content $f -NoNewline }
      }
    } else {
      Write-Host "  = no -Client: the plugin skeleton is not copied ($wpKit\plugin)" -ForegroundColor Yellow
    }
  } else {
    New-Item -ItemType Directory -Force tests\unit | Out-Null
    # `bun test ./tests/unit` fails if the folder does not exist; empty + --pass-with-no-tests passes.
    if (-not (Get-ChildItem tests\unit -Force)) { New-Item tests\unit\.gitkeep | Out-Null }
    # qa-roles.ts is the project's part of qa:local: copied once, never replaced afterwards.
    foreach ($f in 'test-related.ts', 'pr-screenshots.ts', 'publish-pr-shots.sh', 'qa-local.ts', 'qa-roles.ts', 'context-backup.sh', 'cloud-setup.sh') {
      CopyIfMissing "$kit\reference\scripts\$f" "scripts\$f"
    }
  }
  # Cloud sessions (claude.ai/code) only load what is committed in the repo: the kit's skills
  # and agents go in the project's .claude/ (replaced on each run, like install-kit), and the
  # SessionStart hook runs scripts/cloud-setup.sh (bun install + context:restore; local: no-op).
  & "$kit\install-kit.ps1" -Project . *> $null
  foreach ($d in '.claude\skills', '.claude\agents', '.claude\kit-reference') { $copied.Add($d) }
  Write-Host "  + .claude\skills, .claude\agents, .claude\kit-reference (kit copy, for cloud sessions)"
  if (Test-Path .claude\settings.json) {
    $settings = Get-Content .claude\settings.json -Raw
    if ($settings -notmatch 'cloud-setup\.sh') {
      Write-Host "  = .claude\settings.json exists without the cloud hook: add the SessionStart of $kit\reference\claude\settings.json" -ForegroundColor Yellow
    }
  } else {
    Copy-Item "$kit\reference\claude\settings.json" .claude\settings.json
    $copied.Add('.claude\settings.json')
    Write-Host "  + .claude\settings.json (SessionStart -> scripts/cloud-setup.sh)"
  }
  if (-not $OnlyPieces) {
    $tpl = if ($wp) { $wpKit } else { "$kit\github-templates" }
    $ci = if ($wp) { "$wpKit\ci.yml" } else { "$kit\github-templates\workflows\ci.yml" }
    CopyIfMissing "$tpl\pull_request_template.md" '.github\pull_request_template.md'
    CopyIfMissing $ci '.github\workflows\ci.yml'
  }
  # Version and CHANGELOG with Changesets: each PR brings its .changeset/*.md and the Action
  # keeps the version PR. That way two parallel PRs do not collide on `version` or CHANGELOG.md.
  if (-not $NoVersion -and -not $OnlyPieces) {
    CopyIfMissing "$kit\changeset-templates" '.changeset'
    CopyIfMissing "$kit\github-templates\workflows\release.yml" '.github\workflows\release.yml'
  }

  # .kit-version: which kit version the project starts with (the kit-update skill reads it
  # to compute the update path).
  if ($OnlyPieces) {
    # .kit-version and CLAUDE.md belong to kit-update's migration, not to the pieces.
  } elseif (Test-Path .kit-version) {
    Write-Host "  = .kit-version already exists ($((Get-Content .kit-version -Raw).Trim())), left as is" -ForegroundColor Yellow
  } elseif ($olderKit) {
    Write-Host "  = context/ was already there: no .kit-version. In a project session, /kit-update brings it up to date" -ForegroundColor Yellow
  } else {
    $version = (Get-Content "$kit\VERSION" -Raw).Trim()
    Set-Content .kit-version "$version`n" -NoNewline
    Write-Host "  + .kit-version ($version)"
  }

  # CLAUDE.md: the kit's, keeping the "@AGENTS.md" that Next.js 16 adds.
  $claude = Get-Content $(if ($wp) { "$wpKit\CLAUDE.md.template" } else { "$kit\CLAUDE.md.template" }) -Raw
  $current = if (Test-Path CLAUDE.md) { Get-Content CLAUDE.md -Raw } else { '' }
  if ($OnlyPieces) {
  } elseif ($current -and $current.Trim() -ne '@AGENTS.md') {
    Write-Host "  = CLAUDE.md already has its own content, left as is" -ForegroundColor Yellow
  } else {
    $header = if (Test-Path AGENTS.md) { "@AGENTS.md`n`n" } else { '' }
    Set-Content CLAUDE.md ($header + $claude) -NoNewline
    $copied.Add('CLAUDE.md')
    Write-Host "  + CLAUDE.md (kit template$(if ($header) { ' + @AGENTS.md' }))"
  }

  # package.json scripts the skills use.
  $pkg = Get-Content package.json -Raw | ConvertFrom-Json
  if (-not $pkg.scripts) { $pkg | Add-Member -NotePropertyName scripts -NotePropertyValue ([pscustomobject] @{}) }
  # `next typegen` only exists in Next.js: in Astro/Vite the typecheck is the project's own
  # (Astro: astro check) and is not invented here (world-flags, Astro 7).
  $isNext = ($pkg.dependencies -and $pkg.dependencies.PSObject.Properties['next']) -or
    ($pkg.devDependencies -and $pkg.devDependencies.PSObject.Properties['next'])
  $scripts = @{
    'test'            = 'bun test ./tests/unit --dots --pass-with-no-tests'
    'test:related'    = 'bun scripts/test-related.ts'
    'shots'           = 'node scripts/pr-screenshots.ts .pr-shots.json'
    'shots:publish'   = 'bash scripts/publish-pr-shots.sh .pr-shots'
    'qa:local'        = 'node scripts/qa-local.ts'
    'context:backup'  = 'bash scripts/context-backup.sh'
    'context:restore' = 'bash scripts/context-backup.sh --restore'
  }
  if ($wp) {
    foreach ($k in 'test', 'test:related', 'qa:local') { $scripts.Remove($k) }
    $scripts['lint:php']   = 'bash scripts/php-lint.sh'
    $scripts['site:pull']  = 'bash scripts/pull-site.sh'
    $scripts['local:up']   = 'docker compose --env-file .env.local up -d'
    $scripts['local:down'] = 'docker compose --env-file .env.local down'
    $scripts['local:wp']   = 'docker compose --env-file .env.local --profile cli run --rm wpcli wp'
    # The WordPress CLAUDE.md and CI name `bun run build:css` and the skeleton brings
    # assets/scss/site.scss, but no script compiled it (InversionesJL22).
    if ($Client) {
      $assets = "wp-content/plugins/$Client-site/assets"
      $scripts['build:css'] = "sass $assets/scss/site.scss $assets/site.css --no-source-map --style=compressed"
    }
  } elseif ($isNext) { $scripts['typecheck'] = 'next typegen && tsc --noEmit' }
  elseif (-not $pkg.scripts.PSObject.Properties['typecheck']) {
    Write-Host "  = script typecheck: not Next.js, add the project's own by hand (Astro: astro check)" -ForegroundColor Yellow
  }
  # The kit's CI and CLAUDE.md call `bun run lint` and `bun install --frozen-lockfile`. In an
  # existing npm project they were copied as they were: CI failed on both, and on Windows
  # `bun run lint` without that script ran a `lint.bat` of the system (workout ×3).
  if (-not $wp) {
    if (-not $pkg.scripts.PSObject.Properties['lint']) {
      Write-Host '  ! package.json has no "lint" script: CI and CLAUDE.md call `bun run lint`. Add it (Biome: "biome check") or change both.' -ForegroundColor Yellow
    }
    $otherLock = 'package-lock.json', 'pnpm-lock.yaml', 'yarn.lock' | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($otherLock -and -not ((Test-Path bun.lock) -or (Test-Path bun.lockb))) {
      Write-Host "  ! $otherLock and no bun.lock: the kit's CI runs ``bun install --frozen-lockfile``. Move the project to bun (bun install, commit bun.lock) or adapt .github/workflows/ci.yml." -ForegroundColor Yellow
    }
  }
  $added = 0
  $tsRewritten = $false
  foreach ($k in $scripts.Keys) {
    if (-not $pkg.scripts.PSObject.Properties[$k]) {
      $pkg.scripts | Add-Member -NotePropertyName $k -NotePropertyValue $scripts[$k]
      Write-Host "  + script $k"
      $added++
    }
  }
  # Rewritten only if a script was added: ConvertTo-Json reformats the whole file.
  if ($added) { ($pkg | ConvertTo-Json -Depth 20) + "`n" | Set-Content package.json -NoNewline }

  # .gitignore: local PR screenshots. Each line on its own: a check for "\.pr-shots" was
  # satisfied by `.pr-shots.json` alone and the folder stayed out (KREA).
  $ignore = if (Test-Path .gitignore) { Get-Content .gitignore -Raw } else { '' }
  $shots = @('.pr-shots/', '.pr-shots.json') | Where-Object {
    $ignore -notmatch "(?m)^/?$([regex]::Escape($_.TrimEnd('/')))/?[ \t]*\r?$"
  }
  if ($shots) {
    Add-Content .gitignore "`n# PR screenshots (web-agent-kit)`n$($shots -join "`n")"
    Write-Host "  + .gitignore: $($shots -join ', ')"
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
  # WordPress: production's files and dumps carry customers' personal data, never in git.
  if ($wp -and $ignore -notmatch '\.site-pull') {
    Add-Content .gitignore "`n# WordPress: production's copy, dumps, JS tooling (web-agent-kit)`n.site-pull/`n*.sql`n*.sql.gz`n*.wpress`nnode_modules/`nwp-content/debug.log"
    Write-Host "  + .gitignore: .site-pull/, dumps"
  }

  # Worktrees Claude Desktop creates inside the project: they bring their own root biome.json
  # and broke `bun run lint` in the main folder. Out of git and out of Biome.
  # A rule that ignores all of `.claude/` also ignores the kit copy (`.claude/skills/`,
  # `.claude/kit-reference/`), which goes in git: it is replaced by the two local paths, not
  # appended under (world-flags: the copy stayed out of git and was fixed by hand).
  if ($ignore -match '(?m)^/?\.claude/?\*?[ \t]*\r?$') {
    # Re-read: the blocks above appended to the file after $ignore was read.
    $ignore = (Get-Content .gitignore -Raw) -replace '(?m)^/?\.claude/?\*?[ \t]*(\r?)$', ".claude/worktrees/`$1`n.claude/settings.local.json`$1"
    Set-Content .gitignore $ignore -NoNewline
    Write-Host "  ~ .gitignore: .claude/ -> .claude/worktrees/ + .claude/settings.local.json"
  }
  if ($ignore -notmatch '\.claude/worktrees') {
    Add-Content .gitignore "`n# Claude Desktop worktrees (web-agent-kit)`n.claude/worktrees/"
    Write-Host "  + .gitignore: .claude/worktrees/"
  }
  # Out of Biome and tsc too: the kit copy in `.claude/kit-reference/` brings `.ts` scripts in
  # the kit's format, which Biome rejected and tsc included through `**/*.ts` (KREA, 3.15.0).
  $outOfTools = @('.claude/worktrees', '.claude/kit-reference')
  if (Test-Path biome.json) {
    $biome = Get-Content biome.json -Raw | ConvertFrom-Json
    if (-not $biome.files) { $biome | Add-Member -NotePropertyName files -NotePropertyValue ([pscustomobject] @{}) }
    $before = $biome | ConvertTo-Json -Depth 20
    if ($biome.files.PSObject.Properties['ignore']) {
      # Biome 1.x
      foreach ($d in $outOfTools) { if ($biome.files.ignore -notcontains $d) { $biome.files.ignore += $d } }
    } else {
      # Biome 2.x: files.includes with negation; without includes, "**" is what it processed before.
      if (-not $biome.files.PSObject.Properties['includes']) {
        $biome.files | Add-Member -NotePropertyName includes -NotePropertyValue @('**')
      }
      # `.claude/worktrees` relative to the root, not `!**/…`: inside one of those worktrees
      # its own path matches `**/.claude/worktrees`, and Biome 2.3 processed no files there
      # (`bun run lint` exit 1: workout, kit-deploy ×2). Tested on 2.2.0, 2.3.8 and 2.6.8.
      $biome.files.includes = @($biome.files.includes | Where-Object { $_ -ne '!**/.claude/worktrees' })
      # Either form of each exclusion counts as present: `!.claude/kit-reference` got a second
      # `!**/.claude/kit-reference` appended (krea).
      foreach ($p in '!.claude/worktrees', '!**/.claude/kit-reference') {
        $bare = $p -replace '^!(\*\*/)?', ''
        if (-not ($biome.files.includes | Where-Object { ($_ -replace '^!(\*\*/)?', '') -eq $bare -and $_ -like '!*' })) {
          $biome.files.includes = @($biome.files.includes) + $p
        }
      }
    }
    # "auto" means CRLF on Windows: with the `eol=lf` set below, the local lint failed on
    # every file while CI passed (workout).
    if ($biome.PSObject.Properties['formatter'] -and $biome.formatter.PSObject.Properties['lineEnding'] -and
      $biome.formatter.lineEnding -eq 'auto') {
      $biome.formatter.lineEnding = 'lf'
      Write-Host '  ~ biome.json: formatter.lineEnding auto -> lf'
    }
    $after = $biome | ConvertTo-Json -Depth 20
    if ($after -ne $before) {
      $after + "`n" | Set-Content biome.json -NoNewline
      Write-Host "  + biome.json: $($outOfTools -join ', ') excluded"
    }
  }
  if (Test-Path tsconfig.json) {
    $ts = Get-Content tsconfig.json -Raw | ConvertFrom-Json
    $exclude = @(if ($ts.PSObject.Properties['exclude']) { $ts.exclude } else { 'node_modules' })
    $new = @($outOfTools | Where-Object { $exclude -notcontains $_ })
    if ($new) {
      $ts | Add-Member -NotePropertyName exclude -NotePropertyValue (@($exclude) + $new) -Force
      ($ts | ConvertTo-Json -Depth 20) + "`n" | Set-Content tsconfig.json -NoNewline
      $tsRewritten = $true
      Write-Host "  + tsconfig.json exclude: $($new -join ', ')"
    }
  }
  # Vitest walks every folder git ignores too: from the main folder it ran the tests of a
  # worktree in `.claude/worktrees` (8 files instead of 4, and an old one failed: workout ×2).
  # Its config is code, so it is not edited here.
  $vitest = Get-ChildItem -File -Filter 'vitest.config.*' | Select-Object -First 1
  if ($vitest -and (Get-Content $vitest.FullName -Raw) -notmatch '\.claude') {
    Write-Host "  ! $($vitest.Name): add to test.exclude  [...configDefaults.exclude, '.claude/**']  (configDefaults from 'vitest/config')" -ForegroundColor Yellow
  }

  # Every text file with LF in the working copy too. With `* text=auto` alone and Windows'
  # core.autocrlf=true, a branch switch left the files in CRLF and `bun run lint` (Biome, LF)
  # failed locally while CI passed (KREA); bash also fails on a .sh in CRLF.
  # An existing global rule without `eol` gets it; one that already forces LF is left alone:
  # appending `* text=auto` after `* text=auto eol=lf` overrode it (inversiones-js).
  if (-not (Test-Path .gitattributes)) {
    Set-Content .gitattributes "* text=auto eol=lf`n" -NoNewline
    Write-Host "  + .gitattributes: LF for every text file"
  } else {
    $attrs = Get-Content .gitattributes -Raw
    if ($attrs -notmatch '(?m)^\*\s.*eol=lf') {
      if ($attrs -match '(?m)^\*\s+text=auto[ \t]*\r?$') {
        $attrs = $attrs -replace '(?m)^\*\s+text=auto[ \t]*(\r?)$', '* text=auto eol=lf$1'
        Set-Content .gitattributes $attrs -NoNewline
      } else {
        $sep = if ($attrs -and -not $attrs.EndsWith("`n")) { "`n" } else { '' }
        Add-Content .gitattributes "$sep* text=auto eol=lf`n" -NoNewline
      }
      Write-Host "  ~ .gitattributes: * text=auto eol=lf (LF for every text file)"
    }
  }

  # The scripts import 'bun' and '@playwright/test': without their types, `tsc` and
  # `next build` fail (tsconfig includes **/*.ts). Playwright's browsers are not downloaded
  # here: `bunx playwright install chromium` when screenshots or audits are needed.
  # @axe-core/playwright: the a11y gate uses it on every unit, and a pool worker does not add
  # dependencies (it ended up injecting axe from a CDN).
  $deps = if ($wp) { @('@playwright/test', '@axe-core/playwright') + $(if ($Client) { 'sass' }) } else { @('@types/bun', '@playwright/test', '@axe-core/playwright') }
  if (-not $NoVersion) { $deps += '@changesets/cli' }
  $missing = $deps | Where-Object {
    -not ($pkg.devDependencies -and $pkg.devDependencies.PSObject.Properties[$_])
  }
  if ($missing) {
    bun add -d @missing | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "bun add -d $missing failed" }
    Write-Host "  + devDependencies: $($missing -join ', ')"
  }

  foreach ($c in $copied) { ToLf $c }

  # What was copied takes the project's format (quotes, semicolons, indentation), with the
  # project's own Biome (bunx resolves node_modules/.bin first).
  if ($pkg.devDependencies -and $pkg.devDependencies.PSObject.Properties['@biomejs/biome']) {
    $paths = @('scripts')
    if ($added) { $paths += 'package.json' }
    # ConvertTo-Json left it with CRLF and one array item per line: a new project failed
    # its first `bun run lint` on it (kit-deploy, workout).
    if ($tsRewritten) { $paths += 'tsconfig.json' }
    if (Test-Path biome.json) { $paths += 'biome.json' }
    if (Test-Path .changeset) { $paths += '.changeset' }
    if (Test-Path .claude/settings.json) { $paths += '.claude/settings.json' }
    bunx biome check --write @paths | Out-Null
    Write-Host "  ~ formatted with the project's Biome: $($paths -join ', ')"
  }

  if ($OnlyPieces) {
    Write-Host "`nDone (pieces only). Review with git status." -ForegroundColor Green
    return
  }
  if ($wp) {
    Write-Host "`nDone (WordPress). Next:" -ForegroundColor Green
    Write-Host "  1. git status  -> review what was copied"
    Write-Host "  2. the deploy that matches the host: copy $wpKit\deploy-ssh.yml or deploy-ftps.yml"
    Write-Host "     to .github\workflows\deploy.yml and fill its env (SITE_PLUGIN, CHILD_THEME)"
    Write-Host "  3. copy .env.example to .env.local and fill the access"
    Write-Host "  4. open Claude Code in ${Path}: 'adopta el kit en este WordPress' -> it follows"
    Write-Host "     reference/tech/wordpress-adopt.md (pull-site, local copy, inventory, walk-through)"
    return
  }
  Write-Host "`nDone. Next:" -ForegroundColor Green
  Write-Host "  1. git status  -> review what was copied"
  Write-Host "  2. open Claude Code in $Path and type /project-kickoff"
  Write-Host "     (it asks whether to create the GitHub repo and the Vercel project, and with your yes it sets them up;"
  Write-Host "      have 'gh auth login' and 'bunx vercel login' done if you will want them)"
} finally { Pop-Location }
