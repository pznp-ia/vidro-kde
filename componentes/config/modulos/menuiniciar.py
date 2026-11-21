"""Menu iniciar e pop-ups do Plasma (estilo do Plasma "Vidro"):
fundo de vidro com cantos ajustáveis + sombra gaussiana combinando (dialogs/background)
e cabeçalho/rodapé sem linhas (widgets/plasmoidheading). Vale para todos os pop-ups do painel
(menu iniciar, relógio, bandeja...). Modelos originais em ~/.local/share/vidro/modelos."""
import gzip, math, os, re, subprocess, sys, time
sys.path.insert(0, os.path.dirname(__file__))
from _union import num, sim

GRUPO = 'MenuIniciar'
PADROES = {
    'ativo': 'true',      # false = pop-ups como eram (modelos originais)
    'raio': '14',         # cantos (px)
    'fundo': 'tema',      # tema | cor
    'cor_vidro': '#1c1e24',  # cor do vidro quando fundo = cor
    'opacidade': '80',    # fundo (%)
    'borda': '10',        # contorno fino (%)
    'linhas': '0',        # linhas do cabeçalho/rodapé (%)
    'cabecalho': '0',     # fundo próprio do cabeçalho/rodapé (%) — 0 = contínuo com o resto
    'sombra': '55',       # força da sombra (%)
    'tamanho': '18',      # tamanho da sombra (px)
}

DATA = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
TEMA = os.path.join(DATA, 'plasma', 'desktoptheme', 'Vidro')
MODELOS = os.path.join(DATA, 'vidro', 'modelos')


def _gz(path, texto):
    with gzip.open(path, 'wb') as f:
        f.write(texto.encode())


def _dialogo(R, op, borda, forca, S, cor=None, margem=None):
    """SVG 9-partes (frame + máscara de desfoque + sombra) com cantos de raio R."""
    R = max(2, R); C = R                    # tamanho dos cantos do frame
    St, Ss, Sb = max(4, round(S * 0.7)), S, max(6, round(S * 1.3))
    sig = max(2.0, S / 2.6)
    defs, body = [], []
    gid = [0]
    ox = [0]

    def grupo(id_, w, h, itens):
        x0 = ox[0]; ox[0] += w + 8
        body.append(f'<g id="{id_}" transform="translate({x0},0)"><rect width="{w}" height="{h}" fill="#000" opacity="0"/>{"".join(itens)}</g>')

    def espelhos(nome, w, h, fn):
        """fn(w,h) desenha o canto de cima-esquerda; gera os 4 cantos por espelhamento."""
        out = {}
        for k, m in (('topleft', '1,0,0,1,0,0'), ('topright', f'-1,0,0,1,{w},0'),
                     ('bottomleft', f'1,0,0,-1,0,{h}'), ('bottomright', f'-1,0,0,-1,{w},{h}')):
            out[k] = [f'<g transform="matrix({m})">{"".join(fn())}</g>']
        return out

    fundo = (f'fill="{cor}" fill-opacity="{op:.3f}"' if cor else
             f'class="ColorScheme-Background" fill="currentColor" fill-opacity="{op:.3f}"')
    linha = f'class="ColorScheme-Text" fill="currentColor" fill-opacity="{borda:.3f}"'

    # ---- frame ----
    def canto():
        it = [f'<path {fundo} d="M0,{C}A{R},{R} 0 0 1 {R},0H{C}V{C}Z"/>']
        if borda > 0:
            it.append(f'<path {linha} fill-rule="evenodd" d="M0,{C}A{R},{R} 0 0 1 {R},0V1A{R-1},{R-1} 0 0 0 1,{C}Z"/>')
        return it
    for k, v in espelhos('frame', C, C, canto).items():
        grupo(k, C, C, v)
    L = 16
    def lado(horiz, inicio):
        w, h = (L, C) if horiz else (C, L)
        it = [f'<rect {fundo} width="{w}" height="{h}"/>']
        if borda > 0:
            if horiz:
                it.append(f'<rect {linha} y="{0 if inicio else C-1}" width="{w}" height="1"/>')
            else:
                it.append(f'<rect {linha} x="{0 if inicio else C-1}" width="1" height="{h}"/>')
        return w, h, it
    for k, hz, ini in (('top', 1, 1), ('bottom', 1, 0), ('left', 0, 1), ('right', 0, 0)):
        w, h, it = lado(hz, ini); grupo(k, w, h, it)
    grupo('center', L, L, [f'<rect {fundo} width="{L}" height="{L}"/>'])

    # margens do conteúdo
    m = margem if margem is not None else max(4, round(R * 0.5))
    for k in ('top', 'bottom', 'left', 'right'):
        grupo(f'hint-{k}-margin', m, m, [])

    # ---- máscara (região do desfoque) ----
    preto = 'fill="#000"'
    def canto_m():
        return [f'<path {preto} d="M0,{C}A{R},{R} 0 0 1 {R},0H{C}V{C}Z"/>']
    for k, v in espelhos('mask', C, C, canto_m).items():
        grupo(f'mask-{k}', C, C, v)
    for k in ('top', 'bottom'):
        grupo(f'mask-{k}', L, C, [f'<rect {preto} width="{L}" height="{C}"/>'])
    for k in ('left', 'right'):
        grupo(f'mask-{k}', C, L, [f'<rect {preto} width="{C}" height="{L}"/>'])
    grupo('mask-center', L, L, [f'<rect {preto} width="{L}" height="{L}"/>'])

    # ---- sombra (perfil gaussiano, cantos coerentes com as laterais) ----
    def pr(d):
        return forca * math.exp(-(max(0.0, d) ** 2) / (2 * sig * sig))

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

    # cantos da sombra: (lado x, lado y) de margem; a janela ocupa o canto interno com raio R
    def canto_sombra(nome, mx, my):
        w, h = mx + R, my + R
        cx, cy = w, h  # centro do arco da janela = canto interno do quadro
        janela = f'M{mx},{h}V{my+R}A{R},{R} 0 0 1 {mx+R},{my}H{w}V{h}Z'
        it = [f'<path fill="{rad(cx, cy, R, R + max(mx, my) + 2)}" fill-rule="evenodd" d="M0,0H{w}V{h}H0Z {janela}"/>']
        return w, h, it
    for k, mx, my, m_ in (('topleft', Ss, St, '1,0,0,1,0,0'), ('topright', Ss, St, None),
                          ('bottomleft', Ss, Sb, None), ('bottomright', Ss, Sb, None)):
        w, h, it = canto_sombra(k, mx, my)
        if k == 'topright':
            it = [f'<g transform="matrix(-1,0,0,1,{w},0)">{"".join(it)}</g>']
        elif k == 'bottomleft':
            it = [f'<g transform="matrix(1,0,0,-1,0,{h})">{"".join(it)}</g>']
        elif k == 'bottomright':
            it = [f'<g transform="matrix(-1,0,0,-1,{w},{h})">{"".join(it)}</g>']
        grupo(f'shadow-{k}', w, h, it)
    grupo('shadow-top', L, St, [f'<rect fill="{lin(0, St, 0, 0, 0, St)}" width="{L}" height="{St}"/>'])
    grupo('shadow-bottom', L, Sb, [f'<rect fill="{lin(0, 0, 0, Sb, 0, Sb)}" width="{L}" height="{Sb}"/>'])
    grupo('shadow-left', Ss, L, [f'<rect fill="{lin(Ss, 0, 0, 0, 0, Ss)}" width="{Ss}" height="{L}"/>'])
    grupo('shadow-right', Ss, L, [f'<rect fill="{lin(0, 0, Ss, 0, 0, Ss)}" width="{Ss}" height="{L}"/>'])
    grupo('shadow-center', L, L, [])
    for k, v in (('top', St), ('bottom', Sb), ('left', Ss), ('right', Ss)):
        grupo(f'shadow-hint-{k}-margin', v, v, [])

    estilo = ('<style type="text/css" id="current-color-scheme">'
              '.ColorScheme-Text{color:#232629;}.ColorScheme-Background{color:#eff0f1;}</style>')
    return (f'<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="{ox[0]}" height="{max(C, Sb + R, L) + 8}">'
            f'<defs>{estilo}{"".join(defs)}</defs>{"".join(body)}</svg>\n')


def _cabecalho(linhas, fundo):
    s = open(os.path.join(MODELOS, 'plasmoidheading.svg')).read()
    # linhas (ColorScheme-Frame) e fundo (ColorScheme-Background) com opacidade ajustável
    s = re.sub(r'class="ColorScheme-Frame"', f'class="ColorScheme-Frame" opacity="{linhas:.3f}"', s)
    s = re.sub(r'class="ColorScheme-Background"', f'class="ColorScheme-Background" opacity="{fundo:.3f}"', s)
    return s


def _recarregar():
    # apaga o cache de imagens do estilo (senão o Plasma reaproveita o SVG antigo) e troca de estilo ida e volta
    cache = os.path.expanduser('~/.cache')
    for f in os.listdir(cache):
        if f.startswith('plasma_theme_Vidro') or f.startswith('ksvg-elements') or f.startswith('plasma-svgelements'):
            try: os.remove(os.path.join(cache, f))
            except OSError: pass
    for t in ('breeze-dark', 'Vidro'):
        subprocess.run(['plasma-apply-desktoptheme', t], capture_output=True)
        time.sleep(0.4)


def aplicar(cfg):
    if not os.path.isdir(TEMA) or not os.path.isfile(os.path.join(MODELOS, 'dialogs-background.svg')):
        return
    # o Plasma usa translucent/dialogs quando há desfoque (o normal); dialogs/ só sem efeitos
    trans = os.path.join(TEMA, 'translucent', 'dialogs', 'background.svgz')
    mod_trans = os.path.join(MODELOS, 'translucent-dialogs-background.svg')
    if not sim(cfg, 'ativo'):
        _gz(os.path.join(TEMA, 'dialogs', 'background.svgz'), open(os.path.join(MODELOS, 'dialogs-background.svg')).read())
        if os.path.isfile(mod_trans) and os.path.isdir(os.path.dirname(trans)):
            _gz(trans, open(mod_trans).read())
        _gz(os.path.join(TEMA, 'widgets', 'plasmoidheading.svgz'), open(os.path.join(MODELOS, 'plasmoidheading.svg')).read())
    else:
        R = int(num(cfg, 'raio', 2, 30, 14))
        op = num(cfg, 'opacidade', 30, 100, 80) / 100
        borda = num(cfg, 'borda', 0, 60, 10) / 100
        forca = num(cfg, 'sombra', 0, 100, 55) / 100 * 0.5
        S = int(num(cfg, 'tamanho', 4, 40, 18))
        cor = cfg.get('cor_vidro', '#1c1e24') if cfg.get('fundo', 'tema') == 'cor' else None
        if cor and not re.fullmatch(r'#[0-9a-fA-F]{6}', cor):
            cor = None
        svg = _dialogo(R, op, borda, forca, S, cor)
        _gz(os.path.join(TEMA, 'dialogs', 'background.svgz'), svg)
        if os.path.isdir(os.path.dirname(trans)):
            _gz(trans, svg)
        _gz(os.path.join(TEMA, 'widgets', 'plasmoidheading.svgz'),
            _cabecalho(num(cfg, 'linhas', 0, 100, 0) / 100, num(cfg, 'cabecalho', 0, 100, 0) / 100))
    _recarregar()
