"""Botões das janelas (decoração Vidro): lado, ordem, botão de menu, estilo, tamanho, espaço e cores.
O desenho é feito pelo gerar-vidro.py (lê o grupo [Botoes] do vidrorc); a ordem também vai para o kwinrc."""
import json, os, subprocess

GRUPO = 'Botoes'
PADROES = {
    'posicao': 'esquerda',     # esquerda | direita
    'ordem': 'macos',          # macos (fechar, minimizar, maximizar) | windows (minimizar, maximizar, fechar)
    'menu': 'false',           # botão do menu da janela no outro lado
    'estilo': 'semaforo',      # semaforo | simbolos | grafite | contorno | icones | quadrado
    'tamanho': '6.5',          # raio (4-9)
    'espaco': '2',             # px entre os botões
    'inativos': 'cinza',       # cinza | cor (janelas inativas)
    'cor': 'semaforo',         # semaforo | unica
    'cor_unica': '#8ab4f8',
}
_ULTIMA = os.path.expanduser('~/.cache/vidro/botoes')


def _kwin(cfg):
    seq = 'XIA' if cfg.get('ordem') == 'macos' else 'IAX'
    menu = 'M' if cfg.get('menu') == 'true' else ''
    esq, dir_ = (seq, menu) if cfg.get('posicao') == 'esquerda' else (menu, seq)
    for k, v in (('ButtonsOnLeft', esq), ('ButtonsOnRight', dir_)):
        subprocess.run(['kwriteconfig6', '--file', 'kwinrc', '--group', 'org.kde.kdecoration2', '--key', k, v])


def aplicar(cfg):
    chave = json.dumps({k: cfg.get(k) for k in PADROES}, sort_keys=True)
    try:
        if open(_ULTIMA).read() == chave:
            return
    except OSError:
        pass
    _kwin(cfg)
    # refaz a decoração (lê [Botoes] do vidrorc) e recarrega o KWin
    subprocess.run([os.path.expanduser('~/.local/bin/vidro-cor-titulo'), '--force'], capture_output=True)
    os.makedirs(os.path.dirname(_ULTIMA), exist_ok=True)
    open(_ULTIMA, 'w').write(chave)
