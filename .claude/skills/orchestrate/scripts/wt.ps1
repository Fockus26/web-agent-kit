#Requires -Version 7
<#
.SYNOPSIS
  Pool de worktrees reciclables para las tandas de `orchestrate`: N carpetas fijas por
  proyecto que nunca se borran. Cada unidad toma una libre, crea su rama ahí y al cerrar la
  libera. `node_modules` se queda en el slot: `bun install` pasa a ser incremental y no hay
  que esperar a que Windows borre miles de archivos por cada unidad.

.DESCRIPTION
  Se ejecuta desde la carpeta principal del proyecto (desde un slot también sirve: la
  principal se deduce de `git worktree list`).

    wt init    [-Count 4]              crea ..\<repo>-wt\wt1..wtN, instala y copia los .env*
    wt take    <tipo/rama> [-Slot wtN] toma un slot libre y crea (o retoma) la rama ahí
    wt free    <wtN>                   lo deja libre (detached) y borra la rama si ya está mergeada
    wt status                          tabla: slot, rama o "libre", sucio, puerto
    wt destroy <wtN> [-Force]          borra el slot de verdad (solo si está libre)

  Slot libre = HEAD detached y `git status --porcelain` vacío.

  Puerto fijo por slot: 4300 + N (wt1 → 4301, wt2 → 4302…). El servidor de desarrollo de
  ese slot va siempre en su puerto: `bun run dev -- --port <puerto>`. `take` y `free` paran
  lo que siga escuchando en ese puerto (servidores huérfanos de la unidad anterior).

  `.qa/` (scripts de medición y logs de cada slot) queda ignorado por git en todos los
  slots: `init` y `take` lo añaden a `.git/info/exclude`.

  Los `.env*` (menos `.env.example`) se copian desde la carpeta principal solo si git los
  ignora en el slot: nunca se commitean.

  Nada destructivo: sin `reset --hard`, sin `push --force`, sin borrar ramas sin mergear
  (`git branch -d`, nunca `-D`). `free` exige árbol limpio; `destroy` exige slot libre y
  confirmación. Los `take` se corren uno tras otro, no en paralelo (elegirían el mismo slot).

.PARAMETER Base
  Punto de partida de las ramas nuevas y de los slots libres. Por defecto `origin/main`; en
  un repo sin remoto, una rama local (`-Base main`).

.EXAMPLE
  pwsh -NoProfile -File "$env:USERPROFILE\.claude\skills\orchestrate\scripts\wt.ps1" init -Count 4

.EXAMPLE
  pwsh -NoProfile -File "$env:USERPROFILE\.claude\skills\orchestrate\scripts\wt.ps1" take feat/ranking-top20
  # imprime slot=wt2, rama=…, ruta=…, puerto=4302
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory, Position = 0)]
  [ValidateSet('init', 'take', 'free', 'status', 'destroy')]
  [string] $Comando,
  [Parameter(Position = 1)] [string] $Nombre,
  [ValidateRange(1, 50)] [int] $Count = 4,
  [string] $Slot,
  [string] $Base = 'origin/main',
  [switch] $Force
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false   # los códigos de salida se miran a mano
$PuertoBase = 4300

# git que falla en voz alta. (No se llama `git`: la función se llamaría a sí misma.)
function GitOk {
  $salida = & git @args
  if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') falló (código $LASTEXITCODE)" }
  $salida
}

$primera = (GitOk worktree list --porcelain | Select-Object -First 1) -replace '^worktree ', ''
$principal = [IO.Path]::GetFullPath($primera)
$pool = Join-Path (Split-Path $principal -Parent) "$(Split-Path $principal -Leaf)-wt"

function NumeroSlot([string] $s) {
  if ($s -notmatch '^wt(\d+)$') { throw "Slot inválido: '$s' (se espera wtN, p. ej. wt2)" }
  [int] $Matches[1]
}

function RutaSlot([string] $s) {
  NumeroSlot $s | Out-Null
  $ruta = Join-Path $pool $s
  if (-not (Test-Path $ruta)) { throw "No existe el slot $s en $pool (ver wt status)" }
  $ruta
}

function Slots {
  if (-not (Test-Path $pool)) { return }
  Get-ChildItem $pool -Directory | Where-Object Name -Match '^wt\d+$' |
    Sort-Object { [int] $_.Name.Substring(2) }
}

function Rama([string] $ruta) { git -C $ruta branch --show-current }   # '' si está detached
function Sucio([string] $ruta) { @(GitOk -C $ruta status --porcelain) }
function EstaLibre([string] $ruta) { -not (Rama $ruta) -and -not (Sucio $ruta) }

# `git fetch` solo si la base es una rama remota (origin/main); con una base local, nada.
function Actualizar {
  if ($Base -match '^([^/]+)/' -and (git remote) -contains $Matches[1]) {
    GitOk fetch $Matches[1] --quiet
  }
}

# Huella de las dependencias: la del lockfile (o del package.json si no hay lockfile).
function HuellaDeps([string] $ruta) {
  $archivo = 'bun.lock', 'bun.lockb', 'package.json' |
    ForEach-Object { Join-Path $ruta $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($archivo) { (Get-FileHash $archivo -Algorithm SHA256).Hash }
}

# La huella de lo instalado vive dentro de node_modules: si alguien lo borra, se reinstala.
function Instalar([string] $ruta, [switch] $SiCambio) {
  if (-not (Test-Path (Join-Path $ruta 'package.json'))) { return }
  $marca = Join-Path $ruta 'node_modules/.wt-huella'
  $huella = HuellaDeps $ruta
  if ($SiCambio -and (Test-Path $marca) -and (Get-Content $marca -Raw).Trim() -eq $huella) {
    Write-Host '  = dependencias sin cambios: no se instala'
    return
  }
  Write-Host "  … bun install en $(Split-Path $ruta -Leaf)"
  Push-Location $ruta
  try {
    bun install | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "bun install falló en $ruta" }
  } finally { Pop-Location }
  if (Test-Path (Join-Path $ruta 'node_modules')) { Set-Content $marca $huella -NoNewline }
}

function CopiarEnv([string] $ruta) {
  Get-ChildItem $principal -Filter '.env*' -File -Force | Where-Object Name -NE '.env.example' |
    ForEach-Object {
      git -C $ruta check-ignore -q -- $_.Name
      if ($LASTEXITCODE -ne 0) {
        Write-Warning "$($_.Name) no está en .gitignore: no se copia (se commitearía)"
        return
      }
      Copy-Item $_.FullName (Join-Path $ruta $_.Name) -Force
      Write-Host "  + $($_.Name)"
    }
}

# El puerto es del slot: lo que escuche ahí al tomarlo o liberarlo es un servidor que dejó
# la unidad anterior (un kill que solo mató la shell, una sesión cortada). Si se queda, el
# siguiente servidor salta a otro puerto sin avisar y cae en el de otro slot.
function PararServidores([string] $s) {
  $puerto = $PuertoBase + (NumeroSlot $s)
  $pids = if ($IsWindows) {
    Get-NetTCPConnection -LocalPort $puerto -State Listen -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty OwningProcess -Unique
  } elseif (Get-Command lsof -ErrorAction SilentlyContinue) {
    lsof -ti "tcp:$puerto" -sTCP:LISTEN
  }
  foreach ($p in $pids | Where-Object { $_ -gt 0 }) {
    Write-Host "  - servidor huérfano en el puerto $puerto (PID $p): se para"
    if ($IsWindows) { taskkill /PID $p /T /F | Out-Null } else { kill $p }
  }
}

# `.qa/` del slot (scripts de medición, logs de la suite) no se commitea nunca. Va al exclude
# común del repo, que vale para todos los worktrees sin tocar el .gitignore del proyecto.
function ExcluirQa {
  $exclude = Join-Path (Join-Path (GitOk rev-parse --path-format=absolute --git-common-dir) 'info') 'exclude'
  New-Item -ItemType Directory -Force (Split-Path $exclude) | Out-Null
  if (-not (Test-Path $exclude) -or -not (Select-String -LiteralPath $exclude -Pattern '^/?\.qa/$' -Quiet)) {
    Add-Content -LiteralPath $exclude '.qa/'
  }
}

function MostrarEstado {
  $filas = foreach ($d in Slots) {
    $rama = Rama $d.FullName
    $sucio = [bool] (Sucio $d.FullName)
    [pscustomobject] @{
      Slot   = $d.Name
      Rama   = if ($rama) { $rama } elseif ($sucio) { '(detached con cambios)' } else { 'libre' }
      Sucio  = if ($sucio) { 'sí' } else { 'no' }
      Puerto = $PuertoBase + (NumeroSlot $d.Name)
    }
  }
  if (-not $filas) { Write-Host "No hay slots en $pool. Crea el pool con: wt init"; return }
  $filas | Format-Table -AutoSize | Out-Host
}

switch ($Comando) {
  'init' {
    Actualizar
    ExcluirQa
    New-Item -ItemType Directory -Force $pool | Out-Null
    foreach ($n in 1..$Count) {
      $ruta = Join-Path $pool "wt$n"
      if (Test-Path $ruta) { Write-Host "= wt$n ya existe, se salta"; continue }
      Write-Host "+ wt$n → $ruta"
      GitOk worktree add --detach --quiet $ruta $Base
      Instalar $ruta
      CopiarEnv $ruta
    }
    MostrarEstado
  }

  'take' {
    if (-not $Nombre) { throw 'Falta la rama: wt take <tipo/rama> [-Slot wtN]' }
    GitOk check-ref-format --branch $Nombre | Out-Null
    foreach ($d in Slots) {
      if ((Rama $d.FullName) -eq $Nombre) { throw "La rama $Nombre ya está en $($d.Name) ($($d.FullName))" }
    }
    if ($Slot) {
      $ruta = RutaSlot $Slot
      if (-not (EstaLibre $ruta)) { throw "El slot $Slot no está libre (ver wt status)" }
    } else {
      $libre = Slots | Where-Object { EstaLibre $_.FullName } | Select-Object -First 1
      if (-not $libre) {
        throw "No hay slots libres en $pool. Espera a que se libere uno (wt free <wtN>) o amplía el pool (wt init -Count <N mayor>)."
      }
      $Slot = $libre.Name
      $ruta = $libre.FullName
    }

    Actualizar
    ExcluirQa
    PararServidores $Slot
    $remota = if ($Base -match '^([^/]+)/') { "$($Matches[1])/$Nombre" }
    git show-ref --verify --quiet "refs/heads/$Nombre"
    $existeLocal = $LASTEXITCODE -eq 0
    $existeRemota = $false
    if ($remota) { git show-ref --verify --quiet "refs/remotes/$remota"; $existeRemota = $LASTEXITCODE -eq 0 }

    if ($existeLocal) {
      Write-Host "  = retomo la rama local $Nombre"
      GitOk -C $ruta switch --quiet $Nombre
    } elseif ($existeRemota) {
      Write-Host "  = retomo $remota (cambios pedidos en un PR abierto)"
      GitOk -C $ruta switch --quiet -c $Nombre --track $remota
    } else {
      GitOk -C $ruta switch --quiet -c $Nombre --no-track $Base
    }
    Instalar $ruta -SiCambio
    CopiarEnv $ruta

    "slot=$Slot"
    "rama=$Nombre"
    "ruta=$ruta"
    "puerto=$($PuertoBase + (NumeroSlot $Slot))"
  }

  'free' {
    $s = if ($Nombre) { $Nombre } else { $Slot }
    if (-not $s) { throw 'Falta el slot: wt free <wtN>' }
    $ruta = RutaSlot $s
    PararServidores $s
    $sucio = Sucio $ruta
    if ($sucio) {
      throw "El slot $s tiene cambios sin commitear; no se libera. Commitea y empuja, o descártalos a mano:`n$($sucio -join "`n")"
    }
    $rama = Rama $ruta
    if ($rama) {
      git -C $ruta rev-parse --verify --quiet '@{upstream}' | Out-Null
      if ($LASTEXITCODE -eq 0) {
        $sinEmpujar = [int] (GitOk -C $ruta rev-list --count '@{upstream}..HEAD')
        if ($sinEmpujar) { Write-Warning "$rama tiene $sinEmpujar commit(s) sin empujar: la rama local se conserva" }
      }
    }
    Actualizar
    GitOk -C $ruta switch --quiet --detach $Base
    if (-not $rama) { Write-Host "$s ya estaba libre; queda en $Base"; return }

    # Mergeada = está en la base (merge normal) o su PR figura como mergeado (squash).
    git merge-base --is-ancestor $rama $Base
    $mergeada = $LASTEXITCODE -eq 0
    if (-not $mergeada -and (Get-Command gh -ErrorAction SilentlyContinue)) {
      $mergeada = (gh pr view $rama --json state --jq .state 2>$null) -eq 'MERGED'
    }
    if (-not $mergeada) {
      Write-Host "$s libre. Rama $rama conservada: todavía no está mergeada."
    } else {
      git -C $ruta branch -d $rama 2>&1 | Out-Host   # en el slot: su HEAD ya es la base
      if ($LASTEXITCODE -eq 0) {
        Write-Host "$s libre. Rama $rama borrada (ya estaba mergeada)."
      } else {
        # Squash + rama remota ya podada: git no puede probar que no se pierde nada.
        Write-Host "$s libre. Rama $rama conservada: su PR está mergeado pero git no lo ve (squash). Si sobra, bórrala tú con: git branch -D $rama"
      }
    }
  }

  'status' { MostrarEstado }

  'destroy' {
    if (-not $Nombre) { throw 'Falta el slot: wt destroy <wtN> [-Force]' }
    $ruta = RutaSlot $Nombre
    if (-not (EstaLibre $ruta)) { throw "El slot $Nombre no está libre: libéralo antes con wt free $Nombre" }
    if (-not $Force) {
      try { $r = Read-Host "¿Borrar $Nombre ($ruta) con su node_modules? [s/N]" }
      catch { throw 'Sin consola para confirmar: repite con -Force si de verdad quieres borrarlo.' }
      if ($r -notmatch '^(s|si|sí|y|yes)$') { Write-Host 'Cancelado.'; return }
    }
    # rmdir de cmd borra node_modules muchísimo más rápido que Remove-Item.
    foreach ($pesada in 'node_modules', '.next') {
      $p = Join-Path $ruta $pesada
      if (Test-Path $p) {
        if ($IsWindows) { cmd /c "rmdir /s /q `"$p`"" } else { Remove-Item $p -Recurse -Force }
      }
    }
    GitOk worktree remove $ruta
    Write-Host "- $Nombre eliminado"
  }
}
