import os, sys, math
OUT = sys.argv[1]
MODE = sys.argv[2] if len(sys.argv) > 2 else 'escuro'   # 'escuro' ou 'claro'
os.makedirs(OUT, exist_ok=True)

PL = PR = 26; PT = 20; PB = 34     # padding (espaço da sombra)
SIG, DY = 9, 6                     # desfoque (sigma) e deslocamento p/ baixo da sombra
RB = 6                             # raio da sombra nos cantos de baixo
R = 12                             # raio dos cantos superiores
TB = 32                            # altura total da barra de título
TBM = 28                           # barra maximizada
L = PL + R; T = PT + TB; Bm = PB + 2; yb = Bm - PB

STATES = {
  'decoration': dict(base='rgba(38,40,48,0.50)', hl=0.28, glow=0.12, outline=0.55, sh=0.70, sep=0.30),
  'decoration-inactive': dict(base='rgba(30,31,36,0.38)', hl=0.14, glow=0.05, outline=0.40, sh=0.38, sep=0.18),
} if MODE == 'escuro' else {
  'decoration': dict(base='rgba(246,246,250,0.55)', hl=0.70, glow=0.25, outline=0.28, sh=0.50, sep=0.12),
  'decoration-inactive': dict(base='rgba(236,236,242,0.42)', hl=0.45, glow=0.12, outline=0.20, sh=0.28, sep=0.08),
}
INACT_BTN = ('#fff', 0.16, 0.35) if MODE == 'escuro' else ('#000', 0.14, 0.18)
def rgba(s):  # "rgba(r,g,b,a)" -> fill + fill-opacity
    r,g,b,a = s[5:-1].split(','); return f'fill="rgb({r},{g},{b})" fill-opacity="{a}"'

defs = []; body = []; gid = [0]
def grad(kind, stops, **attrs):
    gid[0] += 1; i = f'g{gid[0]}'
    st = ''.join(f'<stop offset="{o}" stop-color="{c}" stop-opacity="{a}"/>' for o,c,a in stops)
    at = ' '.join(f'{k}="{v}"' for k,v in attrs.items())
    defs.append(f'<{kind}Gradient id="{i}" gradientUnits="userSpaceOnUse" {at}>{st}</{kind}Gradient>')
    return f'url(#{i})'
# Sombra = retângulo da janela deslocado DY p/ baixo e desfocado (perfil gaussiano).
# d = distância (com sinal) até a borda desse retângulo; todas as peças usam o mesmo perfil,
# então cantos e laterais se encaixam sem emenda.
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
# NOTE: KSvg mede elementos incluindo o transform proprio do grupo, entao usamos translate.

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
frame('decoration', STATES['decoration'])
frame('decoration-inactive', STATES['decoration-inactive'])
frame('mask', STATES['decoration'], mask=True)
maximized('decoration-maximized', STATES['decoration'])
maximized('decoration-maximized-inactive', STATES['decoration-inactive'])

def svg(w, h, d, b):
    return f'<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>{"".join(d)}</defs>{"".join(b)}</svg>\n'
open(f'{OUT}/decoration.svg','w').write(svg(ox[0], T+60, defs, body))

# ---------- botões estilo semáforo ----------
BW = 20; RAD = 6.5
COL = {'close': ('#ff5f57', '#e0443e', '#bf2f28'), 'minimize': ('#febc2e', '#dea123', '#b5801a'), 'maximize': ('#28c840', '#1aab29', '#128a1f')}
COL['restore'] = COL['maximize']
GLYPH = {
  'close':    '<path d="M7.6,7.6 L12.4,12.4 M12.4,7.6 L7.6,12.4" stroke="#4d0000" stroke-opacity="0.75" stroke-width="1.3" stroke-linecap="round" fill="none"/>',
  'minimize': '<path d="M7,10 H13" stroke="#5a3a00" stroke-opacity="0.8" stroke-width="1.4" stroke-linecap="round" fill="none"/>',
  'maximize': '<path d="M7.3,12.7 V8.6 L11.4,12.7 Z M12.7,7.3 V11.4 L8.6,7.3 Z" fill="#0a4a10" fill-opacity="0.8"/>',
  'restore':  '<path d="M9.6,10.4 H6.6 L9.6,13.4 Z M10.4,9.6 V6.6 L13.4,9.6 Z" fill="#0a4a10" fill-opacity="0.8"/>',
}
for name, (c, ring, press) in COL.items():
    d = [f'<radialGradient id="shine" cx="10" cy="7" r="7" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#fff" stop-opacity="0.35"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></radialGradient>']
    def btn(id_, x, fill, glyph=False, inactive=False):
        g = f'<g id="{id_}-center" transform="translate({x},0)"><rect width="{BW}" height="{BW}" fill="#000" opacity="0"/>'
        if inactive:
            g += f'<circle cx="10" cy="10" r="{RAD}" fill="{INACT_BTN[0]}" fill-opacity="{INACT_BTN[1]}" stroke="#000" stroke-opacity="{INACT_BTN[2]}" stroke-width="0.6"/>'
        else:
            g += f'<circle cx="10" cy="10" r="{RAD}" fill="{fill}" stroke="{ring}" stroke-width="0.6"/><circle cx="10" cy="10" r="{RAD}" fill="url(#shine)"/>'
            if glyph: g += GLYPH[name]
        return g + '</g>'
    b = [btn('active', 0, c), btn('hover', 30, c, True), btn('pressed', 60, press, True),
         btn('inactive', 90, c, inactive=True), btn('deactivated', 120, c, inactive=True),
         btn('hover-inactive', 150, c, True), btn('pressed-inactive', 180, press, True)]
    open(f'{OUT}/{name}.svg','w').write(svg(200, BW, d, b))
print('ok', OUT)

import re
rc = f'{OUT}/Vidrorc'
if os.path.exists(rc):
    t = open(rc).read()
    act, ina = ('235,235,240', '255,255,255,110') if MODE == 'escuro' else ('28,28,32', '0,0,0,120')
    t = re.sub(r'^ActiveTextColor=.*$', 'ActiveTextColor=' + act, t, flags=re.M)
    t = re.sub(r'^InactiveTextColor=.*$', 'InactiveTextColor=' + ina, t, flags=re.M)
    for k, v in (('PaddingTop', PT), ('PaddingBottom', PB), ('PaddingLeft', PL), ('PaddingRight', PR)):
        t = re.sub(rf'^{k}=.*$', f'{k}={v}', t, flags=re.M)
    open(rc, 'w').write(t)
print('modo', MODE)
