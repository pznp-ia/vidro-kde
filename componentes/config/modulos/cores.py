"""Cores: cor de destaque (seleção, foco, realce — ex.: pasta selecionada no Dolphin) e cor da fonte.
Mexe no esquema de cores "Vidro" (e no kdeglobals quando ele está ativo); os apps abertos mudam na hora.
Os valores originais ficam em ~/.local/share/vidro/cores-original.json e voltam ao desligar."""
import json, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(__file__))
from _union import num, sim

GRUPO = 'Cores'
PADROES = {
    'destaque': 'tema',        # tema | cor
    'cor_destaque': '#3daee9',
    'forca': '100',            # 0-100: força da cor na seleção (menos = seleção mais discreta)
    'fonte': 'tema',           # tema | cor
    'cor_fonte': '#fcfcfc',
    'secundario': '41',        # 0-80: quanto o texto secundário fica apagado
}

DATA = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
ESQUEMA = os.path.join(DATA, 'color-schemes', 'Vidro.colors')
ORIG = os.path.join(DATA, 'vidro', 'cores-original.json')
GRUPOS = ['Colors:Button', 'Colors:Complementary', 'Colors:Header', 'Colors:Header][Inactive', 'Colors:Selection',
          'Colors:Tooltip', 'Colors:View', 'Colors:Window']
CHAVES = ['BackgroundNormal', 'BackgroundAlternate', 'DecorationFocus', 'DecorationHover', 'ForegroundNormal', 'ForegroundInactive']


def _ler(arq, g, k):
    return subprocess.run(['kreadconfig6', '--file', arq] + _grp(g) + ['--key', k], capture_output=True, text=True).stdout.strip()


def _grp(g):
    # "Colors:Header][Inactive" = grupo aninhado
    return sum((['--group', x] for x in g.split('][')), [])


def _rgb(t):
    return [int(x) for x in t.split(',')[:3]]


def _txt(c):
    return ','.join(str(max(0, min(255, round(v)))) for v in c)


def _mix(a, b, t):
    return [x + (y - x) * t for x, y in zip(a, b)]


def _hex(h, padrao):
    return [int(h[i:i + 2], 16) for i in (1, 3, 5)] if re.fullmatch(r'#[0-9a-fA-F]{6}', h or '') else padrao


def _originais():
    if os.path.exists(ORIG):
        return json.load(open(ORIG))
    d = {g: {k: _ler(ESQUEMA, g, k) for k in CHAVES} for g in GRUPOS}
    os.makedirs(os.path.dirname(ORIG), exist_ok=True)
    json.dump(d, open(ORIG, 'w'), indent=1)
    return d


def aplicar(cfg):
    if not os.path.exists(ESQUEMA):
        return
    o = _originais()
    novo = {g: dict(v) for g, v in o.items()}
    sel0 = _rgb(o['Colors:Selection']['BackgroundNormal'])            # destaque original
    alt0 = _rgb(o['Colors:Selection']['BackgroundAlternate'])
    # ---- cor de destaque ----
    if cfg.get('destaque', 'tema') == 'cor':
        a = _hex(cfg.get('cor_destaque'), sel0)
        forca = num(cfg, 'forca', 0, 100, 100) / 100
        fundo = _rgb(o['Colors:View']['BackgroundNormal'])
        sel = _mix(fundo, a, max(0.25, forca))
        alt = _mix(fundo, a, max(0.15, forca) * 0.5)
        lum = (0.299 * sel[0] + 0.587 * sel[1] + 0.114 * sel[2]) / 255
        for g in GRUPOS:
            for k in CHAVES:
                v = o[g][k]
                if not v:
                    continue
                if _rgb(v) == sel0 and k in ('DecorationFocus', 'DecorationHover', 'BackgroundNormal'):
                    novo[g][k] = _txt(a if k != 'BackgroundNormal' else sel)
                elif _rgb(v) == alt0 and k == 'BackgroundAlternate':
                    novo[g][k] = _txt(alt)
        novo['Colors:Selection']['ForegroundNormal'] = '20,20,24' if lum > 0.62 else '252,252,252'
    # ---- cor da fonte ----
    if cfg.get('fonte', 'tema') == 'cor':
        f = _hex(cfg.get('cor_fonte'), [252, 252, 252])
        sec = num(cfg, 'secundario', 0, 80, 41) / 100
        for g in GRUPOS:
            if g == 'Colors:Selection':
                continue
            fundo = _rgb(o[g]['BackgroundNormal'] or '32,35,38')
            novo[g]['ForegroundNormal'] = _txt(f)
            novo[g]['ForegroundInactive'] = _txt(_mix(f, fundo, sec))
    # ---- grava no esquema e, se ele estiver ativo, no kdeglobals (avisa os apps só no fim) ----
    ativo = _ler('kdeglobals', 'General', 'ColorScheme') == 'Vidro'
    def minha(g, k):  # chaves deste módulo (o fundo das listas é do módulo do Dolphin)
        if k in ('DecorationFocus', 'DecorationHover', 'ForegroundNormal', 'ForegroundInactive'):
            return True
        if g == 'Colors:Selection':
            return True
        return k == 'BackgroundAlternate' and o[g][k] and _rgb(o[g][k]) == alt0
    muda = [(g, k, v) for g in GRUPOS for k, v in novo[g].items() if v and minha(g, k)]
    for i, (g, k, v) in enumerate(muda):
        subprocess.run(['kwriteconfig6', '--file', ESQUEMA] + _grp(g) + ['--key', k, v])
        if ativo:
            extra = ['--notify'] if i == len(muda) - 1 else []
            subprocess.run(['kwriteconfig6'] + extra + ['--file', 'kdeglobals'] + _grp(g) + ['--key', k, v])
