"""Taskbar show/hide animation (KWin effect vidro_panel): style for appearing and for disappearing,
durations, curve, slide distance and start scale. Only visible when the panel hides by itself
(Taskbar > Hiding: auto-hide / dodge windows)."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import flag, kwin_effect, kwrite, num

GROUP = 'PanelAnimation'
STYLES = ('slide', 'fade', 'slidefade', 'scale', 'rise', 'none')
DEFAULTS = {
    'enabled': 'true',
    'show_style': 'slide',     # slide | fade | slidefade | scale | rise | none
    'hide_style': 'slide',
    'show_ms': '260',
    'hide_ms': '200',
    'curve': 'smooth',         # smooth | snappy | spring | linear
    'distance': '100',         # % of the panel thickness
    'scale': '90',             # % start size (scale / rise)
}


def apply(cfg):
    keys = {
        'ShowStyle': cfg.get('show_style') if cfg.get('show_style') in STYLES else 'slide',
        'HideStyle': cfg.get('hide_style') if cfg.get('hide_style') in STYLES else 'slide',
        'ShowMs': int(num(cfg, 'show_ms', 50, 1500, 260)),
        'HideMs': int(num(cfg, 'hide_ms', 50, 1500, 200)),
        'Curve': cfg.get('curve') if cfg.get('curve') in ('smooth', 'snappy', 'spring', 'linear') else 'smooth',
        'Distance': int(num(cfg, 'distance', 10, 150, 100)),
        'Scale': int(num(cfg, 'scale', 50, 100, 90)),
    }
    for k, v in keys.items():
        kwrite('kwinrc', 'Effect-vidro_panel', k, v)
    kwin_effect('vidro_panel', flag(cfg, 'enabled'))
