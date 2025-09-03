param(
  [Parameter(Mandatory=$true)] [string]$RepoUrl,
  [string]$Ref = 'main',
  [string]$GameExtensionsPath = 'C:\Program Files (x86)\Steam\steamapps\common\X4 Foundations\extensions',
  [switch]$AutoOnly,
  [switch]$Validate,
  [switch]$BackupExisting,
  [switch]$Force,
  [switch]$DryRun,
  [string]$LogPath,
  [switch]$KeepTemp,
  [switch]$OnlyExtensionsCopy
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

function Test-IsAdmin {
  try {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch { return $false }
}

if (-not (Test-IsAdmin)) {
  Write-Warning 'Для записи в Program Files может потребоваться запуск PowerShell от имени администратора.'
}

# Прогресс-бар загрузки в файл
function Invoke-FileDownload {
  param([Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$Destination)
  $req = [System.Net.HttpWebRequest]::Create($Uri)
  $req.UserAgent = 'ForX4Downloader'
  $res = $req.GetResponse()
  try {
    $total = $res.ContentLength
    $inStream = $res.GetResponseStream()
    $dir = Split-Path -Parent $Destination
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $outStream = [System.IO.File]::Open($Destination, [System.IO.FileMode]::Create)
    try {
      $buffer = New-Object byte[] 65536
      $read = 0
      $acc = 0
      do {
        $read = $inStream.Read($buffer, 0, $buffer.Length)
        if ($read -gt 0) {
          $outStream.Write($buffer, 0, $read)
          $acc += $read
          if ($total -gt 0) {
            $pct = [int](($acc * 100) / $total)
          } else { $pct = 0 }
          Write-Progress -Activity 'Загрузка архива' -Status ("$pct%") -PercentComplete $pct
        }
      } while ($read -gt 0)
    } finally {
      $outStream.Close()
      Write-Progress -Activity 'Загрузка архива' -Completed
    }
  } finally { $res.Close() }
}

# Определяем URL ZIP-архива
function Get-ZipUrl {
  param([string]$Url, [string]$Ref)
  if ($Url.ToLower().EndsWith('.zip')) { return $Url }
  if ($Url -match 'https?://github.com/.+?/.+?($|\s|/?)') {
    # Преобразуем ссылку на репозиторий GitHub в ссылку на ZIP нужной ветки/тэга
    $clean = $Url.TrimEnd('/')
    return "$clean/archive/refs/heads/$Ref.zip"
  }
  throw "Неизвестный формат RepoUrl. Укажите прямую ссылку на .zip или GitHub-репозиторий."
}

# Настройка путей
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$tempRoot = Join-Path $env:TEMP ("forx4_repo_$ts")
$zipPath = Join-Path $tempRoot 'repo.zip'

try {
  New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

  $zipUrl = Get-ZipUrl -Url $RepoUrl -Ref $Ref
  Write-Host "==> Скачивание архива: $zipUrl"
  if ($DryRun) {
    Write-Host "[DRY] Invoke-WebRequest -OutFile $zipPath"
  } else {
    Invoke-FileDownload -Uri $zipUrl -Destination $zipPath
  }

  Write-Host "==> Распаковка архива"
  if ($DryRun) {
    Write-Host "[DRY] Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force"
  } else {
    Expand-Archive -Path $zipPath -DestinationPath $tempRoot -Force
  }

  # Находим корневую папку репозитория (обычно единственная директория после распаковки GitHub ZIP)
  $extractedDirs = Get-ChildItem -Path $tempRoot -Directory
  if ($extractedDirs.Count -eq 0) { throw 'Не найдена распакованная папка репозитория.' }
  $repoRoot = $extractedDirs[0].FullName

  if ($OnlyExtensionsCopy) {
    # Прямое копирование только каталога extensions/ из архива в папку игры
    $srcExt = Join-Path $repoRoot 'extensions'
    if (-not (Test-Path $srcExt)) { throw "В архиве отсутствует папка 'extensions': $srcExt" }

    if (-not (Test-Path $GameExtensionsPath)) {
      if ($DryRun) { Write-Host "[DRY] Создал бы папку игры: $GameExtensionsPath" }
      else { New-Item -ItemType Directory -Force -Path $GameExtensionsPath | Out-Null }
    }

    Write-Host "==> Копирование только 'extensions/' в папку игры"
    $mods = Get-ChildItem -Path $srcExt -Directory
    $totalMods = $mods.Count
    $i = 0
    foreach ($m in $mods) {
      $i++
      $modName = $m.Name
      $src = $m.FullName
      $dst = Join-Path $GameExtensionsPath $modName
      $pct = [int](($i * 100) / [Math]::Max(1,$totalMods))
      Write-Progress -Activity 'Установка модов' -Status ("[$i/$totalMods] $modName") -PercentComplete $pct

      if (Test-Path $dst) {
        if ($Force) {
          if ($BackupExisting) {
            $bkRoot = Join-Path $GameExtensionsPath '_backup_forx4translation'
            $ts2 = Get-Date -Format 'yyyyMMdd_HHmmss'
            $bkDir = Join-Path $bkRoot ("$modName`_$ts2")
            if ($DryRun) { Write-Host "[DRY] Бэкап $dst -> $bkDir" }
            else {
              New-Item -ItemType Directory -Force -Path $bkDir | Out-Null
              Copy-Item -Recurse -Force -Path $dst -Destination $bkDir
            }
          }
          if ($DryRun) { Write-Host "[DRY] Удалил бы существующую папку: $dst" }
          else { Remove-Item -Recurse -Force -Path $dst }
        } else {
          Write-Host "Существует: $dst (используйте -Force для перезаписи)"
          continue
        }
      }

      if ($DryRun) { Write-Host "[DRY] Скопировал бы $src -> $dst" }
      else { Copy-Item -Recurse -Force -Path $src -Destination $dst }
    }
    Write-Progress -Activity 'Установка модов' -Completed

    Write-Host '==> Готово.'
    return
  }

  $installer = Join-Path $repoRoot 'scripts\install_translations.ps1'
  if (-not (Test-Path $installer)) { throw "Не найден инсталлятор: $installer" }

  Write-Host "==> Запуск установщика перевода"
  Write-Progress -Activity 'Установка модов' -Status 'Запуск установщика' -PercentComplete 10

  $args = @('-ExecutionPolicy','Bypass','-File', $installer, '-Action','install', '-GameExtensionsPath', $GameExtensionsPath)
  if ($AutoOnly)       { $args += '-AutoOnly' }
  if ($Validate)       { $args += '-Validate' }
  if ($BackupExisting) { $args += '-BackupExisting' }
  if ($Force)          { $args += '-Force' }
  if ($DryRun)         { $args += '-DryRun' }
  if ($LogPath)        { $args += @('-LogPath', $LogPath) }

  Write-Host ("powershell " + ($args -join ' '))
  if (-not $DryRun) {
    $p = Start-Process -FilePath 'powershell' -ArgumentList $args -NoNewWindow -Wait -PassThru
    Write-Progress -Activity 'Установка модов' -Status 'Применение файлов...' -PercentComplete 60
    if ($p.ExitCode -ne 0) { Write-Progress -Activity 'Установка модов' -Completed; throw "Установщик завершился с кодом $($p.ExitCode)" }
  }
  Write-Progress -Activity 'Установка модов' -Status 'Завершение' -PercentComplete 100
  Write-Progress -Activity 'Установка модов' -Completed

  Write-Host '==> Готово.'
}
finally {
  if (-not $KeepTemp) {
    try {
      if ($DryRun) { Write-Host "[DRY] Удалил бы временную папку: $tempRoot" }
      else { Remove-Item -Recurse -Force -Path $tempRoot }
    } catch {}
  } else {
    Write-Host "Временная папка сохранена: $tempRoot"
  }
}
