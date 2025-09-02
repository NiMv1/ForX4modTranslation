# запускается из корня репозитория
$ErrorActionPreference = 'Stop'

Write-Host "==> Синхронизация t-файлов (KUDA/kuertee и др.)"
python .\ru_translation\sync_t_files.py

Write-Host "==> Автоправка content.xml (убрать плейсхолдеры/EN)"
python .\ru_translation\fix_english_content.py

Write-Host "==> Проверка полноты перевода"
python .\ru_translation\check_translation_completeness.py

Write-Host "==> Сканирование ReadText по всем XML"
python .\ru_translation\scan_readtext.py

Write-Host "==> Валидация t-файлов (наличие RU и покрытие ReadText)"
python .\ru_translation\t_validator.py

Write-Host "==> Отчёт по описаниям модов из content.xml/README (для дополнения RU-описаний)"
python .\ru_translation\content_report.py

Write-Host "Готово."
