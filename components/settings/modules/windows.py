"""Windows: transparency (vidro_opacity effect, via vidro-opacity) and titlebar color (Vidro decoration)."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import BIN, kread, once, run

GROUP = 'Windows'
DEFAULTS = {
    'opacity': kread('kwinrc', 'Effect-vidro_opacity', 'Level', '50'),  # 0 opaque … 100 most transparent
    'titlebar': 'theme',          # theme (dark/light from the wallpaper) | custom
    'titlebar_color': '#262830',  # titlebar color when titlebar = custom
}


def apply(cfg):
    run(os.path.join(BIN, 'vidro-opacity'), str(cfg.get('opacity', '50')))
    # rebuild the decoration (a short flicker) only when the titlebar color changed
    if once('windows-titlebar', f"{cfg.get('titlebar')}|{cfg.get('titlebar_color')}"):
        run(os.path.join(BIN, 'vidro-titlebar'), '--force')
