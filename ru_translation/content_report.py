from pathlib import Path
import re
import xml.etree.ElementTree as ET
from typing import Optional

REPO_ROOT = Path(__file__).resolve().parents[1]
EXT_DIR = REPO_ROOT / 'extensions'

README_PATTERNS = (
    'readme.txt', 'README.txt', 'ReadMe.txt',
    'readme.md', 'README.md', 'ReadMe.md',
    'description.txt', 'DESCRIPTION.txt',
    'about.txt', 'About.txt', 'ABOUT.txt',
    'changelog.txt', 'CHANGELOG.txt',
)

PLACEHOLDER_RE = re.compile(r"^(?:readtext|\d{3,}(?:[-.]\d{2,})?)", re.IGNORECASE)


def is_placeholder(text: Optional[str]) -> bool:
    if text is None:
        return True
    t = text.strip()
    if not t:
        return True
    t = t.strip('=<>[](){}"\'\u00A0')
    tl = t.lower().strip()
    if 'readtext' in tl:
        return True
    if t.isdigit() and len(t) >= 3:
        return True
    if t.replace('-', '').replace('.', '').isdigit() and len(t.replace('-', '').replace('.', '')) >= 3:
        return True
    return False


def first_paragraph(text: str) -> str:
    # Возьмём первые 600 символов первого абзаца
    parts = re.split(r"\n\s*\n+", text.strip(), maxsplit=1)
    para = parts[0]
    return (para[:600] + ('…' if len(para) > 600 else ''))


def find_readme(mod_path: Path) -> Optional[str]:
    # Ищем в корне мода или common подпапках
    candidates = []
    # Корень
    for pat in README_PATTERNS:
        p = mod_path / pat
        if p.exists():
            candidates.append(p)
    # Частые подпапки
    for sub in ('docs', 'Doc', 'Documentation', 'doc'):
        sp = mod_path / sub
        if sp.is_dir():
            for pat in README_PATTERNS:
                p = sp / pat
                if p.exists():
                    candidates.append(p)
    if not candidates:
        return None
    # Берём самый короткий путь (обычно корневой README)
    candidates.sort(key=lambda p: len(p.parts))
    try:
        content = candidates[0].read_text(encoding='utf-8', errors='ignore')
        return first_paragraph(content)
    except Exception:
        return None


def parse_content_xml(path: Path):
    try:
        tree = ET.parse(path)
        root = tree.getroot()
    except Exception:
        return None, None
    # поддержка структур content.xml от модов X4
    name_ru = None
    name_en = None
    descr_ru = None
    descr_en = None

    # Частые узлы: content/@name, content/@description, или вложенные <name lang="ru">, <description lang="ru">
    content = root.find('.//content')
    if content is not None:
        # атрибуты
        name_ru = content.get('name_ru') or content.get('name-ru') or content.get('name_ruRU')
        descr_ru = content.get('description_ru') or content.get('description-ru') or content.get('description_ruRU')
        name_en = content.get('name_en') or content.get('name-en') or content.get('name')
        descr_en = content.get('description_en') or content.get('description-en') or content.get('description')
        # вложенные
        for node in ('name', 'description'):
            for child in content.findall(node):
                lang = (child.get('lang') or child.get('language') or '').lower()
                val = (child.text or '').strip()
                if node == 'name':
                    if lang in ('ru', 'ru-ru', 'l007') and not name_ru:
                        name_ru = val
                    if lang in ('en', 'en-us', 'l033') and not name_en:
                        name_en = val
                else:
                    if lang in ('ru', 'ru-ru', 'l007') and not descr_ru:
                        descr_ru = val
                    if lang in ('en', 'en-us', 'l033') and not descr_en:
                        descr_en = val
    else:
        # fallback: поиск любых name/description
        n = root.find('.//name')
        d = root.find('.//description')
        name_ru = (n.text or '').strip() if n is not None else None
        descr_ru = (d.text or '').strip() if d is not None else None

    return (name_ru, name_en, descr_ru, descr_en)


def main():
    print('Отчёт по описаниям модов (content.xml):')
    print('Показываем модули, где есть проблема с RU-описанием или есть возможность дополнить его.')
    print('—\n')

    total = 0
    issues = 0
    for mod in sorted(p for p in EXT_DIR.iterdir() if p.is_dir()):
        cxml = mod / 'content.xml'
        if not cxml.exists():
            continue
        total += 1
        name_ru, name_en, descr_ru, descr_en = parse_content_xml(cxml)

        ru_missing = is_placeholder(descr_ru)
        ru_equals_en = bool(descr_ru and descr_en and descr_ru.strip() == descr_en.strip())
        needs_improve = ru_missing or ru_equals_en

        if needs_improve:
            issues += 1
            print(f'❗ {mod.name}')
            if ru_missing:
                print('  - RU описание: отсутствует/плейсхолдер')
            if ru_equals_en:
                print('  - RU описание совпадает с EN (возможно не переведено)')
            if descr_en and len(descr_en.strip()) > 0:
                print('  - EN описание (фрагмент):')
                print('    ', first_paragraph(descr_en.replace('\n', ' ')))
            readme = find_readme(mod)
            if readme:
                print('  - README/описание (фрагмент для дополнения):')
                for line in first_paragraph(readme).split('\n'):
                    print('    ', line.strip())
            print()

    print('—\nИтог: модов с потенциальной проблемой описания:', issues, 'из', total)
    print('Совет: переведите и при необходимости дополните RU-описание в', 'content.xml', 'на основе EN/README.')


if __name__ == '__main__':
    main()
