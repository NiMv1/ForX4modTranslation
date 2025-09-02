from pathlib import Path
import sys

def scan_for_readtext(root_dir: Path):
    root_dir = Path(root_dir)
    for path in root_dir.rglob('*.xml'):
        try:
            with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                for i, line in enumerate(f, 1):
                    if 'readtext' in line.lower():
                        print(f"{path}:{i}: {line.strip()}")
        except Exception as e:
            print(f"ERROR:{path}: {e}")

if __name__ == '__main__':
    # По умолчанию сканируем папку extensions/ в корне репозитория
    default_root = Path(__file__).resolve().parents[1] / 'extensions'
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else default_root
    scan_for_readtext(root)
