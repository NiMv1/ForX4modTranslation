import re
import html
import sys
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError
import xml.etree.ElementTree as ET
import shutil

REPO_ROOT = Path(__file__).resolve().parents[1]
ext_dir = REPO_ROOT / 'extensions'
MARKER = '[ТРЕБУЕТ ПЕРЕВОД] '
MARKER_NET = '[ТРЕБУЕТ ПЕРЕВОД] Описание (EN): '


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


def find_candidate_urls(mod_dir: Path, max_depth: int = 2) -> list[str]:
    urls = []
    candidates = []
    names = (
        'README.md','ReadMe.md','README.txt','readme.md','readme.txt',
        'about.txt','About.txt','DESCRIPTION.txt','description.txt'
    )
    # collect candidate files up to depth
    roots = [mod_dir]
    for sub in ('docs', 'documentation', 'readme', 'wiki'):
        p = mod_dir / sub
        if p.exists() and p.is_dir():
            roots.append(p)
    visited = set()
    def walk(dir_path: Path, depth: int):
        if depth > max_depth:
            return
        for p in dir_path.iterdir():
            if p.is_dir():
                walk(p, depth + 1)
            else:
                if p.name in names:
                    candidates.append(p)
                elif p.name.lower() == 'content.xml':
                    candidates.append(p)
    for r in roots:
        if r.exists() and r not in visited:
            visited.add(r)
            walk(r, 0)
    for fp in candidates:
        urls += re.findall(r'https?:\/\/\S+', read_text(fp))
    # dedupe and simple filter
    clean = []
    for u in urls:
        u = u.strip().rstrip(').,;"\'')
        if u not in clean and (u.startswith('http://') or u.startswith('https://')):
            clean.append(u)
    return clean[:10]


def find_local_readme_snippet(mod_dir: Path) -> str:
    # search recursively similar to URLs
    for depth in range(0, 3):
        for sub in (Path('.'), Path('docs'), Path('documentation'), Path('readme'), Path('wiki')):
            base = (mod_dir / sub)
            if not base.exists() or not base.is_dir():
                continue
            for p in base.rglob('*'):
                try:
                    if p.is_file() and p.suffix.lower() in ('.md', '.txt'):
                        txt = read_text(p)
                        if not txt:
                            continue
                        # prefer english sections, strip markdown
                        txt = re.sub(r'<[^>]+>', ' ', txt)
                        txt = re.sub(r'[\t ]+', ' ', txt)
                        txt = re.sub(r'[#*_>`]+', ' ', txt)
                        para = first_paragraph(txt, limit=700)
                        if para:
                            return para
                except Exception:
                    continue
    return ''


def fetch_url(url: str) -> str:
    try:
        req = Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (X4 RU Localizer)'
        })
        with urlopen(req, timeout=10) as resp:
            charset = resp.headers.get_content_charset() or 'utf-8'
            data = resp.read()
            return data.decode(charset, errors='ignore')
    except (HTTPError, URLError, TimeoutError, Exception):
        return ''


def strip_html_keep_paragraphs(html_text: str) -> str:
    # convert <br> to newlines
    text = re.sub(r'<\s*br\s*/?>', '\n', html_text, flags=re.I)
    # replace block tags with double newline
    text = re.sub(r'</\s*(p|div|h\d|li|ul|ol)\s*>', '\n\n', text, flags=re.I)
    # strip tags
    text = re.sub(r'<[^>]+>', '', text)
    # unescape
    text = html.unescape(text)
    # normalize spaces
    text = re.sub(r'\r', '', text)
    text = re.sub(r'\n\s*\n+', '\n\n', text)
    return text.strip()


def extract_snippet(url: str, html_text: str) -> str:
    u = urlparse(url)
    host = (u.netloc or '').lower()
    # Try meta description
    m = re.search(r'<meta\s+name=["\']description["\']\s+content=["\']([^"\']+)["\']', html_text, flags=re.I)
    if m:
        return m.group(1).strip()
    # GitHub README rendering
    if 'github.com' in host:
        # try README content area
        art = re.search(r'<article[^>]*>([\s\S]+?)</article>', html_text, flags=re.I)
        if art:
            return first_paragraph(strip_html_keep_paragraphs(art.group(1)))
    # NexusMods generic (best-effort; may be blocked)
    if 'nexusmods.com' in host:
        desc = re.search(r'id=["\']description["\'][^>]*>([\s\S]+?)</div>', html_text, flags=re.I)
        if desc:
            return first_paragraph(strip_html_keep_paragraphs(desc.group(1)))
    # fallback: first paragraph from page text
    return first_paragraph(strip_html_keep_paragraphs(html_text))


def first_paragraph(text: str) -> str:
    parts = [p.strip() for p in re.split(r'\n\s*\n+', text) if p.strip()]
    if not parts:
        return ''
    # limit length
    return parts[0][:700]


def ensure_ru_text_node(content_node: ET.Element) -> ET.Element:
    ru_text_node = content_node.find('.//text[@language="7"]')
    if ru_text_node is None:
        ru_text_node = ET.Element('text')
        ru_text_node.set('language', '7')
        content_node.append(ru_text_node)
    return ru_text_node


def update_content_xml(mod_dir: Path, snippet: str) -> bool:
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

    # current values
    ru_name = (content.get('name') or '').strip()
    ru_desc = (content.get('description') or '').strip()
    # prefer text node values
    t_ru = content.find('.//text[@language="7"]')
    if t_ru is not None:
        ru_name = (t_ru.get('name') or ru_name).strip()
        ru_desc = (t_ru.get('description') or ru_desc).strip()

    changed = False
    if not ru_desc or is_placeholder(ru_desc):
        # compose annotated RU description from EN snippet
        composed = f"{MARKER_NET}{snippet}".strip()
        # set attrs
        if (not is_placeholder(composed)) and composed != ru_desc:
            content.set('description', composed)
            changed = True
        # set text node
        tnode = ensure_ru_text_node(content)
        cur = (tnode.get('description') or '').strip()
        if (not is_placeholder(composed)) and composed != cur:
            tnode.set('description', composed)
            changed = True
    
    if changed:
        # write back with backup (non-destructive)
        bak = cx.with_suffix('.xml.bak')
        try:
            if not bak.exists() and cx.exists():
                shutil.copy2(cx, bak)
        except Exception:
            pass
        tree.write(cx, encoding='utf-8', xml_declaration=True)
    return changed


def process_mod(mod_dir: Path) -> bool:
    urls = find_candidate_urls(mod_dir)
    for u in urls:
        html_text = fetch_url(u)
        if not html_text:
            continue
        snip = extract_snippet(u, html_text)
        if snip and update_content_xml(mod_dir, snip):
            return True
    # fallback: use local README snippet if any
    local_snip = find_local_readme_snippet(mod_dir)
    if local_snip:
        if update_content_xml(mod_dir, local_snip):
            return True
    return False


def main() -> int:
    if not ext_dir.exists():
        print('extensions/ not found')
        return 1
    total = 0
    changed = 0
    for mod in sorted(p for p in ext_dir.iterdir() if p.is_dir()):
        total += 1
        try:
            if process_mod(mod):
                changed += 1
                print(f"✔ Обновлено описание из интернета: {mod.name}")
        except Exception as e:
            print(f"! Ошибка {mod.name}: {e}")
    print(f"Готово: обновлено {changed} из {total}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
