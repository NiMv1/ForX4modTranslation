import re
from pathlib import Path
import xml.etree.ElementTree as ET

REPO_ROOT = Path(__file__).resolve().parents[1]
ext_dir = REPO_ROOT / 'extensions'

# Простая карта переводов для часто встречаемых названий
NAME_MAP = [
    (re.compile(r'\breactive\b', re.I), 'реактивн'),
    (re.compile(r'\bdocking\b', re.I), 'стыковк'),
    (re.compile(r'\bextensions?\b', re.I), 'расширения'),
    (re.compile(r'\bhud\b', re.I), 'HUD'),
    (re.compile(r'\bui\b', re.I), 'интерфейса'),
    (re.compile(r'\bbetter\b', re.I), 'улучшенный'),
    (re.compile(r'\bmonitor\b', re.I), 'монитор'),
    (re.compile(r'\btarget\b', re.I), 'цели'),
    (re.compile(r'\bfleet\b', re.I), 'флота'),
    (re.compile(r'\bmanagement\b', re.I), 'управление'),
    (re.compile(r'\bskip\b', re.I), 'пропуск'),
    (re.compile(r'\bintro\b', re.I), 'заставки'),
    (re.compile(r'\blong\b', re.I), 'дальнего'),
    (re.compile(r'\brange\b', re.I), 'радиуса'),
    (re.compile(r'\bscan\b', re.I), 'сканирования'),
    (re.compile(r'\bpaint|color|colour\b', re.I), 'окраски'),
]

DESC_HINTS = [
    (re.compile(r'\b(ui|hud|menu|interface)\b', re.I), 'улучшает интерфейс и элементы HUD'),
    (re.compile(r'\bdock|docking|carrier\b', re.I), 'добавляет/улучшает механику стыковки и поведения кораблей'),
    (re.compile(r'\btrade|trader|econom(y|ic)|market\b', re.I), 'расширяет торговые инструменты и аналитику рынка'),
    (re.compile(r'\bscan|scanner|long range\b', re.I), 'модифицирует сканирование и обнаружение объектов'),
    (re.compile(r'\bfleet|carrier|command(er)?\b', re.I), 'упрощает управление флотом и подчинёнными'),
    (re.compile(r'\bpaint|skin|color\b', re.I), 'добавляет варианты окраски и визуальные изменения'),
    (re.compile(r'\bweapon|gun|sound\b', re.I), 'меняет характеристики/звуки вооружения'),
]

MARKER = '[ТРЕБУЕТ ПЕРЕВОД]'


def is_placeholder(text: str) -> bool:
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


def has_cyrillic(s: str) -> bool:
    return any('А' <= ch <= 'я' or ch in ('ё','Ё') for ch in s)


def read_text(p: Path) -> str:
    try:
        return p.read_text(encoding='utf-8', errors='ignore')
    except Exception:
        return ''


def first_paragraph(text: str, limit=300) -> str:
    text = text.replace('\r', '')
    parts = [p.strip() for p in re.split(r'\n\s*\n+', text) if p.strip()]
    if not parts:
        return ''
    return parts[0][:limit]


def collect_en(content: ET.Element) -> tuple[str, str]:
    name_en = (content.get('name') or '').strip()
    desc_en = (content.get('description') or '').strip()
    if not name_en or not desc_en:
        for l in ('44','33','49'):
            t = content.find(f'.//text[@language="{l}"]')
            if t is not None:
                if not name_en:
                    name_en = (t.get('name') or '').strip()
                if not desc_en:
                    desc_en = (t.get('description') or '').strip()
                if name_en or desc_en:
                    break
    return name_en, desc_en


def translate_name(en_name: str, mod_dirname: str) -> str:
    if not en_name:
        base = mod_dirname.replace('_',' ').replace('-', ' ').strip()
    else:
        base = en_name
    tokens = re.split(r'[\s_/.-]+', base)
    rus = []
    for tok in tokens:
        lower = tok.lower()
        replaced = None
        for rx, ru in NAME_MAP:
            if rx.search(lower):
                # подставим основу и приведём контекст
                if ru.endswith('н') and lower == 'reactive':
                    replaced = 'реактивная'
                    break
                if lower == 'docking':
                    replaced = 'стыковка'
                    break
                replaced = ru
                break
        rus.append(replaced if replaced else tok)
    name = ' '.join(rus).strip()
    # Нормализация регистра
    name = name[:1].upper() + name[1:]
    # Если не появилось кириллицы, добавим пояснение "(мод)"
    if not has_cyrillic(name):
        name = f"Мод {mod_dirname.replace('_',' ').strip()}"
    return name[:120]


def synthesize_ru_desc(mod_name: str, en_name: str, en_desc_snippet: str, readme_snip: str) -> str:
    text_src = ' '.join(filter(None, [en_name, en_desc_snippet, readme_snip]))
    hints = []
    for rx, ru in DESC_HINTS:
        if rx.search(text_src):
            hints.append(ru)
    hints = list(dict.fromkeys(hints))
    base = mod_name.replace('_',' ').strip()
    if hints:
        desc = f"Мод {base} {', '.join(hints)}."
    else:
        desc = f"Мод {base} расширяет возможности игры и добавляет улучшения геймплея."
    return desc[:900]


def ensure_ru_text_node(content_node: ET.Element) -> ET.Element:
    ru_text_node = content_node.find('.//text[@language="7"]')
    if ru_text_node is None:
        ru_text_node = ET.Element('text')
        ru_text_node.set('language', '7')
        content_node.append(ru_text_node)
    return ru_text_node


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

    t_ru = content.find('.//text[@language="7"]')
    name_ru_curr = (t_ru.get('name') if t_ru is not None else '') or content.get('name') or ''
    desc_ru_curr = (t_ru.get('description') if t_ru is not None else '') or content.get('description') or ''

    # Если уже есть нормальный RU без метки — пропускаем
    if name_ru_curr and has_cyrillic(name_ru_curr) and MARKER not in name_ru_curr:
        pass
    if desc_ru_curr and has_cyrillic(desc_ru_curr) and MARKER not in desc_ru_curr and not is_placeholder(desc_ru_curr):
        return False

    # Собираем EN
    en_name, en_desc = collect_en(content)

    # README сниппет (корень + частые подпапки)
    readme_snip = ''
    for sub in ('', 'docs', 'documentation', 'readme', 'wiki'):
        base = mod_dir / sub if sub else mod_dir
        for p in (base.glob('*.md')):
            readme_snip = first_paragraph(read_text(p), 400)
            if readme_snip:
                break
        if readme_snip:
            break

    # Генерация
    ru_name = translate_name(en_name, mod_dir.name)
    ru_desc = synthesize_ru_desc(mod_dir.name, en_name, en_desc, readme_snip)

    # Запись
    changed = False
    if content.get('name') != ru_name:
        content.set('name', ru_name)
        changed = True
    if content.get('description') != ru_desc:
        content.set('description', ru_desc)
        changed = True
    tnode = ensure_ru_text_node(content)
    if (tnode.get('name') or '') != ru_name:
        tnode.set('name', ru_name)
        changed = True
    if (tnode.get('description') or '') != ru_desc:
        tnode.set('description', ru_desc)
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
                print(f"✔ Переведён: {mod.name}")
        except Exception as e:
            print(f"! Ошибка {mod.name}: {e}")
    print(f"Готово: обновлено {changed} из {total}")


if __name__ == '__main__':
    main()
