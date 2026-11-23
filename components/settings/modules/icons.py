"""Icons of the Vidro icon theme: folder colors, file (document) icons and the small sidebar icons.
Regenerates the icons and switches the icon theme back and forth so apps refresh immediately."""
import colorsys, glob, os, sys, time
sys.path.insert(0, os.path.dirname(__file__))
from _common import DATA, flag, kread, kwrite, num, run

GROUP = 'Icons'
DEFAULTS = {
    'enabled': 'true',          # false = original dark folders
    'folder_mode': 'graphite',  # dark | graphite | accent | custom
    'folder_color': '#7aa2d6',  # used in mode "custom"
    'brightness': '50',         # 0 dark … 100 light
    'relief': '45',             # difference between top and bottom of the folder (gradient)
    'saturation': '60',         # 0 gray … 100 vivid (modes accent/custom)
    # files (documents)
    'file_style': 'dark',       # dark | light | colored | flat
    'file_label': 'true',       # extension label (PDF, PNG…)
    'file_colors': 'type',      # type | single | gray
    'file_color': '#58a6ff',
    'file_fold': 'true',        # folded corner
    'file_radius': '3',
    # sidebar (Dolphin and file dialogs)
    'sidebar_style': 'line',    # line | filled | colored
    'sidebar_color': '#d9dae0',
    'sidebar_stroke': '1.3',
    'sidebar_size': 'auto',     # icon size in Dolphin's sidebar: auto | 16 | 22 | 32
}
THEME = os.path.join(DATA, 'icons', 'Vidro')


def _hex(rgb):
    return '#%02x%02x%02x' % tuple(max(0, min(255, round(c * 255))) for c in rgb)


def _accent():
    try:
        r, g, b = (int(x) / 255 for x in kread('kdeglobals', 'Colors:Selection', 'BackgroundNormal').split(',')[:3])
        return r, g, b
    except ValueError:
        return 0.24, 0.68, 0.91


def folder_colors(cfg):
    """Front/back gradient colors and glyph color of the big folders."""
    mode = cfg.get('folder_mode', 'graphite')
    bright = num(cfg, 'brightness', 0, 100, 50) / 100
    relief = num(cfg, 'relief', 0, 100, 45) / 100
    sat = num(cfg, 'saturation', 0, 100, 60) / 100
    if mode == 'dark':
        h, s, l = 0.64, 0.10, 0.10 + 0.20 * bright
    elif mode == 'graphite':
        h, s, l = 0.63, 0.08, 0.28 + 0.40 * bright
    else:
        if mode == 'accent':
            r, g, b = _accent()
        else:
            c = cfg.get('folder_color', '#7aa2d6').lstrip('#')
            r, g, b = (int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)) if len(c) == 6 else (0.48, 0.64, 0.84)
        h, _l, s0 = colorsys.rgb_to_hls(r, g, b)
        s, l = s0 * sat, 0.22 + 0.50 * bright
    d = 0.04 + 0.16 * relief
    hls = lambda light: _hex(colorsys.hls_to_rgb(h, max(0, min(1, light)), s))
    glyph = '#1c1d22' if l > 0.62 else '#eceef3'   # dark glyph on light folders and vice versa
    return hls(l + d), hls(l - d), hls(l - 0.05), hls(l - 0.05 - 2 * d), glyph


def apply(cfg):
    source = os.path.join(THEME, 'source')
    script = os.path.join(source, 'make-icons.py')
    if not os.path.isfile(script):
        return
    env = dict(os.environ)
    if flag(cfg, 'enabled'):
        f1, f2, b1, b2, gl = folder_colors(cfg)
        env.update(VIDRO_FOLDER_FRONT1=f1, VIDRO_FOLDER_FRONT2=f2, VIDRO_FOLDER_BACK1=b1,
                   VIDRO_FOLDER_BACK2=b2, VIDRO_FOLDER_GLYPH=gl)
    env.update(VIDRO_FILE_STYLE=cfg.get('file_style', 'dark'),
               VIDRO_FILE_LABEL='1' if flag(cfg, 'file_label') else '0',
               VIDRO_FILE_COLORS=cfg.get('file_colors', 'type'), VIDRO_FILE_COLOR=cfg.get('file_color', '#58a6ff'),
               VIDRO_FILE_FOLD='1' if flag(cfg, 'file_fold') else '0', VIDRO_FILE_RADIUS=str(num(cfg, 'file_radius', 0, 10, 3)),
               VIDRO_SIDEBAR_STYLE=cfg.get('sidebar_style', 'line'), VIDRO_SIDEBAR_COLOR=cfg.get('sidebar_color', '#d9dae0'),
               VIDRO_SIDEBAR_STROKE=str(num(cfg, 'sidebar_stroke', 0.8, 2.2, 1.3)))
    size = cfg.get('sidebar_size', 'auto')
    if size == 'auto':
        run('kwriteconfig6', '--file', 'dolphinrc', '--group', 'PlacesPanel', '--key', 'IconSize', '--delete')
    else:
        kwrite('dolphinrc', 'PlacesPanel', 'IconSize', int(num(cfg, 'sidebar_size', 16, 48, 22)))
    import subprocess
    subprocess.run(['python3', '-I', script, THEME, os.path.join(source, 'places.txt'), os.path.join(source, 'mimes.txt')],
                   env=env, capture_output=True)
    # apps only reload icons when the theme changes: switch away and back
    for t in ('breeze-dark', 'Vidro'):
        tool = next((p for p in ['/usr/libexec/plasma-changeicons', '/usr/lib/plasma-changeicons', '/usr/lib64/libexec/plasma-changeicons']
                     + sorted(glob.glob('/usr/lib/*/libexec/plasma-changeicons')) if os.access(p, os.X_OK)), None)
        if tool:   # Fedora /usr/libexec, Arch/SteamOS /usr/lib, Debian/Ubuntu /usr/lib/<arch>/libexec
            run(tool, t)
        time.sleep(0.5)
