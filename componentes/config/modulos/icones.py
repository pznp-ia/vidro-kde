"""Cor das pastas (ícones grandes do tema Vidro): escuro, grafite claro, cor de destaque ou cor escolhida.
Regera os ícones e troca o tema de ícones de ida e volta para os apps atualizarem na hora."""
import colorsys, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(__file__))
from _union import num, sim

GRUPO = 'Icones'
PADROES = {
    'ativo': 'true',       # false = pastas escuras originais
    'modo': 'grafite',     # escuro | grafite | destaque | cor
    'cor': '#7aa2d6',      # usada no modo "cor"
    'brilho': '50',        # 0 escuro … 100 claro
    'relevo': '45',        # diferença entre topo e base da pasta (degradê)
    'saturacao': '60',     # 0 cinza … 100 cor viva (modos destaque/cor)
    # arquivos (documentos)
    'doc_estilo': 'escuro',   # escuro | claro | colorido | plano
    'doc_rotulo': 'true',     # etiqueta com a extensão
    'doc_cores': 'tipo',      # tipo | unica | cinza
    'doc_cor': '#58a6ff',
    'doc_dobra': 'true',      # canto dobrado
    'doc_raio': '3',
    # barra lateral (Dolphin e diálogos)
    'lado_estilo': 'linha',   # linha | preenchido | colorido
    'lado_cor': '#d9dae0',
    'lado_traco': '1.3',
    'lado_tamanho': 'auto',   # tamanho dos ícones na lateral do Dolphin: auto | 16 | 22 | 32
}

DATA = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
TEMA = os.path.join(DATA, 'icons', 'Vidro')


def _hex(rgb):
    return '#%02x%02x%02x' % tuple(max(0, min(255, round(c * 255))) for c in rgb)


def _destaque():
    try:
        v = subprocess.run(['kreadconfig6', '--file', 'kdeglobals', '--group', 'Colors:Selection', '--key', 'BackgroundNormal'],
                           capture_output=True, text=True).stdout.strip()
        r, g, b = (int(x) / 255 for x in v.split(',')[:3])
        return r, g, b
    except Exception:
        return 0.24, 0.68, 0.91


def _cores(cfg):
    modo = cfg.get('modo', 'grafite')
    brilho = num(cfg, 'brilho', 0, 100, 50) / 100
    relevo = num(cfg, 'relevo', 0, 100, 45) / 100
    sat = num(cfg, 'saturacao', 0, 100, 60) / 100
    if modo == 'escuro':
        h, s, l = 0.64, 0.10, 0.10 + 0.20 * brilho
    elif modo == 'grafite':
        h, s, l = 0.63, 0.08, 0.28 + 0.40 * brilho
    else:
        if modo == 'destaque':
            r, g, b = _destaque()
        else:
            c = cfg.get('cor', '#7aa2d6').lstrip('#')
            r, g, b = (int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)) if len(c) == 6 else (0.48, 0.64, 0.84)
        h, l0, s0 = colorsys.rgb_to_hls(r, g, b)
        h, s, l = h, s0 * sat, 0.22 + 0.50 * brilho
    d = 0.04 + 0.16 * relevo
    def hls(l_):
        return _hex(colorsys.hls_to_rgb(h, max(0, min(1, l_)), s))
    frente1, frente2 = hls(l + d), hls(l - d)
    fundo1, fundo2 = hls(l - 0.05), hls(l - 0.05 - 2 * d)
    glifo = '#1c1d22' if l > 0.62 else '#eceef3'   # glifo escuro em pasta clara e vice-versa
    return frente1, frente2, fundo1, fundo2, glifo


def aplicar(cfg):
    fonte = os.path.join(TEMA, 'fonte')
    if not os.path.isfile(os.path.join(fonte, 'gerar-icones.py')):
        return
    env = dict(os.environ)
    if sim(cfg, 'ativo'):
        f1, f2, b1, b2, gl = _cores(cfg)
        env.update(VIDRO_PASTA_FRENTE1=f1, VIDRO_PASTA_FRENTE2=f2, VIDRO_PASTA_FUNDO1=b1,
                   VIDRO_PASTA_FUNDO2=b2, VIDRO_PASTA_GLIFO=gl)
    env.update(VIDRO_DOC_ESTILO=cfg.get('doc_estilo', 'escuro'),
               VIDRO_DOC_ROTULO='1' if sim(cfg, 'doc_rotulo') else '0',
               VIDRO_DOC_CORES=cfg.get('doc_cores', 'tipo'), VIDRO_DOC_COR=cfg.get('doc_cor', '#58a6ff'),
               VIDRO_DOC_DOBRA='1' if sim(cfg, 'doc_dobra') else '0', VIDRO_DOC_RAIO=str(num(cfg, 'doc_raio', 0, 10, 3)),
               VIDRO_LADO_ESTILO=cfg.get('lado_estilo', 'linha'), VIDRO_LADO_COR=cfg.get('lado_cor', '#d9dae0'),
               VIDRO_LADO_TRACO=str(num(cfg, 'lado_traco', 0.8, 2.2, 1.3)))
    tam = cfg.get('lado_tamanho', 'auto')
    if tam == 'auto':
        subprocess.run(['kwriteconfig6', '--file', 'dolphinrc', '--group', 'PlacesPanel', '--key', 'IconSize', '--delete'], capture_output=True)
    else:
        subprocess.run(['kwriteconfig6', '--file', 'dolphinrc', '--group', 'PlacesPanel', '--key', 'IconSize',
                        str(int(num(cfg, 'lado_tamanho', 16, 48, 22)))], capture_output=True)
    subprocess.run(['python3', '-I', os.path.join(fonte, 'gerar-icones.py'), TEMA,
                    os.path.join(fonte, 'places.txt'), os.path.join(fonte, 'mimes.txt')], env=env, capture_output=True)
    # os apps só relêem os ícones quando o tema muda: troca e volta
    outro = 'breeze-dark'
    for t in (outro, 'Vidro'):
        subprocess.run(['/usr/libexec/plasma-changeicons', t], capture_output=True)
        time.sleep(0.5)
