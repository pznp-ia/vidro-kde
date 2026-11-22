"""Window buttons (Vidro decoration): side, order, menu button, style, size, spacing and colors.
Drawn by make-decoration.py (reads the [Buttons] group of vidrorc); the order also goes to kwinrc."""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import BIN, kwrite, once, run

GROUP = 'Buttons'
DEFAULTS = {
    'side': 'left',             # left | right
    'order': 'macos',           # macos (close, minimize, maximize) | windows (minimize, maximize, close)
    'menu': 'false',            # window menu button on the other side
    'style': 'traffic',         # traffic | symbols | graphite | outline | icons | square
    'size': '6.5',              # radius (4-9)
    'spacing': '2',             # px between buttons
    'inactive': 'gray',         # gray | color (inactive windows)
    'color_mode': 'traffic',    # traffic | single | custom
    'single_color': '#8ab4f8',
    'close_color': '#ff5f57',   # used when color_mode = custom
    'minimize_color': '#febc2e',
    'maximize_color': '#28c840',
    'symbols': 'auto',          # auto (the style decides) | hover | always | never
    'symbol_weight': '1.3',     # symbol stroke thickness
    'hover': 'style',           # style (the style's own) | brighten | glow | none
}


def layout(cfg):
    """KWin button strings for the left and right sides."""
    seq = 'XIA' if cfg.get('order') == 'macos' else 'IAX'
    menu = 'M' if cfg.get('menu') == 'true' else ''
    return (seq, menu) if cfg.get('side', 'left') == 'left' else (menu, seq)


def apply(cfg):
    if not once('buttons', json.dumps({k: cfg.get(k) for k in DEFAULTS}, sort_keys=True)):
        return
    left, right = layout(cfg)
    kwrite('kwinrc', 'org.kde.kdecoration2', 'ButtonsOnLeft', left)
    kwrite('kwinrc', 'org.kde.kdecoration2', 'ButtonsOnRight', right)
    # rebuild the decoration (reads [Buttons] from vidrorc) and reload KWin
    run(os.path.join(BIN, 'vidro-titlebar'), '--force')
