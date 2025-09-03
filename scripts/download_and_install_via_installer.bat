@echo off
setlocal enableextensions

REM Download repo ZIP and run installer (NOT OnlyExtensionsCopy)
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

REM ===== DEFAULT SETTINGS =====
set "REPO_URL=https://github.com/NiMv1/ForX4modTranslation/archive/refs/heads/main.zip?cb=%RANDOM%"
set "REF=main"
set "LOG=%~dp0download_and_install_via_installer.log"
REM ============================

echo Starting download and install via installer... > "%LOG%"
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0download_and_install.ps1" ^
  -RepoUrl "%REPO_URL%" ^
  -Ref "%REF%" ^
  -GameExtensionsPath "C:\Program Files (x86)\Steam\steamapps\common\X4 Foundations\extensions" ^
  -Validate -BackupExisting -Force ^
  -LogPath "%LOG%"
REM Важно: не передавать внешние аргументы (%*) во избежание случайной фильтрации -Mods

set ERR=%ERRORLEVEL%
if %ERR% NEQ 0 (
  echo Finished with error code %ERR%. See log: "%LOG%"
  exit /b %ERR%
)

echo Done. See log: "%LOG%"
endlocal & exit /b 0
