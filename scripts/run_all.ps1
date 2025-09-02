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

Write-Host "==> Автопоиск описаний из интернета (GitHub/Nexus) для заполнения RU-описаний"
python .\ru_translation\fetch_online_descriptions.py

Write-Host "==> Генерация кратких RU-аннотаций на основе локальных README/контекста"
python .\ru_translation\generate_ru_summaries.py

Write-Host "==> Массовый перевод RU name/description (без меток), постобработка"
python .\ru_translation\mass_translate.py --only-missing --backup

Write-Host "==> Отчёт по описаниям модов из content.xml/README (для дополнения RU-описаний)"
python .\ru_translation\content_report.py

Write-Host "==> Отчёт модов, требующих ручной вычитки (автогенерация)"
python .\ru_translation\translation_review_report.py --json --csv

Write-Host "Готово."
