"""Light (experimental): a light Vidro keeping the transparencies.
On: "VidroClaro" color scheme + light glass titlebar (adjustable opacity).
Off (default): back to the dark "Vidro" scheme and the automatic titlebar color."""
import os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(__file__))
from _common import BIN, DATA, flag, kwin_reconfigure, kwrite, num, run

GROUP = 'Light'
DEFAULTS = {
    'enabled': 'false',
    'glass': '100',   # 20-160: titlebar glass opacity (100 = normal; less = more transparent)
}
THEME = os.path.join(DATA, 'aurorae', 'themes', 'Vidro')


def _reload_decoration():
    deco = 'org.kde.kdecoration2'
    kwrite('kwinrc', deco, 'library', 'org.kde.breeze'); kwrite('kwinrc', deco, 'theme', 'Breeze'); kwin_reconfigure()
    time.sleep(0.6)
    kwrite('kwinrc', deco, 'library', 'org.kde.kwin.aurorae.v2'); kwrite('kwinrc', deco, 'theme', '__aurorae__svg__Vidro'); kwin_reconfigure()


def apply(cfg):
    if flag(cfg, 'enabled'):
        run('plasma-apply-colorscheme', 'VidroClaro')
        env = dict(os.environ, VIDRO_ALPHA=str(num(cfg, 'glass', 20, 160, 100) / 100))
        subprocess.run(['python3', '-I', os.path.join(THEME, 'source', 'make-decoration.py'), THEME, 'light'],
                       env=env, capture_output=True)
        _reload_decoration()
    else:
        run('plasma-apply-colorscheme', 'Vidro')
        run(os.path.join(BIN, 'vidro-titlebar'), '--force')
