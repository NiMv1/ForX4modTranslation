from pathlib import Path
import xml.etree.ElementTree as ET

REPO_ROOT = Path(__file__).resolve().parents[1]
ext_dir = REPO_ROOT / 'extensions'


def mod_is_auto_generated(content_xml: Path) -> bool:
    try:
        tree = ET.parse(content_xml)
        root = tree.getroot()
    except Exception:
        return False
    content = root if root.tag == 'content' else root.find('.//content')
    if content is None:
        return False
    return content.get('ru_auto') == '1'


def main():
    mods = []
    for mod_dir in sorted(p for p in ext_dir.iterdir() if p.is_dir()):
        cx = mod_dir / 'content.xml'
        if not cx.exists():
            continue
        if mod_is_auto_generated(cx):
            mods.append(mod_dir.name)

    print('Отчёт для ручной вычитки автосгенерированных переводов:')
    print('—')
    if not mods:
        print('Нет модов, помеченных автогенерацией.')
    else:
        for m in mods:
            print(f'- {m}')
    print('—')
    print(f'Итого: {len(mods)} мод(ов) с автогенерацией из mass_translate.py')


if __name__ == '__main__':
    main()
