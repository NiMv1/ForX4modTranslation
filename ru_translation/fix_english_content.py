import os
from pathlib import Path
import xml.etree.ElementTree as ET
import re

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
    # кандидаты EN из text-узлов
    en_candidates = []
    for fallback in ('44', '33', '49'):
        en_n, en_d = extract_text_by_language(root, fallback)
        if en_n:
            en_candidates.append(('text', 'name', en_n))
        if en_d:
            en_candidates.append(('text', 'desc', en_d))

    # кандидаты EN из атрибутов <content>
    def get_content_node(rt: ET.Element) -> ET.Element | None:
        if rt.tag == 'content':
            return rt
        return rt.find('.//content')

    content_node = get_content_node(root)
    if content_node is not None:
        c_en_name = (content_node.get('name') or '').strip()
        c_en_desc = (content_node.get('description') or '').strip()
        if c_en_name and not is_placeholder(c_en_name):
            en_candidates.append(('attr', 'name', c_en_name))
        if c_en_desc and not is_placeholder(c_en_desc):
            en_candidates.append(('attr', 'desc', c_en_desc))

    # кандидаты из README (первый абзац как описание)
    def find_readme_text(mod_dir: Path) -> str:
        names = (
            'readme.md','README.md','ReadMe.md','readme.txt','README.txt','ReadMe.txt',
            'description.txt','DESCRIPTION.txt','about.txt','About.txt','ABOUT.txt'
        )
        for nm in names:
            p = mod_dir / nm
            if p.exists():
                try:
                    txt = p.read_text(encoding='utf-8', errors='ignore')
                    # первый абзац (до пустой строки) или до 600 символов
                    parts = re.split(r"\n\s*\n+", txt.strip(), maxsplit=1)
                    para = parts[0].strip()
                    return para[:600]
                except Exception:
                    continue
        return ''

    readme_desc = find_readme_text(content_xml_path.parent)
    if readme_desc:
        en_candidates.append(('readme', 'desc', readme_desc))

    marker = '[ТРЕБУЕТ ПЕРЕВОД] '

    # Если RU отсутствует или является плейсхолдером — заполняем EN/README и помечаем
    if (not ru_name) or is_placeholder(ru_name):
        for src, kind, val in en_candidates:
            if kind == 'name' and val and not is_placeholder(val):
                ru_name = (val if val.startswith(marker) else (marker + val))
                break
    if (not ru_desc) or is_placeholder(ru_desc):
        for src, kind, val in en_candidates:
            if kind == 'desc' and val and not is_placeholder(val):
                ru_desc = (val if val.startswith(marker) else (marker + val))
                break

    # Если RU совпал с любым из кандидатов EN — добавим маркер
    def matches_any_en(val: str) -> bool:
        v = (val or '').strip()
        for _, _, e in en_candidates:
            if v and e and v == e.strip():
                return True
        return False
    if ru_name and not ru_name.startswith(marker) and matches_any_en(ru_name):
        ru_name = marker + ru_name
    if ru_desc and not ru_desc.startswith(marker) and matches_any_en(ru_desc):
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
