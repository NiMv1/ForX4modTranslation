# Русификация модов для X4: Foundations (сборка RE 1.88 HF4 / 7.60)

Проект для перевода и нормализации контента модов X4 на русский язык. Источник модов: распакованные каталоги в `extensions/`. Целевая сборка: «Сборка модов на основе RE 1.88 HF4 (7.60).rar» - русифицированная + дополнительные моды (см. ниже).

## Структура
- `extensions/` — каталоги модов (распакованные). В репозитории хранятся только текстовые файлы (XML и др.), тяжёлые ассеты игнорируются `.gitignore`.
- `ru_translation/` — утилиты для автоправки и проверки перевода.
- `scripts/` — сценарии запуска типовых операций.

## Дополнительные моды сверх базовой сборки
В набор включены переводы модов из `extensions/`. Часть из них может отсутствовать в архиве «Сборка модов на основе RE 1.88 HF4 (7.60).rar».

На текущий момент дополнительно включён:
- Invisible Force Field (NexusMods): https://www.nexusmods.com/x4foundations/mods/1194

Если вы используете этот мод — установщик скопирует его переведённые файлы при выполнении команды установки.

## Статус
Перевод подготовлен и проверен для релиза:
- Автогенерация RU name/description включена (`ru_auto="1"`) для 99/99 модов.
- Отчёт качества показывает 0 проблем.

## Принципы
- Не коммитим тяжёлые ассеты (`.cat/.dat`, `assets/`, `sfx/`, `previews/`, изображения, аудио) — чтобы репозиторий оставался лёгким.
- Исправления в t-файлах выполняются через выравнивание русских ID с английским источником; при отсутствии перевода подставляется EN-текст, чтобы в игре не было `ReadText`.

## Установка и удаление модов (инсталлятор)
Для копирования переведённых модов в игру используйте `scripts/install_translations.ps1` либо просто перекиньте файлы из `extensions/` в `C:\Program Files (x86)\Steam\steamapps\common\X4 Foundations\extensions`.

Требуемый путь (по умолчанию): `C:\Program Files (x86)\Steam\steamapps\common\X4 Foundations\extensions`

- Установка всех модов из репозитория:
```
powershell -ExecutionPolicy Bypass -File .\scripts\install_translations.ps1 -Action install
```

- Установка только автосгенерированных (помеченных `ru_auto="1"`), с валидацией и бэкапом существующих:
```
powershell -ExecutionPolicy Bypass -File .\scripts\install_translations.ps1 -Action install -AutoOnly -Validate -Force -BackupExisting
```

- Установка выбранных модов:
```
powershell -ExecutionPolicy Bypass -File .\scripts\install_translations.ps1 -Action install -Mods vro vro_assets
```

- Удаление всех модов, установленных инсталлятором (по манифесту):
```
powershell -ExecutionPolicy Bypass -File .\scripts\install_translations.ps1 -Action uninstall
```

- Удаление конкретных модов:
```
powershell -ExecutionPolicy Bypass -File .\scripts\install_translations.ps1 -Action uninstall -Mods vro vro_assets
```

- Сухой прогон (без изменений):
```
powershell -ExecutionPolicy Bypass -File .\scripts\install_translations.ps1 -Action install -DryRun
```

Примечания:
- Для записи в Program Files может потребоваться запуск PowerShell от имени администратора.
- Инсталлятор ставит маркер `.installed_by_forx4_translation` в папку мода и ведёт манифест `.forx4translation_manifest.json` в папке `extensions` игры.

Поддерживаемые параметры инсталлятора:
- `-Mods <имена>` — список каталогов модов.
- `-Force` — перезаписывать существующие каталоги в игре.
- `-BackupExisting` — сохранять бэкап перезаписываемого мода в `_backup_forx4translation`.
- `-AutoOnly` — устанавливать только моды с `ru_auto="1"`.
- `-Validate` — проверять корректность `content.xml` перед установкой.
- `-DryRun` — только показать действия.
- `-LogPath <файл>` — писать лог операций.

## Утилиты
- `ru_translation/fix_english_content.py` — исправляет `content.xml` в модах: переносит корректные RU-имя/описание, убирает плейсхолдеры `ReadText` и числовые заглушки.
- `ru_translation/check_translation_completeness.py` — проверка полноты перевода по всем модам.
- `ru_translation/scan_readtext.py` — поиск любых вхождений `ReadText` в `*.xml`.
- `ru_translation/sync_t_files.py` — синхронизация `0001-l007.xml` (RU) с источником `0001-l033.xml`/`0001.xml` (EN) для модов KUDA/kuertee и др. Заполняет недостающие ID, чтобы избежать `ReadText` в UI.

## Кастомизация описаний
Файл `ru_translation/terms_config.json` позволяет:
- задавать неизменяемые термины (`immutable_terms`),
- указывать запрещённые паттерны (`forbidden_patterns`),
- добавлять кастомные имена/описания для конкретных модов (`custom_names`, `custom_descriptions`),
- ограничивать длину описаний (`desc_min_len`, `desc_max_len`).

Основной автопереводчик: `ru_translation/mass_translate.py`.
Полезные флаги:
- `--mods` — обработать только указанные моды.
- `--only-missing` — трогать только те, где RU отсутствует/плейсхолдер/с метками.
- `--force` — перезаписывать даже если RU уже корректен.
- `--backup` — создавать бэкап `content.xml` при записи.
- `--dry-run` — показать изменения без записи.
- `--no-mark` — не проставлять `ru_auto="1"`.
- `--cleanup-only` — удалить метки `[ТРЕБУЕТ ПЕРЕВОД]` из существующих RU-полей без генерации текста.

## Типичные проблемы и решения
- `ReadText…` в UI: запустите `sync_t_files.py` для целевых модов (KUDA/kuertee и т.п.). Проверьте, что `page id` в `*-l007.xml` совпадает с источником (пример: `kuertee_ui_extensions/t/0001-l007.xml` должен иметь `page id="101475"`).
- Английские описания/заглушки в `content.xml`: запустите `fix_english_content.py` — он подставит корректные RU значения или очистит плейсхолдеры.

## Лицензия
Только для локализации и совместимости. Уважайте лицензии авторов модов.
