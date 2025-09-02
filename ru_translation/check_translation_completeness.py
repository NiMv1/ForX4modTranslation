from pathlib import Path
import xml.etree.ElementTree as ET

REPO_ROOT = Path(__file__).resolve().parents[1]
EXT_DIR = REPO_ROOT / 'extensions'


def is_placeholder(text: str) -> bool:
    if text is None:
        return True
    t = text.strip()
    if not t:
        return True
    t = t.strip('=<>[](){}"\'\u00A0')
    tl = t.lower().strip()
    if tl.startswith('readtext') or 'readtext' in tl:
        return True
    if t.isdigit() and len(t) >= 3:
        return True
    if t.replace('-', '').isdigit() and len(t.replace('-', '')) >= 3:
        return True
    return False


def extract_lang_text(root: ET.Element, lang: str) -> tuple[str, str]:
    node = root.find(f'.//text[@language="{lang}"]')
    if node is None:
        return '', ''
    return (node.get('name') or '').strip(), (node.get('description') or '').strip()


def check_content_xml(path: Path) -> tuple[bool, str]:
    try:
        tree = ET.parse(path)
        root = tree.getroot()
    except Exception as e:
        return False, f'XML error: {e}'
    name = (root.get('name') or '').strip() if root.tag == 'content' else (root.find('.//content').get('name') if root.find('.//content') is not None else '')
    desc = (root.get('description') or '').strip() if root.tag == 'content' else (root.find('.//content').get('description') if root.find('.//content') is not None else '')

    ru_name, ru_desc = extract_lang_text(root, '7')
    ok = True
    problems = []

    for label, value in (('name', name), ('description', desc)):
        if is_placeholder(value):
            ok = False
            problems.append(f'{label} is placeholder')
    # Require presence of RU text node with non-placeholder
    if is_placeholder(ru_name) or is_placeholder(ru_desc):
        ok = False
        problems.append('missing/placeholder RU <text language="7">')

    # Метка незавершённого перевода
    marker = '[ТРЕБУЕТ ПЕРЕВОД]'
    if ru_name.startswith(marker) or ru_desc.startswith(marker):
        ok = False
        problems.append('RU marked as [ТРЕБУЕТ ПЕРЕВОД]')

    # Проверка наличия кириллицы в RU-тексте
    def has_cyrillic(s: str) -> bool:
        return any('А' <= ch <= 'я' or ch == 'ё' or ch == 'Ё' for ch in s)

    if (ru_name and not has_cyrillic(ru_name)) or (ru_desc and not has_cyrillic(ru_desc)):
        ok = False
        problems.append('RU <text language="7"> likely not Russian (no Cyrillic)')

    return ok, '; '.join(problems)


def main():
    print('Проверка полноты перевода всех модов...')
    total = 0
    good = 0
    for mod in sorted([p for p in EXT_DIR.iterdir() if p.is_dir()]):
        cxml = mod / 'content.xml'
        if not cxml.exists():
            continue
        total += 1
        ok, msg = check_content_xml(cxml)
        if ok:
            print(f'✅ {mod.name} - перевод полный')
            good += 1
        else:
            print(f'❌ {mod.name} - {msg}')
    print('\n============================================================')
    print('Всего модов проверено:', total)
    print('Модов с полным переводом:', good)
    print('Модов с проблемами:', total - good)


if __name__ == '__main__':
    main()
