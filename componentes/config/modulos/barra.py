"""Barra de rolagem dos apps (estilo Union "vidro")."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _union import escrever_css, hex_rgba, num, sim

GRUPO = 'Barra'
PADROES = {
    'ativo': 'true',        # false = barra padrão do Breeze/Union
    'modo': 'vidro',        # neon-fino | vidro | cor
    'largura': '6',         # espessura da alça, px
    'opacidade': '45',      # 0-100, alça em repouso
    'realce': '80',         # 0-100, alça ao passar o mouse / arrastar
    'arredondamento': '100',# 0-100 (% de meia largura)
    'trilho': 'false',      # mostrar o trilho
    'cor': '#8ab4f8',       # cor do modo "cor"
    'sobreposta': 'true',   # barra por cima do conteúdo, transparente de verdade (plugin libvidroscroll; vale no próximo login)
    'some': 'true',         # some quando parada (só com sobreposta)
    'espera': '1200',       # ms parada até sumir
    'minima': '0',          # % de opacidade quando sumida
}

ENV = os.path.expanduser('~/.config/plasma-workspace/env/vidro-barra.sh')
PLUGIN = os.path.expanduser('~/.local/share/vidro/qtplugins')

def _sessao(ligar):
    """Script de sessão que faz os apps do KDE carregarem o plugin da barra sobreposta (vale no próximo login)."""
    if ligar and os.path.isfile(os.path.join(PLUGIN, 'styles', 'libvidroscroll.so')):
        os.makedirs(os.path.dirname(ENV), exist_ok=True)
        with open(ENV, 'w') as f:
            f.write('# Vidro: barra de rolagem sobreposta (plugin de estilo que envolve o Union). Gerado por vidro-config.\n'
                    f'export QT_PLUGIN_PATH="{PLUGIN}${{QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}}"\n')
    elif os.path.exists(ENV):
        os.remove(ENV)

def aplicar(cfg):
    _sessao(sim(cfg, 'ativo') and sim(cfg, 'sobreposta'))
    if not sim(cfg, 'ativo'):
        escrever_css('barra', '/* desligado: barra padrão */\n'); return
    modo = cfg.get('modo', 'vidro')
    w = int(num(cfg, 'largura', 2, 16, 6))
    op = num(cfg, 'opacidade', 0, 100, 45) / 100
    hi = num(cfg, 'realce', 0, 100, 80) / 100
    raio = round(w / 2 * num(cfg, 'arredondamento', 0, 100, 100) / 100, 1)
    pad = 3
    total = w + 2 * pad
    if modo == 'neon-fino':
        base = f'modify-color(var(--highlight-color) set-alpha {op:.3f})'
        hover = f'modify-color(var(--highlight-color) set-alpha {max(op, hi):.3f})'
        borda = 'none'; borda_h = 'none'
    elif modo == 'cor':
        c = cfg.get('cor', '#8ab4f8')
        base = hex_rgba(c, op); hover = hex_rgba(c, max(op, hi))
        borda = 'none'; borda_h = 'none'
    else:  # vidro: alça de vidro fosco, sem cor de destaque
        base = f'modify-color(var(--window-text-color) set-alpha {op * 0.55:.3f})'
        hover = f'modify-color(var(--window-text-color) set-alpha {max(op, hi) * 0.6:.3f})'
        borda = f'1px solid modify-color(var(--window-text-color) set-alpha {min(1, op * 0.35):.3f})'
        borda_h = f'1px solid modify-color(var(--window-text-color) set-alpha {min(1, hi * 0.4):.3f})'
    if sim(cfg, 'sobreposta'):   # por cima do conteúdo: trilho transparente de verdade
        trilho = 'modify-color(var(--window-text-color) set-alpha 0.05)' if sim(cfg, 'trilho') else 'transparent'
    else:
        trilho = 'modify-color(var(--window-text-color) set-alpha 0.05)' if sim(cfg, 'trilho') else 'var(--view-background-color)'
    css = f""":root {{
    --scrollbar-size: {total}px;
    --non-interactive-scrollbar-size: {max(4, total - 4)}px;
}}
scrollbar {{
    width: {total}px;
    height: {total}px;
    padding: {pad}px;
    background-color: {trilho};
    &.horizontal {{ border-top: none; }}
    &.vertical {{ border-left: none; }}
    & > handle {{
        background-color: {base};
        border: {borda};
        border-radius: {raio}px;
        &:hovered,
        &:pressed {{
            background-color: {hover};
            border: {borda_h};
        }}
    }}
    &.noninteractive {{
        border-left: none;
        & > handle {{ background-color: {base}; border: none; border-radius: {raio}px; }}
    }}
}}
"""
    escrever_css('barra', css)
