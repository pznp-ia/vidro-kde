"""Animations: open/close windows, minimize, maximize and show desktop (Vidro KWin effects),
plus KDE's global animation speed. Every animation has a style, a duration and a shared curve.
The matching stock KWin effects are turned off so only one animation plays."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import kread, kwin_effect, kwrite, num, run

GROUP = 'Animations'
DEFAULTS = {
    'open_style': 'scale',        # scale | zoom | glide | pop | fade | none
    'open_ms': '220',
    'close_style': 'scale',
    'close_ms': '180',
    'minimize_style': 'icon',     # icon | scale | fade | drop | none
    'minimize_ms': '360',
    'maximize_style': 'morph',    # morph | fade | none
    'maximize_ms': '280',
    'desktop_style': 'corners',   # corners | slide | sink | fade | none
    'desktop_ms': '320',
    'curve': 'smooth',            # smooth | snappy | spring
    'speed': '100',               # KDE global animation speed (%): 50 = slower, 200 = faster
}
# stock effects that would play the same animation
COMPETITORS = {
    'vidro_windows': ('fade', 'scale', 'glide'),
    'vidro_minimize': ('squash', 'magiclamp'),
    'vidro_maximize': ('maximize',),
    'vidro_desktop': ('windowaperture', 'eyeonscreen'),
}


def current():
    try:
        factor = float(kread('kdeglobals', 'KDE', 'AnimationDurationFactor', '1'))
        return {'speed': str(round(100 / factor)) if factor > 0 else '100'}
    except ValueError:
        return {}


def _ms(cfg, key, default):
    return int(num(cfg, key, 50, 1500, default))


def apply(cfg):
    curve = cfg.get('curve', 'smooth')
    settings = {
        'vidro_windows': ({'OpenStyle': cfg.get('open_style', 'scale'), 'CloseStyle': cfg.get('close_style', 'scale'),
                           'OpenMs': _ms(cfg, 'open_ms', 220), 'CloseMs': _ms(cfg, 'close_ms', 180), 'Curve': curve},
                          cfg.get('open_style') != 'none' or cfg.get('close_style') != 'none'),
        'vidro_minimize': ({'Style': cfg.get('minimize_style', 'icon'), 'Ms': _ms(cfg, 'minimize_ms', 360), 'Curve': curve},
                           cfg.get('minimize_style') != 'none'),
        'vidro_maximize': ({'Style': cfg.get('maximize_style', 'morph'), 'Ms': _ms(cfg, 'maximize_ms', 280), 'Curve': curve},
                           cfg.get('maximize_style') != 'none'),
        'vidro_desktop': ({'Style': cfg.get('desktop_style', 'corners'), 'Ms': _ms(cfg, 'desktop_ms', 320), 'Curve': curve},
                          cfg.get('desktop_style') != 'none'),
    }
    for effect, (keys, enabled) in settings.items():
        for k, v in keys.items():
            kwrite('kwinrc', f'Effect-{effect}', k, v)
        for other in COMPETITORS[effect]:
            if kread('kwinrc', 'Plugins', f'{other}Enabled') != 'false':
                kwin_effect(other, False)
        kwin_effect(effect, enabled)
    speed = num(cfg, 'speed', 25, 400, 100)
    factor = round(100 / speed, 3)
    try:
        same = abs(float(kread('kdeglobals', 'KDE', 'AnimationDurationFactor', '1')) - factor) < 0.001
    except ValueError:
        same = False
    if not same:
        kwrite('kdeglobals', 'KDE', 'AnimationDurationFactor', factor, notify=True)
