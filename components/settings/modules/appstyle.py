"""App style studio: buttons, text fields, check boxes, tabs, list selection, focus ring and density
of every KDE app using the Union style "vidro". Writes explicit rules at the end of the style
(css/module-appstyle.css), so they win over the defaults. Open apps change when reopened."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import flag, hex_rgba, num, write_css

GROUP = 'AppStyle'
DEFAULTS = {
    'enabled': 'true',
    'radius': '8',               # corners of buttons, fields, check boxes (px)
    'density': 'normal',         # compact | normal | comfortable
    'buttons': 'glass',          # glass | flat | outline | filled
    'button_border': '10',       # border visibility (%)
    'fields': 'glass',           # glass | flat (underline) | filled
    'checks': 'rounded',         # rounded | circle
    'check_color': 'accent',     # accent | glass
    'tabs': 'segmented',         # segmented | pill | underline
    'selection': 'pill',         # pill (rounded, inset) | full (edge to edge)
    'focus': 'ring',             # ring | glow | none
    'accent_mode': 'theme',      # theme | custom — accent used by filled buttons, checks, focus
    'accent_color': '#5b9cf5',
}
DENSITY = {'compact': (3, 6, 22), 'normal': (5, 10, 28), 'comfortable': (8, 14, 34)}   # vertical padding, horizontal padding, (unused)


def _accent(cfg, alpha):
    if cfg.get('accent_mode') == 'custom':
        return hex_rgba(cfg.get('accent_color', '#5b9cf5'), alpha)
    return f'modify-color(var(--highlight-color) set-alpha {alpha:.3f})'


def apply(cfg):
    if not flag(cfg, 'enabled'):
        write_css('appstyle', '/* off: Vidro default app style */\n')
        return
    r = int(num(cfg, 'radius', 0, 18, 8))
    vpad, hpad, height = DENSITY.get(cfg.get('density', 'normal'), DENSITY['normal'])
    border = num(cfg, 'button_border', 0, 60, 10) / 100
    text = 'var(--window-text-color)'
    glass = lambda a: f'modify-color({text} set-alpha {a:.3f})'
    edge = f'1px solid {glass(border)}' if border > 0 else '1px solid transparent'
    css = []

    # ---- buttons ----
    style = cfg.get('buttons', 'glass')
    if style == 'flat':
        normal, hover, pressed, line = 'transparent', glass(0.08), glass(0.14), '1px solid transparent'
    elif style == 'outline':
        normal, hover, pressed, line = 'transparent', glass(0.06), glass(0.12), f'1px solid {glass(max(border, 0.22))}'
    elif style == 'filled':
        normal, hover, pressed, line = _accent(cfg, 0.85), _accent(cfg, 1.0), _accent(cfg, 0.7), '1px solid transparent'
    else:
        normal, hover, pressed, line = glass(0.06), glass(0.10), glass(0.15), edge
    css.append(f"""button, combobox {{
    border-radius: {r}px;
    padding: {vpad}px {hpad}px;
    background-color: {normal};
    border: {line};
    &:hovered {{ background-color: {hover}; }}
    &:pressed {{ background-color: {pressed}; }}
}}
toolbutton {{
    border-radius: {r}px;
    &:hovered {{ background-color: {glass(0.08)}; border: 1px solid transparent; }}
    &:pressed {{ background-color: {glass(0.14)}; }}
    &:checked {{ background-color: {_accent(cfg, 0.25)}; border: 1px solid {_accent(cfg, 0.45)}; }}
}}
""")
    if style == 'filled':
        css.append('button, combobox { color: var(--highlight-text-color); }\n')

    # ---- text fields ----
    fields = cfg.get('fields', 'glass')
    if fields == 'flat':
        css.append(f"""textfield, spinbox, searchfield {{
    border-radius: 0px;
    background-color: transparent;
    border: none;
    border-bottom: 1px solid {glass(0.25)};
    &:active-focus {{ border-bottom: 2px solid {_accent(cfg, 1.0)}; }}
}}
""")
    else:
        bg = glass(0.10) if fields == 'filled' else glass(0.04)
        css.append(f"""textfield, spinbox, searchfield {{
    border-radius: {r}px;
    padding: {vpad}px {max(6, hpad - 2)}px;
    background-color: {bg};
    border: {edge};
    &:active-focus {{ border: 1px solid {_accent(cfg, 0.7)}; }}
}}
""")

    # ---- check boxes, radio buttons ----
    check_r = '8px' if cfg.get('checks') == 'circle' else f'{max(2, r // 2)}px'   # indicator is 16 px: 8 px = circle
    checked = _accent(cfg, 0.95) if cfg.get('check_color', 'accent') == 'accent' else glass(0.3)
    css.append(f"""checkbox, checkdelegate, radiobutton, radiodelegate {{
    & > indicator {{ border-radius: {check_r}; background-color: {glass(0.06)}; border: 1px solid {glass(0.25)}; }}
    &:checked > indicator {{ background-color: {checked}; border: 1px solid {checked}; }}
}}
radiobutton, radiodelegate {{
    & > indicator {{ border-radius: 8px; }}
}}
""")

    # ---- tabs ----
    tabs = cfg.get('tabs', 'segmented')
    if tabs == 'pill':
        css.append(f"""tabbutton {{
    background-color: transparent;
    border: none;
    border-radius: {r + 6}px;
    &[direction="top"], &[direction="bottom"] {{ border: none; border-radius: {r + 6}px; }}
    &:hovered {{ background-color: {glass(0.07)}; }}
    &:checked, &:highlighted {{ background-color: {_accent(cfg, 0.22)}; border: none; }}
}}
tabbar {{ border: none; background-color: transparent; }}
""")
    elif tabs == 'underline':
        css.append(f"""tabbutton {{
    background-color: transparent;
    border: none;
    border-radius: 0px;
    &[direction="top"], &[direction="bottom"] {{ border: none; border-bottom: 2px solid transparent; border-radius: 0px; }}
    &:hovered {{ border-bottom: 2px solid {glass(0.25)}; }}
    &:checked, &:highlighted {{ border-bottom: 2px solid {_accent(cfg, 1.0)}; background-color: transparent; }}
}}
tabbar {{ border: none; background-color: transparent; }}
""")

    # ---- list selection ----
    if cfg.get('selection', 'pill') == 'pill':
        css.append(f"""itemdelegate, itemviewitem {{
    border-radius: {max(4, r - 2)}px;
}}
""")
    else:
        css.append('itemdelegate, itemviewitem { border-radius: 0px; }\n')

    # ---- focus ----
    focus = cfg.get('focus', 'ring')
    if focus == 'none':
        css.append('button, toolbutton, combobox, textfield, checkbox, radiobutton { &:visual-focus { outline: none; } }\n')
    elif focus == 'glow':
        css.append(f'button, toolbutton, combobox, textfield {{ &:visual-focus {{ border: 1px solid {_accent(cfg, 0.9)}; '
                   f'outline: 3px solid {_accent(cfg, 0.25)}; }} }}\n')
    else:
        css.append(f'button, toolbutton, combobox, textfield {{ &:visual-focus {{ outline: 2px solid {_accent(cfg, 0.55)}; }} }}\n')

    write_css('appstyle', ''.join(css))
