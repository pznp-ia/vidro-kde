"""Right-click menus of apps (Union style "vidro") + open/close animation of menus and popups
(KWin effect vidro_popups)."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import flag, hex_rgba, kwin_effect, kwrite, num, write_css

GROUP = 'Menus'
DEFAULTS = {
    'enabled': 'true',           # false = stock Union menus
    'radius': '12',              # menu corners (px)
    'opacity': '92',             # menu background (%)
    'padding': '6',              # inner spacing (px)
    'separators': '0',           # separator line visibility (0 = only a gap)
    'highlight': 'glass',        # glass | accent | custom
    'highlight_color': '#8ab4f8',
    'background': 'theme',       # theme | custom
    'background_color': '#1c1e24',
    'intensity': '14',           # item highlight strength (%)
    'border': '14',              # thin menu border (%)
    'animation': 'true',         # animate open/close
    'panel_style': 'slide',      # panel popups (launcher, clock, tray): slide | fade | scale | none
    'menu_style': 'fadescale',   # right-click menus and tooltips: fadescale | fade | slide | none
    'open_ms': '150',
    'close_ms': '110',
    'scale': '97',               # initial scale (%)
    'slide': '6',                # px
}


def _kwin(cfg):
    group = 'Effect-vidro_popups'
    for key, value in (('OpenMs', num(cfg, 'open_ms', 40, 600, 150)), ('CloseMs', num(cfg, 'close_ms', 40, 600, 110)),
                       ('Scale', num(cfg, 'scale', 70, 100, 97)), ('Slide', num(cfg, 'slide', 0, 60, 6))):
        kwrite('kwinrc', group, key, int(value))
    kwrite('kwinrc', group, 'PanelStyle', cfg.get('panel_style', 'slide'))
    kwrite('kwinrc', group, 'MenuStyle', cfg.get('menu_style', 'fadescale'))
    kwin_effect('vidro_popups', flag(cfg, 'animation'))


def apply(cfg):
    _kwin(cfg)
    if not flag(cfg, 'enabled'):
        write_css('menus', '/* off: stock menus */\n')
        return
    r = int(num(cfg, 'radius', 0, 24, 12))
    p = int(num(cfg, 'padding', 0, 14, 6))
    op = num(cfg, 'opacity', 40, 100, 92) / 100
    sep = num(cfg, 'separators', 0, 100, 12) / 100
    strength = num(cfg, 'intensity', 0, 60, 14) / 100
    border = num(cfg, 'border', 0, 60, 14) / 100
    item_r = max(2, r - p)  # item corners follow the menu corners
    mode = cfg.get('highlight', 'glass')
    if mode == 'custom':
        c = cfg.get('highlight_color', '#8ab4f8')
        hover, pressed = hex_rgba(c, min(1, strength * 2.2)), hex_rgba(c, min(1, strength * 3.2))
    elif mode == 'accent':
        hover = f'modify-color(var(--highlight-color) set-alpha {min(1, strength * 2.2):.3f})'
        pressed = f'modify-color(var(--highlight-color) set-alpha {min(1, strength * 3.2):.3f})'
    else:
        hover = f'modify-color(var(--window-text-color) set-alpha {strength:.3f})'
        pressed = f'modify-color(var(--window-text-color) set-alpha {min(1, strength * 1.6):.3f})'
    background = (hex_rgba(cfg.get('background_color', '#1c1e24'), op) if cfg.get('background') == 'custom'
                  else f'modify-color(var(--window-background-color) set-alpha {op:.3f})')
    line = f'modify-color(var(--window-text-color) set-alpha {sep * 0.5:.3f})' if sep > 0 else 'transparent'
    write_css('menus', f"""menu {{
    border-radius: {r}px;
    background-color: {background};
    border: 1px solid modify-color(var(--window-text-color) set-alpha {border:.3f});
    padding: {p}px;
}}
menuitem {{
    border-radius: {item_r}px;
    border: none;
    &:hovered,
    &.with-submenu:highlighted {{
        background-color: {hover};
        border: none;
    }}
    &:pressed,
    &.with-submenu:pressed {{
        background-color: {pressed};
        border: none;
        color: var(--window-text-color);
    }}
}}
menuseparator {{
    height: 1px;
    background-color: {line};
    inset: {max(3, p)}px;
    &.with-title {{ border-bottom: none; background-color: transparent; }}
}}
""")
