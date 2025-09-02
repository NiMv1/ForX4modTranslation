import re
from pathlib import Path
import xml.etree.ElementTree as ET
import html

REPO_ROOT = Path(__file__).resolve().parents[1]
ext_dir = REPO_ROOT / 'extensions'
MARKER = '[ТРЕБУЕТ ПЕРЕВОД] '
MARKER_GEN = '[ТРЕБУЕТ ПЕРЕВОД] Краткое описание: '


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


def read_text(p: Path) -> str:
    try:
        return p.read_text(encoding='utf-8', errors='ignore')
    except Exception:
        return ''


def first_paragraph(text: str, limit=400) -> str:
    text = text.replace('\r', '')
    parts = [p.strip() for p in re.split(r'\n\s*\n+', text) if p.strip()]
    if not parts:
        return ''
    return parts[0][:limit]


KEYMAP = [
    (re.compile(r'\b(ui|hud|menu|interface)\b', re.I), 'улучшает интерфейс и элементы HUD'),
    (re.compile(r'\b(dock|docking|carrier)\b', re.I), 'добавляет/улучшает механику стыковки и поведения кораблей'),
    (re.compile(r'\btrade|trader|econom(y|ic)|market\b', re.I), 'расширяет торговые инструменты и аналитику рынка'),
    (re.compile(r'\bscan|scanner|long range\b', re.I), 'модифицирует сканирование и обнаружение объектов'),
    (re.compile(r'\bfleet|carrier|command(er)?\b', re.I), 'упрощает управление флотом и подчинёнными'),
    (re.compile(r'\bpaint|skin|color\b', re.I), 'добавляет варианты окраски и визуальные изменения'),
    (re.compile(r'\bweapon|gun|sound\b', re.I), 'меняет характеристики/звуки вооружения'),
]


def synthesize_ru(mod_name: str, name_en: str, snippet_en: str) -> str:
    base = f"{mod_name}".strip('_- ')
    base = base.replace('_', ' ').replace('-', ' ').strip()
    text_src = ' '.join(filter(None, [name_en, snippet_en]))
    hints = []
    for rx, ru in KEYMAP:
        if rx.search(text_src):
            hints.append(ru)
    hints = list(dict.fromkeys(hints))  # dedupe keep order
    if hints:
        desc = f"Мод {base} {', '.join(hints)}."
    else:
        desc = f"Мод {base} расширяет возможности игры и добавляет улучшения геймплея."
    if snippet_en:
        desc += f"\nEN: {first_paragraph(snippet_en, limit=350)}"
    return f"{MARKER_GEN}{desc}"[:900]


def ensure_ru_text_node(content_node: ET.Element) -> ET.Element:
    ru_text_node = content_node.find('.//text[@language="7"]')
    if ru_text_node is None:
        ru_text_node = ET.Element('text')
        ru_text_node.set('language', '7')
        content_node.append(ru_text_node)
    return ru_text_node


def extract_text_by_language(content_node: ET.Element, lang: str) -> tuple[str, str]:
    node = content_node.find(f'.//text[@language="{lang}"]')
    if node is None:
        return '', ''
    return (node.get('name') or '').strip(), (node.get('description') or '').strip()


def process_mod(mod_dir: Path) -> bool:
    cx = mod_dir / 'content.xml'
    if not cx.exists():
        return False
    try:
        tree = ET.parse(cx)
        root = tree.getroot()
    except Exception:
        return False
    content = root if root.tag == 'content' else root.find('.//content')
    if content is None:
        return False

    # gather current
    ru_name, ru_desc = extract_text_by_language(content, '7')
    if (not ru_name):
        ru_name = (content.get('name') or '').strip()
    if (not ru_desc):
        ru_desc = (content.get('description') or '').strip()

    # skip if already has non-placeholder RU description
    if ru_desc and not is_placeholder(ru_desc) and not ru_desc.lower().startswith(MARKER.strip().lower()):
        return False

    # collect local README snippet
    snippet = ''
    for nm in (
        'README.md','ReadMe.md','README.txt','readme.md','readme.txt',
        'about.txt','About.txt','DESCRIPTION.txt','description.txt'
    ):
        p = mod_dir / nm
        if p.exists():
            txt = read_text(p)
            # strip md/html tags roughly
            txt = re.sub(r'<[^>]+>', ' ', txt)
            txt = re.sub(r'[#*_>`]+', ' ', txt)
            snippet = first_paragraph(txt, limit=500)
            if snippet:
                break

    # pull some EN text as context
    name_en = (content.get('name') or '').strip()
    if not name_en:
        en_name, en_desc = '', ''
        for fallback in ('44','33','49'):
            en_name, en_desc = extract_text_by_language(content, fallback)
            if en_name or en_desc:
                name_en = en_name
                if not snippet:
                    snippet = en_desc
                break

    gen = synthesize_ru(mod_dir.name, name_en, snippet)

    changed = False
    if gen and (not ru_desc or is_placeholder(ru_desc) or ru_desc.startswith(MARKER)):
        # write into attributes and text node
        if (content.get('description') or '').strip() != gen:
            content.set('description', gen)
            changed = True
        tnode = ensure_ru_text_node(content)
        if (tnode.get('description') or '').strip() != gen:
            tnode.set('description', gen)
            changed = True
    if changed:
        tree.write(cx, encoding='utf-8', xml_declaration=True)
    return changed


def main():
    total = 0
    changed = 0
    for mod in sorted(p for p in ext_dir.iterdir() if p.is_dir()):
        total += 1
        try:
            if process_mod(mod):
                changed += 1
                print(f"✔ Сгенерировано RU-описание: {mod.name}")
        except Exception as e:
            print(f"! Ошибка {mod.name}: {e}")
    print(f"Готово: сгенерировано {changed} из {total}")


if __name__ == '__main__':
    main()
