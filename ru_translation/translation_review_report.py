from pathlib import Path
import json
import re
import argparse
import csv
from datetime import datetime
import xml.etree.ElementTree as ET

REPO_ROOT = Path(__file__).resolve().parents[1]
ext_dir = REPO_ROOT / 'extensions'
CONFIG_PATH = REPO_ROOT / 'ru_translation' / 'terms_config.json'
OUT_DIR = REPO_ROOT / 'ru_translation' / 'out'


def has_cyrillic(s: str) -> bool:
    return any('А' <= ch <= 'я' or ch in ('ё', 'Ё') for ch in (s or ''))


def load_limits():
    cfg = {'desc_min_len': 40, 'desc_max_len': 900}
    if CONFIG_PATH.exists():
        try:
            data = json.loads(CONFIG_PATH.read_text(encoding='utf-8'))
            for k in ('desc_min_len', 'desc_max_len'):
                if k in data:
                    cfg[k] = int(data[k])
        except Exception:
            pass
    return cfg['desc_min_len'], cfg['desc_max_len']


def parse_content(content_xml: Path):
    try:
        tree = ET.parse(content_xml)
        root = tree.getroot()
    except Exception:
        return None, None
    content = root if root.tag == 'content' else root.find('.//content')
    return content, root


def mod_is_auto_generated(content) -> bool:
    return content is not None and content.get('ru_auto') == '1'


def gather_quality_flags(content) -> list[str]:
    flags = []
    if content is None:
        return ['no <content> node']
    t_ru = content.find('.//text[@language="7"]')
    name_attr = (content.get('name') or '')
    desc_attr = (content.get('description') or '')
    name_node = (t_ru.get('name') if t_ru is not None else '') or ''
    desc_node = (t_ru.get('description') if t_ru is not None else '') or ''

    # рассинхрон
    if name_attr and name_node and name_attr != name_node:
        flags.append('name_desync')
    if desc_attr and desc_node and desc_attr != desc_node:
        flags.append('desc_desync')

    # длина
    dmin, dmax = load_limits()
    eff_desc = desc_node or desc_attr
    if eff_desc:
        if len(eff_desc) < dmin:
            flags.append('desc_too_short')
        if len(eff_desc) > dmax:
            flags.append('desc_too_long')

    # кириллица
    eff_name = name_node or name_attr
    if eff_name and not has_cyrillic(eff_name):
        flags.append('name_no_cyrillic')
    if eff_desc and not has_cyrillic(eff_desc):
        flags.append('desc_no_cyrillic')

    # метка
    if '[ТРЕБУЕТ ПЕРЕВОД]' in eff_name or '[ТРЕБУЕТ ПЕРЕВОД]' in eff_desc:
        flags.append('contains_marker')

    # ru_auto
    if content.get('ru_auto') != '1':
        flags.append('ru_auto_missing')

    return flags


def main():
    ap = argparse.ArgumentParser(description='Report RU translation auto-generation and quality flags')
    ap.add_argument('--json', action='store_true', help='Сохранить отчёт в JSON (ru_translation/out/report_YYYYMMDD_HHMMSS.json)')
    ap.add_argument('--csv', action='store_true', help='Сохранить отчёт в CSV (ru_translation/out/report_YYYYMMDD_HHMMSS.csv)')
    args = ap.parse_args()

    auto = []
    quality = {}
    for mod_dir in sorted(p for p in ext_dir.iterdir() if p.is_dir()):
        cx = mod_dir / 'content.xml'
        if not cx.exists():
            continue
        content, _ = parse_content(cx)
        if mod_is_auto_generated(content):
            auto.append(mod_dir.name)
        flags = gather_quality_flags(content)
        if flags:
            quality[mod_dir.name] = flags

    print('Отчёт для ручной вычитки автосгенерированных переводов:')
    print('—')
    if not auto:
        print('Нет модов, помеченных автогенерацией.')
    else:
        for m in auto:
            print(f'- {m}')
    print('—')

    print('Отчёт по качеству RU-описаний:')
    print('—')
    issues = 0
    for mod, flags in sorted(quality.items()):
        # Показываем только реальные проблемы
        if flags:
            issues += 1
            print(f'- {mod}: {", ".join(flags)}')
    if issues == 0:
        print('Проблем не найдено.')
    print('—')
    print(f'Итого: автогенерация: {len(auto)}; модов с флагами качества: {issues}')

    # Выгрузка
    if args.json or args.csv:
        OUT_DIR.mkdir(parents=True, exist_ok=True)
        ts = datetime.now().strftime('%Y%m%d_%H%M%S')
        if args.json:
            jpath = OUT_DIR / f'report_{ts}.json'
            payload = {
                'auto': auto,
                'quality': quality,
                'counts': {'auto': len(auto), 'issues': issues}
            }
            jpath.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding='utf-8')
            print(f'JSON: {jpath}')
        if args.csv:
            cpath = OUT_DIR / f'report_{ts}.csv'
            with cpath.open('w', newline='', encoding='utf-8') as f:
                w = csv.writer(f)
                w.writerow(['mod', 'flag'])
                for mod, flags in sorted(quality.items()):
                    if flags:
                        for fl in flags:
                            w.writerow([mod, fl])
            print(f'CSV: {cpath}')


if __name__ == '__main__':
    main()
