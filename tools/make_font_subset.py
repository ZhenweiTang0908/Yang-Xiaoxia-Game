"""Rebuild assets/art/ui_font.ttf from the full Noto Sans SC, or check it covers the game's text.

  .venv/bin/python tools/make_font_subset.py          rebuild the subset
  .venv/bin/python tools/make_font_subset.py --check  list characters the game uses but the font lacks

The web build has no system fonts to fall back on, so any missing glyph shows as a box there.
The subset keeps every character found in scripts, scenes and data, the 3755 common GB2312
level-1 hanzi (so new lines rarely need a rebuild), and everything the old subset had.
"""
from pathlib import Path
import sys
from fontTools.ttLib import TTFont

SOURCE = Path('art_source/fonts/NotoSansSC[wght].ttf')
OUTPUT = Path('assets/art/ui_font.ttf')
WEIGHT = 500
TEXT_SOURCES = ['scripts/**/*.gd', 'scenes/**/*.tscn', 'data/**/*.tres', 'data/**/*.json']


def game_text():
    chars = set()
    for pattern in TEXT_SOURCES:
        for path in Path('.').glob(pattern):
            chars.update(path.read_text(encoding='utf-8', errors='ignore'))
    # Only visible characters matter; control codes and whitespace other than space are noise.
    return {c for c in chars if c == ' ' or (c.isprintable() and not c.isspace())}


def common_hanzi():
    chars = set()
    for high in range(0xB0, 0xD8):
        for low in range(0xA1, 0xFF):
            try:
                chars.add(bytes([high, low]).decode('gb2312'))
            except UnicodeDecodeError:
                pass
    return chars


def missing(font_path, chars):
    cmap = TTFont(font_path).getBestCmap()
    return sorted(c for c in chars if ord(c) not in cmap)


def check():
    lacking = missing(OUTPUT, game_text())
    if lacking:
        print(f'{OUTPUT} 缺少 {len(lacking)} 个游戏用到的字：{"".join(lacking)}')
        print('运行 .venv/bin/python tools/make_font_subset.py 重新生成字库')
        return 1
    print(f'{OUTPUT} 覆盖了游戏用到的全部字符')
    return 0


def build():
    from fontTools.varLib import instancer
    from fontTools import subset

    chars = game_text() | common_hanzi() | {chr(c) for c in range(0x20, 0x7F)}
    if OUTPUT.exists():
        chars |= {chr(c) for c in TTFont(OUTPUT).getBestCmap()}
    font = instancer.instantiateVariableFont(TTFont(SOURCE), {'wght': WEIGHT})
    options = subset.Options()
    options.layout_features = ['*']
    options.name_IDs = ['*']
    options.notdef_outline = True
    options.hinting = False
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=[ord(c) for c in chars])
    subsetter.subset(font)
    font.save(OUTPUT)
    lacking = missing(OUTPUT, game_text())
    print(f'已生成 {OUTPUT}：{len(TTFont(OUTPUT).getBestCmap())} 个字符，{OUTPUT.stat().st_size // 1024} KB')
    if lacking:
        print(f'原始字体也没有这些字符：{"".join(lacking)}')


if __name__ == '__main__':
    sys.exit(check() if '--check' in sys.argv else build())
