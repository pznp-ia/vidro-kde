#!/usr/bin/env python3
"""Gerador de cursores do Vidro (estúdio do cursor nas Configurações do Vidro).

Uso: python3 -I gerar-cursor.py <pasta-do-tema> [--so-svg]
Opções por variáveis de ambiente (todas opcionais):
  VIDRO_CUR_FORMA     classica | moderna | minima | triangulo     (forma da seta)
  VIDRO_CUR_FUNDO     cor de dentro (#rrggbb)
  VIDRO_CUR_CONTORNO  cor do contorno
  VIDRO_CUR_DESTAQUE  cor dos detalhes (espera, selos)
  VIDRO_CUR_BORDA     espessura do contorno (0-3, em px de 32)
  VIDRO_CUR_CANTOS    arredondamento (0-3)
  VIDRO_CUR_SOMBRA    sombra (0-100)
Gera cursors_scalable/ (SVG, usado pelo Plasma 6 no Wayland) e, sem --so-svg,
cursors/ (Xcursor, para apps X11), com os mesmos nomes e atalhos do Breeze."""
import io, json, math, os, re, struct, subprocess, sys

OUT = sys.argv[1]
SO_SVG = '--so-svg' in sys.argv
E = os.environ.get
FORMA = E('VIDRO_CUR_FORMA', 'moderna')
FUNDO = E('VIDRO_CUR_FUNDO', '#1d1e23')
CONT = E('VIDRO_CUR_CONTORNO', '#ffffff')
ACC = E('VIDRO_CUR_DESTAQUE', '#5b9cf5')
try: OW = max(0.0, min(3.0, float(E('VIDRO_CUR_BORDA', '1.3'))))
except ValueError: OW = 1.3
try: RD = max(0.0, min(3.0, float(E('VIDRO_CUR_CANTOS', '1'))))
except ValueError: RD = 1.0
try: SH = max(0.0, min(100.0, float(E('VIDRO_CUR_SOMBRA', '45')))) / 100
except ValueError: SH = 0.45
VERMELHO, VERDE = '#e5534b', '#3fb950'
BREEZE = '/usr/share/icons/breeze_cursors'

# ---------- peças ----------
# cada forma é uma lista de (tipo, dado): ('f', path) área preenchida; ('l', path, largura) linha;
# ('a', path) área na cor de destaque; ('al', path, largura) linha na cor de destaque; ('r', path, largura) linha vermelha
SETAS = {
    'classica': 'M6,4 L6,25.5 L11.2,20.6 L14.6,28.2 L18,26.7 L14.7,19.3 L21.6,19.1 Z',
    'moderna': 'M6.5,4 L6.5,24.5 L11.4,19.9 L14.4,26.6 L17,25.5 L14.1,18.9 L20.6,18.9 Z',
    'minima': 'M6,4 L6,22.5 L11.4,17.6 L19.3,17.6 Z',
    'triangulo': 'M6,4 L8.6,24.2 L12.8,16.8 L20.8,14.6 Z',
}
SETA = SETAS.get(FORMA, SETAS['moderna'])
HOT_SETA = (6.5, 4) if FORMA == 'moderna' else (6, 4)


def seta():
    return [('f', SETA)]


def selo(x, y, itens, cor=None):
    """Selo redondo no canto (copiar, atalho, proibido...)."""
    out = [('f', f'M{x-5},{y} a5,5 0 1,0 10,0 a5,5 0 1,0 -10,0 Z')]
    if cor:
        out.append(('c', f'M{x-4},{y} a4,4 0 1,0 8,0 a4,4 0 1,0 -8,0 Z', cor))
    return out + itens


def rot(itens, ang, cx=16, cy=16):
    return [('g', f'rotate({ang} {cx} {cy})', itens)]


def mao_apontando():
    return [('f', 'M11,5.6 a2.1,2.1 0 0 1 4.2,0 V17 H11 Z'),
            ('f', 'M15.2,12.4 a1.9,1.9 0 0 1 3.8,0 V18 H15.2 Z'),
            ('f', 'M19,13.3 a1.8,1.8 0 0 1 3.6,0 V18.5 H19 Z'),
            ('f', 'M22.6,14.6 a1.6,1.6 0 0 1 3.2,0 V20 H22.6 Z'),
            ('f', 'M11,15 H25.8 V22 C25.8,26.5 22.8,29 18.5,29 H15.5 C12.5,29 10.6,27.3 9.4,25 L6.6,19.6 '
                  'C6,18.4 6.4,17.2 7.5,16.7 C8.6,16.2 9.6,16.7 10.3,17.6 L11,18.6 Z'),
            ('d', 'M15.2,14 V17.5 M19,15 V18 M22.6,16 V19', 0.7)]


def mao_aberta():
    return [('f', 'M9.5,8.7 a1.7,1.7 0 0 1 3.4,0 V18 H9.5 Z'),
            ('f', 'M12.9,6.2 a1.7,1.7 0 0 1 3.4,0 V18 H12.9 Z'),
            ('f', 'M16.3,6.7 a1.7,1.7 0 0 1 3.4,0 V18 H16.3 Z'),
            ('f', 'M19.7,9.1 a1.6,1.6 0 0 1 3.2,0 V18.5 H19.7 Z'),
            ('f', 'M9.5,15 H22.9 V22 C22.9,26.5 20,29 16.5,29 H14 C11,29 9.5,27 8.5,25 L5.6,19.5 '
                  'C5,18.3 5.5,17 6.6,16.6 C7.6,16.2 8.6,16.7 9.2,17.6 Z'),
            ('d', 'M12.9,11 V17 M16.3,10 V17 M19.7,11.5 V17', 0.7)]


def mao_fechada():
    return [('f', 'M9.5,13.2 a1.7,1.7 0 0 1 3.4,0 V18 H9.5 Z'),
            ('f', 'M12.9,12.2 a1.7,1.7 0 0 1 3.4,0 V18 H12.9 Z'),
            ('f', 'M16.3,12.2 a1.7,1.7 0 0 1 3.4,0 V18 H16.3 Z'),
            ('f', 'M19.7,13.2 a1.6,1.6 0 0 1 3.2,0 V18.5 H19.7 Z'),
            ('f', 'M9.5,15.5 H22.9 V22 C22.9,26.5 20,29 16.5,29 H14 C11,29 9.5,27 8.5,25 L6.6,21 '
                  'C6,19.8 6.5,18.5 7.6,18.1 C8.6,17.7 9.2,18.2 9.5,18.6 Z'),
            ('d', 'M12.9,14 V17 M16.3,14 V17 M19.7,14.5 V17', 0.7)]


SETA_DUPLA = 'M4.5,16 L10.5,10.5 V14.2 H21.5 V10.5 L27.5,16 L21.5,21.5 V17.8 H10.5 V21.5 Z'
QUATRO = ('M16,3.5 L21,8.5 H17.8 V14.2 H23.5 V11 L28.5,16 L23.5,21 V17.8 H17.8 V23.5 H21 L16,28.5 L11,23.5 '
          'H14.2 V17.8 H8.5 V21 L3.5,16 L8.5,11 V14.2 H14.2 V8.5 H11 Z')
COLUNA = ('M3.5,16 L8.5,11.5 V14.3 H12.5 V8 H14.6 V24 H12.5 V17.7 H8.5 V20.5 Z '
          'M28.5,16 L23.5,11.5 V14.3 H19.5 V8 H17.4 V24 H19.5 V17.7 H23.5 V20.5 Z')
LADO = [('l', 'M9,5 H23', 2.2), ('f', 'M16,8 L21.5,13.5 H17.8 V26 H14.2 V13.5 H10.5 Z')]
CANTO = [('l', 'M5,14 V5 H14', 2.2), ('f', 'M7.5,7.5 H15.5 L12.8,10.2 L22.5,19.9 L19.9,22.5 L10.2,12.8 L7.5,15.5 Z')]
CRUZ = 'M13.5,5 H18.5 V13.5 H27 V18.5 H18.5 V27 H13.5 V18.5 H5 V13.5 H13.5 Z'
TEXTO = [('l', 'M16,8 V24', 1.7),
         ('l', 'M12.5,6 C14.5,6 16,6.6 16,8 C16,6.6 17.5,6 19.5,6', 1.7),
         ('l', 'M12.5,26 C14.5,26 16,25.4 16,24 C16,25.4 17.5,26 19.5,26', 1.7)]
LAPIS = [('f', 'M6,26 L7.6,19.8 L21.4,6 L26,10.6 L12.2,24.4 Z'), ('d', 'M7.6,19.8 L12.2,24.4 M19.2,8.2 L23.8,12.8', 0.9)]
CONTA_GOTAS = [('f', 'M5,27 L6.2,22.6 L17.2,11.6 L20.4,14.8 L9.4,25.8 Z'), ('f', 'M16,9.6 L22.2,15.8 L24.4,13.6 C26.5,11.5 26.5,8.5 24.4,6.4 '
               'C22.3,4.3 19.3,4.3 17.2,6.4 L15,8.6 Z')]


def lupa(sinal):
    out = [('l', 'M18.4,18.4 L26.5,26.5', 3.4), ('o', 'M6.5,13 a6.5,6.5 0 1,0 13,0 a6.5,6.5 0 1,0 -13,0 Z')]
    out.append(('dl', 'M10,13 H16' + (' M13,10 V16' if sinal == '+' else ''), 1.6))
    return out


def girador(frac, x=16, y=16, r=8.0, w=3.0):
    """Anel de espera com um arco de destaque na posição frac (0-1)."""
    a0 = frac * 2 * math.pi - math.pi / 2
    a1 = a0 + math.pi * 0.62
    p0 = (x + r * math.cos(a0), y + r * math.sin(a0)); p1 = (x + r * math.cos(a1), y + r * math.sin(a1))
    return [('l', f'M{x - r},{y} a{r},{r} 0 1,0 {2 * r},0 a{r},{r} 0 1,0 -{2 * r},0', w),
            ('al', f'M{p0[0]:.2f},{p0[1]:.2f} A{r},{r} 0 0,1 {p1[0]:.2f},{p1[1]:.2f}', w - 0.4)]


QUADROS = 12
FORMAS = {   # nome: (itens ou função(quadro), ponto quente)
    'default': (seta(), HOT_SETA),
    'right_ptr': ([('g', 'matrix(-1 0 0 1 32 0)', seta())], (32 - HOT_SETA[0], HOT_SETA[1])),
    'pointer': (mao_apontando(), (13.1, 3.5)),
    'openhand': (mao_aberta(), (16, 16)),
    'dnd-move': (mao_fechada(), (16, 16)),
    'text': (TEXTO, (16, 16)),
    'vertical-text': (rot(TEXTO, 90), (16, 16)),
    'crosshair': ([('l', 'M16,4 V12.5 M16,19.5 V28 M4,16 H12.5 M19.5,16 H28', 1.7), ('a', 'M14.8,16 a1.2,1.2 0 1,0 2.4,0 a1.2,1.2 0 1,0 -2.4,0 Z')], (16, 16)),
    'cell': ([('f', CRUZ)], (16, 16)),
    'x-cursor': (rot([('f', CRUZ)], 45), (16, 16)),
    'pirate': (rot([('f', CRUZ)], 45), (16, 16)),
    'fleur': ([('f', QUATRO)], (16, 16)),
    'all-scroll': ([('f', QUATRO)], (16, 16)),
    'size_hor': ([('f', SETA_DUPLA)], (16, 16)),
    'size_ver': (rot([('f', SETA_DUPLA)], 90), (16, 16)),
    'size_fdiag': (rot([('f', SETA_DUPLA)], 45), (16, 16)),
    'size_bdiag': (rot([('f', SETA_DUPLA)], -45), (16, 16)),
    'col-resize': ([('f', COLUNA)], (16, 16)),
    'row-resize': (rot([('f', COLUNA)], 90), (16, 16)),
    'top_side': (LADO, (16, 5)),
    'right_side': (rot(LADO, 90), (27, 16)),
    'bottom_side': (rot(LADO, 180), (16, 27)),
    'left_side': (rot(LADO, 270), (5, 16)),
    'top_left_corner': (CANTO, (5, 5)),
    'top_right_corner': (rot(CANTO, 90), (27, 5)),
    'bottom_right_corner': (rot(CANTO, 180), (27, 27)),
    'bottom_left_corner': (rot(CANTO, 270), (5, 27)),
    'up-arrow': ([('f', 'M16,4 L24,14 H18.5 V27 H13.5 V14 H8 Z')], (16, 4)),
    'center_ptr': ([('f', 'M16,4 L24,14 H18.5 V27 H13.5 V14 H8 Z')], (16, 4)),
    'right-arrow': (rot([('f', 'M16,4 L24,14 H18.5 V27 H13.5 V14 H8 Z')], 90), (28, 16)),
    'down-arrow': (rot([('f', 'M16,4 L24,14 H18.5 V27 H13.5 V14 H8 Z')], 180), (16, 28)),
    'left-arrow': (rot([('f', 'M16,4 L24,14 H18.5 V27 H13.5 V14 H8 Z')], 270), (4, 16)),
    'not-allowed': ([('r', 'M7,16 a9,9 0 1,0 18,0 a9,9 0 1,0 -18,0 M9.6,22.4 L22.4,9.6', 3)], (16, 16)),
    'no-drop': (seta() + selo(22, 23, [('r', 'M19.6,23 a2.4,2.4 0 1,0 4.8,0 a2.4,2.4 0 1,0 -4.8,0 M20.3,24.7 L23.7,21.3', 1.3)]), HOT_SETA),
    'dnd-no-drop': (seta() + selo(22, 23, [('r', 'M19.6,23 a2.4,2.4 0 1,0 4.8,0 a2.4,2.4 0 1,0 -4.8,0 M20.3,24.7 L23.7,21.3', 1.3)]), HOT_SETA),
    'copy': (seta() + selo(22, 23, [('wl', 'M19.6,23 H24.4 M22,20.6 V25.4', 1.6)], VERDE), HOT_SETA),
    'alias': (seta() + selo(22, 23, [('wl', 'M19.8,25 C19.8,22 21,21 23.8,21 M22.2,19.6 L23.9,21 L22.2,22.5', 1.3)], ACC), HOT_SETA),
    'context-menu': (seta() + [('f', 'M17.5,17 H27.5 V27.5 H17.5 Z'), ('dl', 'M19.5,20 H25.5 M19.5,22.3 H25.5 M19.5,24.6 H25.5', 1)], HOT_SETA),
    'help': (seta() + selo(22, 23, [('t', '?', 22, 25.6)], ACC), HOT_SETA),
    'zoom-in': (lupa('+'), (13, 13)),
    'zoom-out': (lupa('-'), (13, 13)),
    'pencil': (LAPIS, (6, 26)),
    'draft': (LAPIS, (6, 26)),
    'color-picker': (CONTA_GOTAS, (5, 27)),
    'wayland-cursor': (seta(), HOT_SETA),
    'wait': (lambda q: girador(q / QUADROS), (16, 16)),
    'progress': (lambda q: seta() + girador(q / QUADROS, 22.5, 23, 4.6, 2.4), HOT_SETA),
}


# ---------- desenho ----------
def _desenha(itens, camada):
    """camada: 'sombra' | 'contorno' | 'dentro'."""
    out = []
    larg_cont = 2 * OW + RD
    for it in itens:
        t = it[0]
        if t == 'g':
            out.append(f'<g transform="{it[1]}">{_desenha(it[2], camada)}</g>'); continue
        if t in ('f', 'o', 'c'):
            d = it[1]
            if camada in ('contorno', 'sombra'):
                if t == 'c': continue
                if t == 'o':
                    out.append(f'<path d="{d}" fill="none" stroke="{CONT}" stroke-width="{2.4 + 2 * OW:.2f}" stroke-linejoin="round"/>')
                else:
                    out.append(f'<path d="{d}" fill="{CONT}" stroke="{CONT}" stroke-width="{larg_cont:.2f}" stroke-linejoin="round"/>')
            else:
                if t == 'o':
                    out.append(f'<path d="{d}" fill="none" stroke="{FUNDO}" stroke-width="2.4" stroke-linejoin="round"/>')
                elif t == 'c':
                    out.append(f'<path d="{d}" fill="{it[2]}"/>')
                else:
                    extra = f' stroke="{FUNDO}" stroke-width="{RD:.2f}" stroke-linejoin="round"' if RD > 0 else ''
                    out.append(f'<path d="{d}" fill="{FUNDO}"{extra}/>')
        elif t in ('l', 'al', 'r', 'wl', 'dl'):
            d, w = it[1], it[2]
            if t in ('wl', 'dl') and camada != 'dentro':
                continue
            if camada in ('contorno', 'sombra'):
                out.append(f'<path d="{d}" fill="none" stroke="{CONT}" stroke-width="{w + 2 * OW:.2f}" stroke-linecap="round" stroke-linejoin="round"/>')
            else:
                cor = {'l': FUNDO, 'al': ACC, 'r': VERMELHO, 'wl': '#ffffff', 'dl': CONT}[t]
                out.append(f'<path d="{d}" fill="none" stroke="{cor}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>')
        elif t == 'a':
            if camada == 'dentro':
                out.append(f'<path d="{it[1]}" fill="{ACC}"/>')
            else:
                out.append(f'<path d="{it[1]}" fill="{CONT}" stroke="{CONT}" stroke-width="{2 * OW:.2f}"/>')
        elif t == 'd':  # divisões finas (entre dedos, lápis) na cor do contorno
            if camada == 'dentro':
                out.append(f'<path d="{it[1]}" fill="none" stroke="{CONT}" stroke-opacity=".55" stroke-width="{it[2]}" stroke-linecap="round"/>')
        elif t == 't':
            if camada == 'dentro':
                out.append(f'<text x="{it[2]}" y="{it[3]}" font-family="sans-serif" font-weight="700" font-size="7.5" '
                           f'text-anchor="middle" fill="#ffffff">{it[1]}</text>')
    return ''.join(out)


def svg(itens):
    partes = []
    if SH > 0:
        for i, (dy, op) in enumerate(((1.6, .10), (1.1, .14), (.6, .18))):
            partes.append(f'<g transform="translate(0 {dy})" opacity="{op * SH * 2:.3f}">'
                          + _desenha(itens, 'sombra').replace(f'"{CONT}"', '"#000000"') + '</g>')
    if OW > 0 or RD > 0:
        partes.append(_desenha(itens, 'contorno'))
    partes.append(_desenha(itens, 'dentro'))
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">'
            + ''.join(partes) + '</svg>\n')


# ---------- Xcursor ----------
TAMANHOS = (24, 32, 36, 48, 64, 72, 96)


def _png(svg_txt, px):
    r = subprocess.run(['magick', '-background', 'none', '-density', str(72 * px / 32), 'svg:-', '-resize', f'{px}x{px}!', 'png:-'],
                       input=svg_txt.encode(), capture_output=True)
    if r.returncode != 0 or not r.stdout:
        return None
    from PIL import Image
    return Image.open(io.BytesIO(r.stdout)).convert('RGBA')


def xcursor(quadros, hot, delay=50):
    """quadros: lista de textos SVG (1 = estático). Devolve bytes no formato Xcursor."""
    imgs = []
    for px in TAMANHOS:
        for q in quadros:
            im = _png(q, px)
            if im is None:
                continue
            # RGBA -> BGRA com cor multiplicada pelo alfa (= ARGB little-endian do Xcursor);
            # o modo 'La' do Pillow faz a multiplicação de cada canal pelo alfa
            from PIL import Image
            r_, g_, b_, a_ = im.split()
            r_, g_, b_ = (Image.merge('LA', (c, a_)).convert('La').split()[0] for c in (r_, g_, b_))
            dados = Image.merge('RGBA', (b_, g_, r_, a_)).tobytes()
            hx, hy = round(hot[0] * px / 32), round(hot[1] * px / 32)
            imgs.append((px, struct.pack('<9I', 36, 0xfffd0002, px, 1, px, px, min(hx, px - 1), min(hy, px - 1), delay) + bytes(dados)))
    n = len(imgs)
    cab = struct.pack('<4sIII', b'Xcur', 16, 0x10000, n)
    pos = 16 + 12 * n
    toc = b''
    for px, b in imgs:
        toc += struct.pack('<III', 0xfffd0002, px, pos); pos += len(b)
    return cab + toc + b''.join(b for _, b in imgs)


# ---------- montagem ----------
def main():
    esc = os.path.join(OUT, 'cursors_scalable'); xc = os.path.join(OUT, 'cursors')
    os.makedirs(esc, exist_ok=True)
    if not SO_SVG:
        os.makedirs(xc, exist_ok=True)
    for nome, (forma, hot) in FORMAS.items():
        d = os.path.join(esc, nome)
        if os.path.islink(d): os.remove(d)
        os.makedirs(d, exist_ok=True)
        for f in os.listdir(d): os.remove(os.path.join(d, f))
        if callable(forma):
            textos = [svg(forma(q)) for q in range(QUADROS)]
            meta = []
            for i, t in enumerate(textos):
                fn = f'{nome}-{i + 1:02d}.svg'
                open(os.path.join(d, fn), 'w').write(t)
                meta.append({'filename': fn, 'hotspot_x': hot[0], 'hotspot_y': hot[1], 'nominal_size': 32, 'delay': 60})
        else:
            textos = [svg(forma)]
            open(os.path.join(d, f'{nome}.svg'), 'w').write(textos[0])
            meta = [{'filename': f'{nome}.svg', 'hotspot_x': hot[0], 'hotspot_y': hot[1], 'nominal_size': 32}]
        json.dump(meta, open(os.path.join(d, 'metadata.json'), 'w'), indent=1)
        if not SO_SVG:
            p = os.path.join(xc, nome)
            if os.path.islink(p): os.remove(p)
            open(p, 'wb').write(xcursor(textos, hot, 60))
    # atalhos: os mesmos nomes do Breeze (relativos, para funcionar em flatpak)
    for sub in (('cursors_scalable', esc),) + ((('cursors', xc),) if not SO_SVG else ()):
        base = os.path.join(BREEZE, sub[0])
        if not os.path.isdir(base):
            continue
        for n in os.listdir(base):
            src = os.path.join(base, n)
            if not os.path.islink(src) or n in FORMAS:
                continue
            alvo = os.path.basename(os.readlink(src))
            if alvo not in FORMAS:
                alvo = 'default'
            p = os.path.join(sub[1], n)
            if os.path.lexists(p):
                if os.path.islink(p) or os.path.isfile(p): os.remove(p)
                else: continue
            os.symlink(alvo, p)
    open(os.path.join(OUT, 'index.theme'), 'w').write(
        '[Icon Theme]\nName=Vidro (cursor)\nComment=Cursor feito no estúdio das Configurações do Vidro\nInherits=breeze_cursors\n')
    print('ok', len(FORMAS), 'cursores', '(só SVG)' if SO_SVG else '(SVG + Xcursor)')


if __name__ == '__main__':
    main()
