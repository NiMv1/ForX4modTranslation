param(
  [ValidateSet('install','uninstall')]
  [string]$Action = 'install',
  [string]$GameExtensionsPath = 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\X4 Foundations\\extensions',
  [string[]]$Mods,
  [switch]$Force,
  [switch]$DryRun,
  [switch]$AutoOnly,
  [switch]$Validate,
  [switch]$BackupExisting,
  [string]$LogPath
)

$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
  try {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch { return $false }
}

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptRoot
$RepoExtensions = Join-Path $RepoRoot 'extensions'
$ManifestPath = Join-Path $GameExtensionsPath '.forx4translation_manifest.json'
$MarkerName = '.installed_by_forx4_translation'

if ($LogPath) {
  try {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $LogPath) | Out-Null
  } catch {}
}

function Write-Log {
  param([string]$msg)
  if ($LogPath) { $msg | Out-File -FilePath $LogPath -Append -Encoding UTF8 }
}

if (-not (Test-Path $RepoExtensions)) {
  Write-Error "Не найдена папка с модами: $RepoExtensions"
  exit 1
}

if (-not (Test-Path $GameExtensionsPath)) {
  if ($DryRun) {
    Write-Host "[DRY] Создал бы папку игры: $GameExtensionsPath"
    Write-Log  "[DRY] mkdir $GameExtensionsPath"
  } else {
    New-Item -ItemType Directory -Path $GameExtensionsPath -Force | Out-Null
    Write-Log  "mkdir $GameExtensionsPath"
  }
}

if (-not (Test-IsAdmin)) {
  Write-Warning 'Для записи в Program Files может потребоваться запуск PowerShell от имени администратора.'
}

function Get-TargetMods {
  param([string[]]$Filter)
  $dirs = Get-ChildItem -Path $RepoExtensions -Directory | ForEach-Object { $_.Name }
  if ($Filter -and $Filter.Count -gt 0) {
    return $dirs | Where-Object { $Filter -contains $_ }
  }
  return $dirs
}

function Test-RuAuto {
  param([string]$ModName)
  $cx = Join-Path (Join-Path $RepoExtensions $ModName) 'content.xml'
  if (-not (Test-Path $cx)) { return $false }
  try {
    [xml]$doc = Get-Content $cx -Raw -Encoding UTF8
    $node = $doc.SelectSingleNode('//content')
    if ($node -and $node.ru_auto -eq '1') { return $true }
  } catch {}
  return $false
}

function Test-ContentXml {
  param([string]$ModName)
  if (-not $Validate) { return $true }
  $cx = Join-Path (Join-Path $RepoExtensions $ModName) 'content.xml'
  if (-not (Test-Path $cx)) { Write-Host "Внимание: нет content.xml у $ModName"; return $false }
  try {
    [xml]$doc = Get-Content $cx -Raw -Encoding UTF8
    $node = $doc.SelectSingleNode('//content')
    return [bool]$node
  } catch {
    Write-Host "Внимание: невалидный content.xml у ${ModName}: $($_.Exception.Message)"
    return $false
  }
}

function Read-Manifest {
  if (Test-Path $ManifestPath) {
    try { return Get-Content $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }
  }
  return @{ installed = @(); lastUpdated = (Get-Date).ToString('s') }
}

function Write-Manifest {
  param($obj)
  $obj.lastUpdated = (Get-Date).ToString('s')
  $json = $obj | ConvertTo-Json -Depth 4
  if ($DryRun) {
    Write-Host "[DRY] Записал бы манифест: $ManifestPath"; return
  }
  $json | Out-File -FilePath $ManifestPath -Encoding UTF8
}

function Install-Mod {
  param([string]$ModName)
  $src = Join-Path $RepoExtensions $ModName
  $dst = Join-Path $GameExtensionsPath $ModName
  if (-not (Test-Path $src)) { Write-Warning "Пропуск: нет исходника $src"; return $false }
  if ($AutoOnly -and -not (Test-RuAuto -ModName $ModName)) {
    Write-Host "Пропуск: $ModName без ru_auto=1 (AutoOnly)"; Write-Log "skip AutoOnly $ModName"; return $false
  }
  if (-not (Test-ContentXml -ModName $ModName)) {
    Write-Host "Пропуск: $ModName не прошёл валидацию content.xml"; Write-Log "skip invalid $ModName"; return $false
  }

  if (Test-Path $dst) {
    if ($Force) {
      if ($BackupExisting) {
        $bkRoot = Join-Path $GameExtensionsPath '_backup_forx4translation'
        $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
        $bkDir = Join-Path $bkRoot ("$ModName`_$ts")
        if ($DryRun) { Write-Host "[DRY] Бэкап $dst -> $bkDir"; Write-Log "[DRY] backup $dst -> $bkDir" }
        else {
          New-Item -ItemType Directory -Force -Path $bkDir | Out-Null
          Copy-Item -Recurse -Force -Path $dst -Destination $bkDir
          Write-Log "backup $dst -> $bkDir"
        }
      }
      if ($DryRun) { Write-Host "[DRY] Удалил бы существующую папку: $dst"; Write-Log "[DRY] remove $dst" }
      else { Remove-Item -Recurse -Force -Path $dst; Write-Log "remove $dst" }
    } else {
      Write-Host "Существует: $dst (используйте -Force для перезаписи)"
      return $false
    }
  }
  if ($DryRun) { Write-Host "[DRY] Скопировал бы $src -> $dst"; Write-Log "[DRY] copy $src -> $dst" }
  else { Copy-Item -Recurse -Force -Path $src -Destination $dst; Write-Log "copy $src -> $dst" }

  # Маркер
  $marker = Join-Path $dst $MarkerName
  $markerContent = "installed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`nsource: $src"
  if ($DryRun) { Write-Host "[DRY] Создал бы маркер: $marker"; Write-Log "[DRY] marker $marker" }
  else { $markerContent | Out-File -FilePath $marker -Encoding UTF8; Write-Log "marker $marker" }
  return $true
}

function Uninstall-Mod {
  param([string]$ModName, [switch]$AllowNoMarker)
  $dst = Join-Path $GameExtensionsPath $ModName
  if (-not (Test-Path $dst)) { Write-Host "Пропуск: нет установленного каталога $dst"; return $false }
  $marker = Join-Path $dst $MarkerName
  if (-not (Test-Path $marker) -and -not $AllowNoMarker) {
    Write-Host "Пропуск: $ModName не помечен как установленный этим скриптом (используйте -Force для удаления)"
    return $false
  }
  if ($DryRun) { Write-Host "[DRY] Удалил бы папку: $dst"; Write-Log "[DRY] remove $dst" }
  else { Remove-Item -Recurse -Force -Path $dst; Write-Log "remove $dst" }
  return $true
}

$modsToProcess = Get-TargetMods -Filter $Mods
Write-Log ("RepoRoot: " + $RepoRoot)
Write-Log ("RepoExtensions: " + $RepoExtensions)
Write-Log ("Found mods count: " + ($modsToProcess.Count))
if ($modsToProcess.Count -gt 0) { Write-Log ("Found mods: " + ($modsToProcess -join ', ')) }
if (-not $modsToProcess -or $modsToProcess.Count -eq 0) {
  # Дополнительно выведем содержимое каталога для диагностики
  try {
    $dirsDbg = (Get-ChildItem -Path $RepoExtensions -Directory | ForEach-Object { $_.Name })
    Write-Log ("Extensions dir listing: " + ($dirsDbg -join ', '))
  } catch {}
  Write-Host 'Нет модов для обработки.'
  exit 0
}

$manifest = Read-Manifest
$installed = @()
$removed = @()

switch ($Action) {
  'install' {
    foreach ($m in $modsToProcess) {
      if (Install-Mod -ModName $m) { $installed += $m }
    }
    if (-not $DryRun) {
      $manifest.installed = ($manifest.installed + $installed | Select-Object -Unique)
      Write-Manifest -obj $manifest
    }
    Write-Host "Готово: установлено $($installed.Count)."
    Write-Log  "installed: $($installed -join ', ')"
  }
  'uninstall' {
    # Если фильтр не задан — берём из манифеста
    if (-not $Mods -or $Mods.Count -eq 0) { $modsToProcess = @($manifest.installed) }
    foreach ($m in $modsToProcess) {
      if (Uninstall-Mod -ModName $m -AllowNoMarker:$Force) { $removed += $m }
    }
    if (-not $DryRun) {
      $manifest.installed = @($manifest.installed | Where-Object { $removed -notcontains $_ })
      Write-Manifest -obj $manifest
    }
    Write-Host "Готово: удалено $($removed.Count)."
    Write-Log  "removed: $($removed -join ', ')"
  }
}
