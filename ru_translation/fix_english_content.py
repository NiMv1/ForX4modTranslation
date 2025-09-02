import os
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
    # убрать обрамляющие пустышки
    t = t.strip('=<>[](){}"\'\u00A0')
    tl = t.lower().strip()
    # любые формы ReadText
    if tl.startswith('readtext') or 'readtext' in tl:
        return True
    # только цифры или цифро-коды с дефисами
    if t.isdigit() and len(t) >= 3:
        return True
    if t.replace('-', '').isdigit() and len(t.replace('-', '')) >= 3:
        return True
    return False


def extract_text_by_language(root: ET.Element, lang: str) -> tuple[str, str]:
    node = root.find(f'.//text[@language="{lang}"]')
    if node is None:
        return '', ''
    name = (node.get('name') or '').strip()
    desc = (node.get('description') or '').strip()
    if is_placeholder(name):
        name = ''
    if is_placeholder(desc):
        desc = ''
    return name, desc


def fix_content_xml(content_xml_path: Path, mod_name: str) -> bool:
    try:
        tree = ET.parse(content_xml_path)
        root = tree.getroot()
    except Exception:
        return False

    # приоритет RU (7), затем EN (44/33/49)
    ru_name, ru_desc = extract_text_by_language(root, '7')
    en_name, en_desc = '', ''
    if not ru_name or not ru_desc:
        for fallback in ('44', '33', '49'):
            en_name, en_desc = extract_text_by_language(root, fallback)
            if (not ru_name) and en_name:
                ru_name = en_name
            if (not ru_desc) and en_desc:
                ru_desc = en_desc
            if ru_name and ru_desc:
                break

    # если RU формируется из EN или сомнителен — помечаем как требующий перевода
    def needs_marker(ru_val: str, en_val: str) -> bool:
        if not ru_val:
            return False
        if not en_val:
            return False
        return ru_val.strip() == en_val.strip()

    marker = '[ТРЕБУЕТ ПЕРЕВОД] '
    # Проставим метку, если RU отсутствовал и был взят из EN, либо совпадает с EN
    if ru_name and en_name and needs_marker(ru_name, en_name) and not ru_name.startswith(marker):
        ru_name = marker + ru_name
    if ru_desc and en_desc and needs_marker(ru_desc, en_desc) and not ru_desc.startswith(marker):
        ru_desc = marker + ru_desc

    changed = False
    # целевые атрибуты в <content>
    if root.tag == 'content':
        cur_name = (root.get('name') or '').strip()
        cur_desc = (root.get('description') or '').strip()
        if (ru_name and not is_placeholder(ru_name)) and (cur_name != ru_name):
            root.set('name', ru_name)
            changed = True
        if (ru_desc and not is_placeholder(ru_desc)) and (cur_desc != ru_desc):
            root.set('description', ru_desc)
            changed = True
    else:
        # иногда content вложен (на всякий случай)
        node = root.find('.//content')
        if node is not None:
            cur_name = (node.get('name') or '').strip()
            cur_desc = (node.get('description') or '').strip()
            if (ru_name and not is_placeholder(ru_name)) and (cur_name != ru_name):
                node.set('name', ru_name)
                changed = True
            if (ru_desc and not is_placeholder(ru_desc)) and (cur_desc != ru_desc):
                node.set('description', ru_desc)
                changed = True

    # Обеспечить наличие и заполнение <text language="7">
    def get_content_node(rt: ET.Element) -> ET.Element | None:
        if rt.tag == 'content':
            return rt
        return rt.find('.//content')

    content_node = get_content_node(root)
    if content_node is not None:
        ru_text_node = content_node.find('.//text[@language="7"]')
        if ru_text_node is None:
            # создаём RU-узел
            ru_text_node = ET.Element('text')
            ru_text_node.set('language', '7')
            content_node.append(ru_text_node)
            changed = True

        cur_t_name = (ru_text_node.get('name') or '').strip()
        cur_t_desc = (ru_text_node.get('description') or '').strip()

        # При необходимости дублируем значение из атрибутов content
        if ru_name and cur_t_name != ru_name:
            ru_text_node.set('name', ru_name)
            changed = True
        if ru_desc and cur_t_desc != ru_desc:
            ru_text_node.set('description', ru_desc)
            changed = True

    if changed:
        bak = content_xml_path.with_suffix(content_xml_path.suffix + '.bak_fix')
        try:
            bak.write_text(content_xml_path.read_text(encoding='utf-8', errors='ignore'), encoding='utf-8')
        except Exception:
            pass
        tree.write(content_xml_path, encoding='utf-8')
    return changed


def main():
    print('Исправляю content.xml в модах...')
    total = 0
    changed = 0
    for mod in sorted([p for p in EXT_DIR.iterdir() if p.is_dir()]):
        cxml = mod / 'content.xml'
        if not cxml.exists():
            continue
        total += 1
        if fix_content_xml(cxml, mod.name):
            print(f"  ✔ {mod.name} — исправлено")
            changed += 1
        else:
            print(f"  • {mod.name} — ок / без изменений")
    print('\nИтог: обработано:', total, 'исправлено:', changed)


if __name__ == '__main__':
    main()
