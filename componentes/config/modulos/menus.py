"""Menus de clique direito dos apps (estilo Union "vidro") + animação dos menus/pop-ups (efeito vidro_popups)."""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(__file__))
from _union import escrever_css, hex_rgba, num, sim

GRUPO = 'Menus'
PADROES = {
    'ativo': 'true',          # false = menus padrão do Union
    'raio': '12',             # cantos do menu (px)
    'opacidade': '92',        # fundo do menu (%)
    'espaco': '6',            # respiro interno (px)
    'separadores': '0',       # visibilidade das linhas separadoras (0 = só um espaço)
    'realce': 'vidro',        # vidro | destaque | cor
    'cor_realce': '#8ab4f8',  # usada quando realce = cor
    'fundo': 'tema',          # tema | cor
    'cor_fundo': '#1c1e24',   # usada quando fundo = cor
    'intensidade': '14',      # força do realce do item (%)
    'borda': '14',            # borda fina do menu (%)
    'animacao': 'true',       # animação ao abrir/fechar
    'entrada': '150',         # ms
    'saida': '110',           # ms
    'escala': '97',           # % inicial
    'deslize': '6',           # px
}

def _kwin(cfg):
    on = sim(cfg, 'animacao')
    vals = {'Entrada': int(num(cfg, 'entrada', 40, 600, 150)), 'Saida': int(num(cfg, 'saida', 40, 600, 110)),
            'Escala': int(num(cfg, 'escala', 70, 100, 97)), 'Deslize': int(num(cfg, 'deslize', 0, 40, 6))}
    for k, v in vals.items():
        subprocess.run(['kwriteconfig6', '--file', 'kwinrc', '--group', 'Effect-vidro_popups', '--key', k, str(v)])
    subprocess.run(['kwriteconfig6', '--file', 'kwinrc', '--group', 'Plugins', '--key', 'vidro_popupsEnabled', 'true' if on else 'false'])
    metodo = 'loadEffect' if on else 'unloadEffect'
    d = ['dbus-send', '--session', '--type=method_call', '--dest=org.kde.KWin', '/Effects']
    subprocess.run(d + [f'org.kde.kwin.Effects.{metodo}', 'string:vidro_popups'])
    if on:
        subprocess.run(d + ['org.kde.kwin.Effects.reconfigureEffect', 'string:vidro_popups'])

def aplicar(cfg):
    _kwin(cfg)
    if not sim(cfg, 'ativo'):
        escrever_css('menus', '/* desligado: menus padrão */\n'); return
    r = int(num(cfg, 'raio', 0, 24, 12))
    p = int(num(cfg, 'espaco', 0, 14, 6))
    op = num(cfg, 'opacidade', 40, 100, 92) / 100
    sep = num(cfg, 'separadores', 0, 100, 12) / 100
    inten = num(cfg, 'intensidade', 0, 60, 14) / 100
    borda = num(cfg, 'borda', 0, 60, 14) / 100
    ri = max(2, r - p)  # cantos dos itens acompanham os do menu
    if cfg.get('realce', 'vidro') == 'cor':
        c = cfg.get('cor_realce', '#8ab4f8')
        hov = hex_rgba(c, min(1, inten * 2.2)); pre = hex_rgba(c, min(1, inten * 3.2))
    elif cfg.get('realce', 'vidro') == 'destaque':
        hov = f'modify-color(var(--highlight-color) set-alpha {min(1, inten * 2.2):.3f})'
        pre = f'modify-color(var(--highlight-color) set-alpha {min(1, inten * 3.2):.3f})'
    else:
        hov = f'modify-color(var(--window-text-color) set-alpha {inten:.3f})'
        pre = f'modify-color(var(--window-text-color) set-alpha {min(1, inten * 1.6):.3f})'
    fundo = hex_rgba(cfg.get('cor_fundo', '#1c1e24'), op) if cfg.get('fundo', 'tema') == 'cor' \
        else f'modify-color(var(--window-background-color) set-alpha {op:.3f})'
    linha = f'modify-color(var(--window-text-color) set-alpha {sep * 0.5:.3f})' if sep > 0 else 'transparent'
    css = f"""menu {{
    border-radius: {r}px;
    background-color: {fundo};
    border: 1px solid modify-color(var(--window-text-color) set-alpha {borda:.3f});
    padding: {p}px;
}}
menuitem {{
    border-radius: {ri}px;
    border: none;
    &:hovered,
    &.with-submenu:highlighted {{
        background-color: {hov};
        border: none;
    }}
    &:pressed,
    &.with-submenu:pressed {{
        background-color: {pre};
        border: none;
        color: var(--window-text-color);
    }}
}}
menuseparator {{
    height: 1px;
    background-color: {linha};
    inset: {max(3, p)}px;
    &.with-title {{ border-bottom: none; background-color: transparent; }}
}}
"""
    escrever_css('menus', css)
