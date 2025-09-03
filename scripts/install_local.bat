@echo off
setlocal enableextensions

REM Local installer launcher (ASCII only to avoid encoding issues in CMD)
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "LOG=%~dp0install_local.log"

echo Starting installer... > "%LOG%"
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_translations.ps1" -Action install -AutoOnly -Validate -Force -BackupExisting -LogPath "%LOG%" %*

set ERR=%ERRORLEVEL%
if %ERR% NEQ 0 (
  echo Installer finished with error code %ERR%. See log: "%LOG%"
  exit /b %ERR%
)

echo Done. Backups (if any) are in _backup_forx4translation under the game's extensions folder.
endlocal & exit /b 0
