import re
from pathlib import Path
import xml.etree.ElementTree as ET
from typing import Dict, Set, Tuple

REPO_ROOT = Path(__file__).resolve().parents[1]
ext_dir = REPO_ROOT / 'extensions'

READTEXT_RE = re.compile(r"readtext\s*\.?\{?(\d+)\}?\.?\{?(\d+)\}?", re.IGNORECASE)


def parse_t_file(path: Path) -> Tuple[str | None, Dict[int, str]]:
    try:
        tree = ET.parse(path)
        root = tree.getroot()
    except Exception:
        return None, {}
    page = None
    if root.tag == 'language':
        page = root.find('page')
    else:
        page = root.find('.//page')
    if page is None:
        return None, {}
    page_id = page.get('id')
    entries: Dict[int, str] = {}
    for t in page.findall('t'):
        tid = t.get('id')
        if not tid:
            continue
        try:
            tid_i = int(tid)
        except ValueError:
            continue
        entries[tid_i] = (t.text or '').strip()
    return page_id, entries


def scan_mod_for_readtext(mod_path: Path) -> Dict[str, Set[int]]:
    required: Dict[str, Set[int]] = {}
    for xml in mod_path.rglob('*.xml'):
        try:
            text = xml.read_text(encoding='utf-8', errors='ignore')
        except Exception:
            continue
        for m in READTEXT_RE.finditer(text):
            page, tid = m.group(1), m.group(2)
            required.setdefault(page, set()).add(int(tid))
    return required


def validate_mod_t(mod_path: Path) -> Tuple[bool, str]:
    t_dir = mod_path / 't'
    if not t_dir.exists():
        # мод может не использовать t-файлы — ок
        return True, 'no t/ directory'

    en_path = None
    if (t_dir / '0001-l033.xml').exists():
        en_path = t_dir / '0001-l033.xml'
    elif (t_dir / '0001.xml').exists():
        en_path = t_dir / '0001.xml'

    ru_path = t_dir / '0001-l007.xml'

    # Базовые проверки наличия файлов
    if not en_path and not ru_path.exists():
        return False, 'missing both EN (0001-l033.xml/0001.xml) and RU (0001-l007.xml)'
    if en_path and not ru_path.exists():
        return False, 'missing RU 0001-l007.xml'

    # Парсим RU для получения page id и доступных ID
    page_ru, ru_entries = parse_t_file(ru_path) if ru_path.exists() else (None, {})

    # Если есть EN — сверяем page id
    if en_path:
        page_en, _ = parse_t_file(en_path)
        if page_en and page_ru and page_en != page_ru:
            return False, f'page id mismatch RU({page_ru}) vs EN({page_en})'

    # Сканируем используемые readtext
    required = scan_mod_for_readtext(mod_path)
    # Проверяем покрытие по странице RU
    problems: list[str] = []
    if page_ru and page_ru in required:
        missing = [tid for tid in sorted(required[page_ru]) if tid not in ru_entries or not ru_entries[tid].strip()]
        if missing:
            problems.append(f'missing RU ids for page {page_ru}: {", ".join(map(str, missing[:50]))}{" ..." if len(missing)>50 else ""}')
    # Если мод ссылается на страницы других модов/игры — пропускаем

    if problems:
        return False, ' | '.join(problems)
    return True, 'ok'


def main():
    print('Валидация t-файлов (наличие RU, корректный page id, покрытие используемых ReadText)...')
    total = 0
    ok_count = 0
    for mod in sorted(p for p in ext_dir.iterdir() if p.is_dir()):
        total += 1
        ok, msg = validate_mod_t(mod)
        status = '✅' if ok else '❌'
        print(f'{status} {mod.name} - {msg}')
        if ok:
            ok_count += 1
    print('\nИтог:', ok_count, '/', total, 'модов без проблем')


if __name__ == '__main__':
    main()
