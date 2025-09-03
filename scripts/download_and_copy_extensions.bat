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
  echo [Ошибка] Установка завершилась с ошибкой. Попробуйте запустить от имени администратора.
  echo.
  echo Установка завершена с ошибкой. Чтобы выйти, нажмите ПРОБЕЛ.
  powershell -NoProfile -Command "do{$k=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')}while($k.Character -ne ' ')" 1>nul 2>nul
  exit /b 1
)

echo.
echo Готово. Бэкапы (если были) сохранены в _backup_forx4translation в папке extensions игры.
echo.
echo Установка завершена. Чтобы выйти, нажмите ПРОБЕЛ.
powershell -NoProfile -Command "do{$k=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')}while($k.Character -ne ' ')" 1>nul 2>nul
endlocal
