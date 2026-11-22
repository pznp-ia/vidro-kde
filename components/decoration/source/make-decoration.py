"""Generates the Vidro Aurorae window decoration (decoration.svg, buttons, Vidrorc).
Usage: python3 -I make-decoration.py <theme-folder> [dark|light]
Reads [Windows] (titlebar color) and [Buttons] (button style) from ~/.config/vidrorc."""
import os, sys, math, re, configparser
OUT = sys.argv[1]
MODE = sys.argv[2] if len(sys.argv) > 2 else 'dark'   # 'dark' or 'light'
MODE = {'escuro': 'dark', 'claro': 'light'}.get(MODE, MODE)  # old names
os.makedirs(OUT, exist_ok=True)

PL = PR = 26; PT = 20; PB = 34     # padding (room for the shadow)
SIG, DY = 9, 6                     # shadow blur (sigma) and downward offset
RB = 6                             # shadow radius at the bottom corners
R = 12                             # top corner radius
TB = 32                            # total titlebar height
TBM = 28                           # maximized titlebar
L = PL + R; T = PT + TB; Bm = PB + 2; yb = Bm - PB

STATES = {
  'decoration': dict(base='rgba(38,40,48,0.50)', hl=0.28, glow=0.12, outline=0.55, sh=0.70, sep=0.30),
  'decoration-inactive': dict(base='rgba(30,31,36,0.38)', hl=0.14, glow=0.05, outline=0.40, sh=0.38, sep=0.18),
} if MODE == 'dark' else {
  'decoration': dict(base='rgba(246,246,250,0.55)', hl=0.70, glow=0.25, outline=0.28, sh=0.50, sep=0.12),
  'decoration-inactive': dict(base='rgba(236,236,242,0.42)', hl=0.45, glow=0.12, outline=0.20, sh=0.28, sep=0.08),
}
INACT_BTN = ('#fff', 0.16, 0.35) if MODE == 'dark' else ('#000', 0.14, 0.18)
# VIDRO_ALPHA (0.2-1.6, default 1): multiplies the titlebar glass opacity (used by the "Light" option)
try: _ALFA = max(0.2, min(1.6, float(os.environ.get('VIDRO_ALPHA', os.environ.get('VIDRO_ALFA', '1')))))
except ValueError: _ALFA = 1.0
if _ALFA != 1.0:
    for _st in STATES.values():
        _r, _g, _b, _a = _st['base'][5:-1].split(',')
        _st['base'] = f'rgba({_r},{_g},{_b},{min(0.98, float(_a) * _ALFA):.3f})'
def rgba(s):  # "rgba(r,g,b,a)" -> fill + fill-opacity
    r,g,b,a = s[5:-1].split(','); return f'fill="rgb({r},{g},{b})" fill-opacity="{a}"'

defs = []; body = []; gid = [0]
def grad(kind, stops, **attrs):
    gid[0] += 1; i = f'g{gid[0]}'
    st = ''.join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o,c,a in stops)
    at = ' '.join(f'{k}="{v}"' for k,v in attrs.items())
    defs.append(f'<{kind}Gradient id="{i}" gradientUnits="userSpaceOnUse" {at}>{st}</{kind}Gradient>')
    return f'url(#{i})'
# Shadow = the window rectangle moved DY down and blurred (gaussian profile).
# d = signed distance to that rectangle's edge; every piece uses the same profile,
# so corners and sides fit without seams.
def prof(d): return 0.5 * math.erfc(d / (SIG * math.sqrt(2)))
def dstops(a, d0, d1, n=18):
    return [(round(i/(n-1),4), '#000', round(a*prof(d0+(d1-d0)*i/(n-1)),4)) for i in range(n)]
def lin(a, x1, y1, x2, y2, d0, d1):
    return grad("linear", dstops(a, d0, d1), x1=x1, y1=y1, x2=x2, y2=y2)
def rad(a, cx, cy, rs):
    r = rs + 3*SIG
    return grad("radial", dstops(a, -rs, r - rs, 26), cx=cx, cy=cy, r=r)

ox = [0]
def place(w, h):
    x0 = ox[0]; ox[0] += w + 10; return x0, 0
def group(id_, w, h, items):
    x0, y0 = place(w, h)
    body.append(f'<g id="{id_}" transform="translate({x0},{y0})"><rect width="{w}" height="{h}" fill="#000" opacity="0"/>{"".join(items)}</g>')
# NOTE: KSvg measures elements including the group's own transform, so we use translate.

def mirror_items(fn, w):
    return [f'<g transform="matrix(-1,0,0,1,{w},0)">{"".join(fn())}</g>']

def frame(prefix, st, mask=False):
    a = st['sh']
    def topleft():
        it = []
        if not mask:
            cx, cy = PL + R, PT + DY + R
            it.append(f'<path fill="{rad(a, cx, cy, R)}" d="M0,0H{L}V{PT}H{PL+R}A{R},{R} 0 0 0 {PL},{PT+R}V{cy}H0Z"/>')
            it.append(f'<path fill="{lin(a, 0, 0, PL, 0, PL, 0)}" d="M0,{cy}H{PL}V{T}H0Z"/>')
        shape = f'M{PL},{T}V{PT+R}A{R},{R} 0 0 1 {PL+R},{PT}H{L}V{T}Z'
        if mask:
            return [f'<path fill="#000" d="{shape}"/>']
        it.append(f'<path {rgba(st["base"])} d="{shape}"/>')
        it.append(f'<path fill="{grad("linear", [(0,"#fff",st["glow"]),(1,"#fff",0)], x1=0, y1=PT, x2=0, y2=T)}" d="{shape}"/>')
        P = lambda o: f'M{PL+o},{T}V{PT+R}A{R-o},{R-o} 0 0 1 {PL+R},{PT+o}H{L}V{T}Z'
        it.append(f'<path fill-rule="evenodd" fill="#000" fill-opacity="{st["outline"]}" d="{P(0)} {P(1)}"/>')
        it.append(f'<path fill-rule="evenodd" fill="{grad("linear", [(0,"#fff",st["hl"]),(1,"#fff",0)], x1=0, y1=PT, x2=0, y2=PT+R+6)}" d="{P(1)} {P(2)}"/>')
        it.append(f'<rect x="{PL+1}" y="{T-1}" width="{L-PL-1}" height="1" fill="#000" fill-opacity="{st["sep"]}"/>')
        return it
    def top():
        if mask: return [f'<rect y="{PT}" width="20" height="{TB}" fill="#000"/>']
        return [f'<rect width="20" height="{PT}" fill="{lin(a, 0, 0, 0, PT, PT+DY, DY)}"/>',
                f'<rect y="{PT}" width="20" height="{TB}" {rgba(st["base"])}/>',
                f'<rect y="{PT}" width="20" height="{TB}" fill="{grad("linear", [(0,"#fff",st["glow"]),(1,"#fff",0)], x1=0, y1=PT, x2=0, y2=T)}"/>',
                f'<rect y="{PT}" width="20" height="1" fill="#000" fill-opacity="{st["outline"]}"/>',
                f'<rect y="{PT+1}" width="20" height="1" fill="#fff" fill-opacity="{st["hl"]}"/>',
                f'<rect y="{T-1}" width="20" height="1" fill="#000" fill-opacity="{st["sep"]}"/>']
    def left():
        if mask: return [f'<rect x="{PL}" width="{R}" height="20" fill="#000"/>']
        return [f'<rect width="{PL}" height="20" fill="{lin(a, 0, 0, PL, 0, PL, 0)}"/>',
                f'<rect x="{PL}" width="1" height="20" fill="#000" fill-opacity="{st["outline"]}"/>',
                f'<rect x="{PL+1}" width="{R-1}" height="20" {rgba(st["base"])}/>']
    def bottomleft():
        if mask: return [f'<rect x="{PL}" width="{R}" height="{yb}" fill="#000"/>']
        cx, cy = PL + RB, max(yb, yb + DY - RB)
        sh = []
        if cy > 0: sh.append(f'<rect width="{PL}" height="{cy}" fill="{lin(a, 0, 0, PL, 0, PL, 0)}"/>')
        return sh + [f'<rect y="{cy}" width="{cx}" height="{Bm-cy}" fill="{rad(a, cx, cy, RB)}"/>',
                f'<rect x="{cx}" y="{yb}" width="{L-cx}" height="{Bm-yb}" fill="{lin(a, 0, yb, 0, Bm, -DY, PB-DY)}"/>',
                f'<rect x="{PL+1}" width="{R-1}" height="{yb-1}" {rgba(st["base"])}/>',
                f'<rect x="{PL}" width="1" height="{yb}" fill="#000" fill-opacity="{st["outline"]}"/>',
                f'<rect x="{PL+1}" y="{yb-1}" width="{R-1}" height="1" fill="#000" fill-opacity="{st["outline"]}"/>']
    def bottom():
        if mask: return [f'<rect width="20" height="{yb}" fill="#000"/>']
        return [f'<rect width="20" height="{yb-1}" {rgba(st["base"])}/>',
                f'<rect y="{yb-1}" width="20" height="1" fill="#000" fill-opacity="{st["outline"]}"/>',
                f'<rect y="{yb}" width="20" height="{Bm-yb}" fill="{lin(a, 0, yb, 0, Bm, -DY, PB-DY)}"/>']
    def center():
        return [f'<rect width="20" height="20" fill="#000"/>'] if mask else [f'<rect width="20" height="20" fill="#000" fill-opacity="0"/>']
    group(f'{prefix}-topleft', L, T, topleft())
    group(f'{prefix}-topright', L, T, mirror_items(topleft, L))
    group(f'{prefix}-top', 20, T, top())
    group(f'{prefix}-left', L, 20, left())
    group(f'{prefix}-right', L, 20, mirror_items(left, L))
    group(f'{prefix}-bottomleft', L, Bm, bottomleft())
    group(f'{prefix}-bottomright', L, Bm, mirror_items(bottomleft, L))
    group(f'{prefix}-bottom', 20, Bm, bottom())
    group(f'{prefix}-center', 20, 20, center())

def maximized(prefix, st):
    piece = [f'<rect width="1" height="{TBM}" {rgba(st["base"])}/>',
             f'<rect width="1" height="{TBM}" fill="{grad("linear", [(0,"#fff",st["glow"]),(1,"#fff",0)], x1=0, y1=0, x2=0, y2=TBM)}"/>',
             f'<rect y="{TBM-1}" width="1" height="1" fill="#000" fill-opacity="{st["sep"]}"/>']
    for p in ('topleft','top','topright'):
        group(f'{prefix}-{p}', 1, TBM, piece)
    for p in ('left','right','bottomleft','bottom','bottomright','center'):
        group(f'{prefix}-{p}', 1, 1, [f'<rect width="1" height="1" {rgba(st["base"])}/>'])

body.append('<rect id="hint-stretch-borders" width="1" height="1" opacity="0"/>')
body.append('<rect id="hint-compose-over-border" x="2" width="1" height="1" opacity="0"/>')
# Custom titlebar color (Vidro Settings → Windows): ~/.config/vidrorc [Windows] titlebar=custom, titlebar_color=#rrggbb
COR_TEXTO = None
try:
    import configparser, re
    _c = configparser.RawConfigParser(); _c.read(os.path.join(os.environ.get('XDG_CONFIG_HOME', os.path.expanduser('~/.config')), 'vidrorc'))
    _cor = os.environ.get('VIDRO_TITLEBAR_COLOR') or (_c.get('Windows', 'titlebar_color', fallback='') if _c.get('Windows', 'titlebar', fallback='theme') == 'custom' else '')
    if re.fullmatch(r'#[0-9a-fA-F]{6}', _cor or ''):
        _r, _g, _b = (int(_cor[i:i+2], 16) for i in (1, 3, 5))
        for _k, _f in (('decoration', 1.0), ('decoration-inactive', 0.82)):
            _a = STATES[_k]['base'][5:-1].split(',')[3]
            STATES[_k]['base'] = f'rgba({round(_r*_f)},{round(_g*_f)},{round(_b*_f)},{_a})'
        _lum = (0.299*_r + 0.587*_g + 0.114*_b) / 255
        COR_TEXTO = ('28,28,32', '0,0,0,120') if _lum > 0.6 else ('235,235,240', '255,255,255,110')
except Exception:
    pass

frame('decoration', STATES['decoration'])
frame('decoration-inactive', STATES['decoration-inactive'])
frame('mask', STATES['decoration'], mask=True)
maximized('decoration-maximized', STATES['decoration'])
maximized('decoration-maximized-inactive', STATES['decoration-inactive'])

def svg(w, h, d, b):
    return f'<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>{"".join(d)}</defs>{"".join(b)}</svg>\n'
open(f'{OUT}/decoration.svg','w').write(svg(ox[0], T+60, defs, body))

# ---------- buttons ----------
# Style from ~/.config/vidrorc [Buttons] (Vidro Settings → Window buttons):
#   style = traffic | symbols (traffic lights with symbols) | graphite (gray, color on hover)
#           | outline (ring only) | icons (symbol only) | square (rounded square)
#   size = button radius (4-9), inactive = gray | color
#   color_mode = traffic | single (+ single_color) | custom (+ close_color, minimize_color, maximize_color)
#   symbols = auto (the style decides) | hover | always | never;  symbol_weight = 0.8-2.4
#   hover = style (the style's own hover) | brighten | glow (soft ring around the button) | none
BOT = {}
try:
    _b = configparser.RawConfigParser(); _b.read(os.path.join(os.environ.get('XDG_CONFIG_HOME', os.path.expanduser('~/.config')), 'vidrorc'))
    if _b.has_section('Buttons'): BOT = dict(_b.items('Buttons'))
except Exception:
    pass
STYLE = BOT.get('style', 'traffic')
try: RAD = max(4.0, min(9.0, float(BOT.get('size', '6.5'))))
except ValueError: RAD = 6.5
INACTIVE_COLOR = BOT.get('inactive', 'gray') == 'color'
BW = 20
COL = {'close': ('#ff5f57', '#e0443e', '#bf2f28'), 'minimize': ('#febc2e', '#dea123', '#b5801a'), 'maximize': ('#28c840', '#1aab29', '#128a1f')}
_single = BOT.get('single_color', '') if BOT.get('color_mode', 'traffic') == 'single' else ''
if re.fullmatch(r'#[0-9a-fA-F]{6}', _single or ''):
    _r, _g, _b2 = (int(_single[i:i+2], 16) for i in (1, 3, 5))
    _esc = lambda f: '#%02x%02x%02x' % (round(_r*f), round(_g*f), round(_b2*f))
    for k in COL: COL[k] = (_single, _esc(0.85), _esc(0.7))
if BOT.get('color_mode') == 'custom':
    for k in ('close', 'minimize', 'maximize'):
        v = BOT.get(f'{k}_color', '')
        if re.fullmatch(r'#[0-9a-fA-F]{6}', v or ''):
            _r, _g, _b2 = (int(v[i:i+2], 16) for i in (1, 3, 5))
            COL[k] = (v, '#%02x%02x%02x' % (round(_r*.85), round(_g*.85), round(_b2*.85)), '#%02x%02x%02x' % (round(_r*.7), round(_g*.7), round(_b2*.7)))
COL['restore'] = COL['maximize']
SYMBOLS = BOT.get('symbols', 'auto')
try: SYMBOL_W = max(0.8, min(2.4, float(BOT.get('symbol_weight', '1.3'))))
except ValueError: SYMBOL_W = 1.3
HOVER = BOT.get('hover', 'style')
LIGHT = MODE == 'light' or (COR_TEXTO is not None and COR_TEXTO[0].startswith('28'))
INK = '#1c1c20' if LIGHT else '#ececf0'        # symbol color without a colored circle
def _k(sc):  # scale the symbols (drawn for radius 6.5) to the button size
    f = RAD / 6.5
    return f'<g transform="translate(10,10) scale({f:.3f}) translate(-10,-10)">{sc}</g>'
GLYPH_D = {
  'close':    ('M7.6,7.6 L12.4,12.4 M12.4,7.6 L7.6,12.4', 'stroke'),
  'minimize': ('M7,10 H13', 'stroke'),
  'maximize': ('M7.3,12.7 V8.6 L11.4,12.7 Z M12.7,7.3 V11.4 L8.6,7.3 Z', 'fill'),
  'restore':  ('M9.6,10.4 H6.6 L9.6,13.4 Z M10.4,9.6 V6.6 L13.4,9.6 Z', 'fill'),
}
if STYLE == 'icons':  # Windows/GNOME-like symbols: a square to maximize
    GLYPH_D['maximize'] = ('M7.2,7.2 H12.8 V12.8 H7.2 Z', 'stroke')
    GLYPH_D['restore'] = ('M6.8,8.8 H11.2 V13.2 H6.8 Z M8.8,8.8 V6.8 H13.2 V11.2 H11.2', 'stroke')
DARK_GLYPH = {'close': '#4d0000', 'minimize': '#5a3a00', 'maximize': '#0a4a10', 'restore': '#0a4a10'}
def glyph(name, color, op=0.8, width=None):
    if SYMBOLS == 'never': return ''
    width = SYMBOL_W if width is None else width * SYMBOL_W / 1.3
    d, modo = GLYPH_D[name]
    if modo == 'stroke':
        return _k(f'<path d="{d}" stroke="{color}" stroke-opacity="{op}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    return _k(f'<path d="{d}" fill="{color}" fill-opacity="{op}"/>')
def shape(fill, extra=''):
    if STYLE == 'square':
        q = RAD * 2; return f'<rect x="{10-RAD}" y="{10-RAD}" width="{q}" height="{q}" rx="{RAD*0.38:.2f}" fill="{fill}" {extra}/>'
    return f'<circle cx="10" cy="10" r="{RAD}" fill="{fill}" {extra}/>'
for name, (c, ring, press) in COL.items():
    d = [f'<radialGradient id="shine" cx="10" cy="{10-RAD*0.45:.2f}" r="{RAD+0.5}" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>']
    def btn(id_, x, fill, hover=False, inactive=False, pressed=False):
        g = f'<g id="{id_}-center" transform="translate({x},0)"><rect width="{BW}" height="{BW}" fill="#000" opacity="0"/>'
        gray = inactive and not INACTIVE_COLOR
        if STYLE == 'icons':
            if hover or pressed:
                g += shape(c if name == 'close' else ('#000' if LIGHT else '#fff'), f'fill-opacity="{0.9 if name == "close" else 0.14}"')
            g += glyph(name, ('#fff' if (name == 'close' and (hover or pressed)) else INK), 0.45 if gray else 0.9, 1.4)
        elif STYLE == 'outline':
            col = (INACT_BTN[0] if gray else fill)
            if hover or pressed: g += shape(fill)
            else: g += shape('none', f'stroke="{col}" stroke-opacity="{0.45 if gray else 1}" stroke-width="1.4"').replace(f'r="{RAD}"', f'r="{RAD-0.7}"')
            if hover or pressed: g += glyph(name, DARK_GLYPH[name])
        elif STYLE == 'graphite' and not (hover or pressed):
            g += shape('#000' if LIGHT else '#fff', f'fill-opacity="{0.12 if gray else 0.28}" stroke="#000" stroke-opacity="0.3" stroke-width="0.6"')
            g += glyph(name, INK, 0.35 if gray else 0.75)
        elif gray:
            g += shape(INACT_BTN[0], f'fill-opacity="{INACT_BTN[1]}" stroke="#000" stroke-opacity="{INACT_BTN[2]}" stroke-width="0.6"')
            if STYLE == 'symbols': g += glyph(name, INK, 0.35)
        else:
            g += shape(fill, f'stroke="{ring}" stroke-width="0.6"') + shape('url(#shine)')
            if hover or pressed or STYLE == 'symbols': g += glyph(name, DARK_GLYPH[name])
        if SYMBOLS == 'always' and not (hover or pressed) and 'path d=' not in g.split('</rect>', 1)[-1]:
            g += glyph(name, INK if (gray or STYLE in ('graphite', 'icons')) else DARK_GLYPH[name], 0.4 if gray else 0.8)
        if SYMBOLS == 'hover' and not (hover or pressed):   # strip symbols from the resting state
            g = re.sub(r'<g transform="translate\(10,10\) scale\([^)]*\) translate\(-10,-10\)">.*?</g>', '', g)
        if hover and HOVER == 'glow' and not gray:
            g = g.replace(f'<rect width="{BW}" height="{BW}" fill="#000" opacity="0"/>',
                          f'<rect width="{BW}" height="{BW}" fill="#000" opacity="0"/><circle cx="10" cy="10" r="{min(9.8, RAD + 2.6):.2f}" fill="{fill}" fill-opacity="0.28"/>', 1)
        elif hover and HOVER == 'brighten' and not gray and STYLE != 'icons':
            g += shape('#ffffff', 'fill-opacity="0.16"')
        elif hover and HOVER == 'none':
            return btn(id_, x, fill, hover=False, inactive=inactive, pressed=False).replace('<g id="', '<g data-h="1" id="', 1)
        return g + '</g>'
    b = [btn('active', 0, c), btn('hover', 30, c, hover=True), btn('pressed', 60, press, pressed=True),
         btn('inactive', 90, c, inactive=True), btn('deactivated', 120, c, inactive=True),
         btn('hover-inactive', 150, c, hover=True), btn('pressed-inactive', 180, press, pressed=True)]
    open(f'{OUT}/{name}.svg','w').write(svg(200, BW, d, b))
print('ok', OUT)

import re
rc = f'{OUT}/Vidrorc'
if os.path.exists(rc):
    t = open(rc).read()
    act, ina = ('235,235,240', '255,255,255,110') if MODE == 'dark' else ('28,28,32', '0,0,0,120')
    if COR_TEXTO: act, ina = COR_TEXTO
    t = re.sub(r'^ActiveTextColor=.*$', 'ActiveTextColor=' + act, t, flags=re.M)
    t = re.sub(r'^InactiveTextColor=.*$', 'InactiveTextColor=' + ina, t, flags=re.M)
    _left = _right = None
    if True:  # no [Buttons] in vidrorc = Vidro default (left; close, minimize, maximize)
        _seq = 'XIA' if BOT.get('order', 'macos') == 'macos' else 'IAX'
        _menu = 'M' if BOT.get('menu', 'false') == 'true' else ''
        if BOT.get('side', 'left') == 'left': _left, _right = _seq, _menu
        else: _left, _right = _menu, _seq
    if _left is not None: t = re.sub(r'^LeftButtons=.*$', 'LeftButtons=' + _left, t, flags=re.M)
    if _right is not None: t = re.sub(r'^RightButtons=.*$', 'RightButtons=' + _right, t, flags=re.M)
    try: t = re.sub(r'^ButtonSpacing=.*$', 'ButtonSpacing=%d' % max(0, min(12, int(float(BOT.get('spacing', '2'))))), t, flags=re.M)
    except ValueError: pass
    for k, v in (('PaddingTop', PT), ('PaddingBottom', PB), ('PaddingLeft', PL), ('PaddingRight', PR)):
        t = re.sub(rf'^{k}=.*$', f'{k}={v}', t, flags=re.M)
    open(rc, 'w').write(t)
print('mode', MODE)
