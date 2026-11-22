"""Launcher menu and Plasma popups (Plasma style "Vidro"):
glass background with adjustable corners + matching gaussian shadow (dialogs/background)
and header/footer without lines (widgets/plasmoidheading). Applies to every panel popup
(launcher, clock, system tray...). Original templates in ~/.local/share/vidro/templates."""
import gzip, math, os, re, subprocess, sys, time
sys.path.insert(0, os.path.dirname(__file__))
from _common import DATA, VIDRO, flag, num

GROUP = 'Popups'
DEFAULTS = {
    'enabled': 'true',        # false = popups as they were (original templates)
    'radius': '14',          # corners (px)
    'background': 'theme',   # theme | custom
    'glass_color': '#1c1e24', # glass color when background = custom
    'opacity': '80',          # background (%)
    'border': '10',           # thin outline (%)
    'lines': '0',             # header/footer lines (%)
    'header': '0',            # header/footer own background (%) — 0 = continuous
    'shadow': '55',           # shadow strength (%)
    'shadow_size': '18',      # shadow size (px)
}

THEME = os.path.join(DATA, 'plasma', 'desktoptheme', 'Vidro')
TEMPLATES = os.path.join(VIDRO, 'templates')


def _gz(path, texto):
    with gzip.open(path, 'wb') as f:
        f.write(texto.encode())


def dialog_svg(R, op, border, strength, S, color=None, margin=None):
    """9-part SVG (frame + blur mask + shadow) with corner radius R."""
    R = max(2, R); C = R                    # size of the frame corners
    St, Ss, Sb = max(4, round(S * 0.7)), S, max(6, round(S * 1.3))
    sig = max(2.0, S / 2.6)
    defs, body = [], []
    gid = [0]
    ox = [0]

    def group(id_, w, h, items):
        x0 = ox[0]; ox[0] += w + 8
        body.append(f'<g id="{id_}" transform="translate({x0},0)"><rect width="{w}" height="{h}" fill="#000" opacity="0"/>{"".join(items)}</g>')

    def mirrors(name, w, h, fn):
        """fn() draws the top-left corner; the 4 corners are made by mirroring."""
        out = {}
        for k, m in (('topleft', '1,0,0,1,0,0'), ('topright', f'-1,0,0,1,{w},0'),
                     ('bottomleft', f'1,0,0,-1,0,{h}'), ('bottomright', f'-1,0,0,-1,{w},{h}')):
            out[k] = [f'<g transform="matrix({m})">{"".join(fn())}</g>']
        return out

    fill = (f'fill="{color}" fill-opacity="{op:.3f}"' if color else
             f'class="ColorScheme-Background" fill="currentColor" fill-opacity="{op:.3f}"')
    line = f'class="ColorScheme-Text" fill="currentColor" fill-opacity="{border:.3f}"'

    # ---- frame ----
    def corner():
        it = [f'<path {fill} d="M0,{C}A{R},{R} 0 0 1 {R},0H{C}V{C}Z"/>']
        if border > 0:
            it.append(f'<path {line} fill-rule="evenodd" d="M0,{C}A{R},{R} 0 0 1 {R},0V1A{R-1},{R-1} 0 0 0 1,{C}Z"/>')
        return it
    for k, v in mirrors('frame', C, C, corner).items():
        group(k, C, C, v)
    L = 16
    def side(horiz, start):
        w, h = (L, C) if horiz else (C, L)
        it = [f'<rect {fill} width="{w}" height="{h}"/>']
        if border > 0:
            if horiz:
                it.append(f'<rect {line} y="{0 if start else C-1}" width="{w}" height="1"/>')
            else:
                it.append(f'<rect {line} x="{0 if start else C-1}" width="1" height="{h}"/>')
        return w, h, it
    for k, hz, ini in (('top', 1, 1), ('bottom', 1, 0), ('left', 0, 1), ('right', 0, 0)):
        w, h, it = side(hz, ini); group(k, w, h, it)
    group('center', L, L, [f'<rect {fill} width="{L}" height="{L}"/>'])

    # content margins
    m = margin if margin is not None else max(4, round(R * 0.5))
    for k in ('top', 'bottom', 'left', 'right'):
        group(f'hint-{k}-margin', m, m, [])

    # ---- mask (blur region) ----
    black = 'fill="#000"'
    def mask_corner():
        return [f'<path {black} d="M0,{C}A{R},{R} 0 0 1 {R},0H{C}V{C}Z"/>']
    for k, v in mirrors('mask', C, C, mask_corner).items():
        group(f'mask-{k}', C, C, v)
    for k in ('top', 'bottom'):
        group(f'mask-{k}', L, C, [f'<rect {black} width="{L}" height="{C}"/>'])
    for k in ('left', 'right'):
        group(f'mask-{k}', C, L, [f'<rect {black} width="{C}" height="{L}"/>'])
    group('mask-center', L, L, [f'<rect {black} width="{L}" height="{L}"/>'])

    # ---- shadow (gaussian profile, corners consistent with the sides) ----
    def pr(d):
        return strength * math.exp(-(max(0.0, d) ** 2) / (2 * sig * sig))

    def stops(d0, d1, n=14):
        return ''.join(f'<stop offset="{i/(n-1):.4f}" stop-color="#000" stop-opacity="{pr(d0+(d1-d0)*i/(n-1)):.4f}"/>' for i in range(n))

    def lin(x1, y1, x2, y2, d0, d1):
        gid[0] += 1; i = f'vs{gid[0]}'
        defs.append(f'<linearGradient id="{i}" gradientUnits="userSpaceOnUse" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{stops(d0, d1)}</linearGradient>')
        return f'url(#{i})'

    def rad(cx, cy, r0, r1):
        gid[0] += 1; i = f'vs{gid[0]}'
        n = 18
        st = ''.join(f'<stop offset="{i2/(n-1):.4f}" stop-color="#000" stop-opacity="{pr(r1*i2/(n-1) - r0):.4f}"/>' for i2 in range(n))
        defs.append(f'<radialGradient id="{i}" gradientUnits="userSpaceOnUse" cx="{cx}" cy="{cy}" r="{r1}">{st}</radialGradient>')
        return f'url(#{i})'

    # shadow corners: (x, y) margin sizes; the window takes the inner corner with radius R
    def shadow_corner(name, mx, my):
        w, h = mx + R, my + R
        cx, cy = w, h  # arc center = inner corner of the tile
        window = f'M{mx},{h}V{my+R}A{R},{R} 0 0 1 {mx+R},{my}H{w}V{h}Z'
        it = [f'<path fill="{rad(cx, cy, R, R + max(mx, my) + 2)}" fill-rule="evenodd" d="M0,0H{w}V{h}H0Z {window}"/>']
        return w, h, it
    for k, mx, my, m_ in (('topleft', Ss, St, '1,0,0,1,0,0'), ('topright', Ss, St, None),
                          ('bottomleft', Ss, Sb, None), ('bottomright', Ss, Sb, None)):
        w, h, it = shadow_corner(k, mx, my)
        if k == 'topright':
            it = [f'<g transform="matrix(-1,0,0,1,{w},0)">{"".join(it)}</g>']
        elif k == 'bottomleft':
            it = [f'<g transform="matrix(1,0,0,-1,0,{h})">{"".join(it)}</g>']
        elif k == 'bottomright':
            it = [f'<g transform="matrix(-1,0,0,-1,{w},{h})">{"".join(it)}</g>']
        group(f'shadow-{k}', w, h, it)
    group('shadow-top', L, St, [f'<rect fill="{lin(0, St, 0, 0, 0, St)}" width="{L}" height="{St}"/>'])
    group('shadow-bottom', L, Sb, [f'<rect fill="{lin(0, 0, 0, Sb, 0, Sb)}" width="{L}" height="{Sb}"/>'])
    group('shadow-left', Ss, L, [f'<rect fill="{lin(Ss, 0, 0, 0, 0, Ss)}" width="{Ss}" height="{L}"/>'])
    group('shadow-right', Ss, L, [f'<rect fill="{lin(0, 0, Ss, 0, 0, Ss)}" width="{Ss}" height="{L}"/>'])
    group('shadow-center', L, L, [])
    for k, v in (('top', St), ('bottom', Sb), ('left', Ss), ('right', Ss)):
        group(f'shadow-hint-{k}-margin', v, v, [])

    style = ('<style type="text/css" id="current-color-scheme">'
              '.ColorScheme-Text{color:#232629;}.ColorScheme-Background{color:#eff0f1;}</style>')
    return (f'<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="{ox[0]}" height="{max(C, Sb + R, L) + 8}">'
            f'<defs>{style}{"".join(defs)}</defs>{"".join(body)}</svg>\n')


def header_svg(lines, background):
    s = open(os.path.join(TEMPLATES, 'plasmoidheading.svg')).read()
    # lines (ColorScheme-Frame) and background (ColorScheme-Background) with adjustable opacity
    s = re.sub(r'class="ColorScheme-Frame"', f'class="ColorScheme-Frame" opacity="{lines:.3f}"', s)
    s = re.sub(r'class="ColorScheme-Background"', f'class="ColorScheme-Background" opacity="{background:.3f}"', s)
    return s


def reload_theme():
    # clear the style image cache (otherwise Plasma reuses the old SVG) and switch styles back and forth
    cache = os.path.expanduser('~/.cache')
    for f in os.listdir(cache):
        if f.startswith('plasma_theme_Vidro') or f.startswith('ksvg-elements') or f.startswith('plasma-svgelements'):
            try: os.remove(os.path.join(cache, f))
            except OSError: pass
    for t in ('breeze-dark', 'Vidro'):
        subprocess.run(['plasma-apply-desktoptheme', t], capture_output=True)
        time.sleep(0.4)


def apply(cfg):
    if not os.path.isdir(THEME) or not os.path.isfile(os.path.join(TEMPLATES, 'dialogs-background.svg')):
        return
    # Plasma uses translucent/dialogs when blur is available (the usual case); dialogs/ only without effects
    translucent = os.path.join(THEME, 'translucent', 'dialogs', 'background.svgz')
    translucent_template = os.path.join(TEMPLATES, 'translucent-dialogs-background.svg')
    if not flag(cfg, 'enabled'):
        _gz(os.path.join(THEME, 'dialogs', 'background.svgz'), open(os.path.join(TEMPLATES, 'dialogs-background.svg')).read())
        if os.path.isfile(translucent_template) and os.path.isdir(os.path.dirname(translucent)):
            _gz(translucent, open(translucent_template).read())
        _gz(os.path.join(THEME, 'widgets', 'plasmoidheading.svgz'), open(os.path.join(TEMPLATES, 'plasmoidheading.svg')).read())
    else:
        R = int(num(cfg, 'radius', 2, 30, 14))
        op = num(cfg, 'opacity', 30, 100, 80) / 100
        border = num(cfg, 'border', 0, 60, 10) / 100
        strength = num(cfg, 'shadow', 0, 100, 55) / 100 * 0.5
        S = int(num(cfg, 'shadow_size', 4, 40, 18))
        color = cfg.get('glass_color', '#1c1e24') if cfg.get('background') == 'custom' else None
        if color and not re.fullmatch(r'#[0-9a-fA-F]{6}', color):
            color = None
        svg = dialog_svg(R, op, border, strength, S, color)
        _gz(os.path.join(THEME, 'dialogs', 'background.svgz'), svg)
        if os.path.isdir(os.path.dirname(translucent)):
            _gz(translucent, svg)
        _gz(os.path.join(THEME, 'widgets', 'plasmoidheading.svgz'),
            header_svg(num(cfg, 'lines', 0, 100, 0) / 100, num(cfg, 'header', 0, 100, 0) / 100))
    reload_theme()
