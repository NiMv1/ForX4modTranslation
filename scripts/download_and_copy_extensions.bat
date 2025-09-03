@echo off
setlocal
REM Скачать репозиторий (ZIP) и скопировать ТОЛЬКО папку extensions/ в игру.
REM Требуются права на запись в папку игры (часто нужны права администратора).

set PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe

REM ===== НАСТРОЙКИ ПО УМОЛЧАНИЮ =====
REM Укажете ваш URL репозитория (GitHub страница репо или прямая ссылка на ZIP)
set "REPO_URL=https://github.com/NiMv1/ForX4modTranslation/archive/refs/heads/main.zip"
set "REF=main"
REM ==================================

"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0download_and_install.ps1" ^
  -RepoUrl "%REPO_URL%" ^
  -Ref "%REF%" ^
  -GameExtensionsPath "C:\Program Files (x86)\Steam\steamapps\common\X4 Foundations\extensions" ^
  -OnlyExtensionsCopy -Force -BackupExisting %*

if errorlevel 1 (
  echo.
  echo Error: Installation failed. Try running as Administrator.
  echo.
  echo Установка завершена с ошибкой. Чтобы выйти, нажмите ПРОБЕЛ.
  powershell -NoProfile -Command "do{$k=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')}while($k.Character -ne ' ')" 1>nul 2>nul
  exit /b 1
)

echo.
echo Done. Backups (if any) are saved in _backup_forx4translation under the game's extensions folder.
echo.
echo Setup finished. Press SPACE to exit.
powershell -NoProfile -Command "do{$k=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')}while($k.Character -ne ' ')" 1>nul 2>nul
endlocal
