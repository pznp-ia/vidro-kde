"""Pastas (Dolphin): sem linhas de separação, fundo contínuo entre barra lateral e arquivos.
Só o Dolphin usa: estilo Union derivado "vidro-dolphin" (herda o "vidro" por atalhos) +
lançadores do Dolphin com UNION_STYLE_NAME=vidro-dolphin. Desligado = Dolphin igual aos outros apps."""
import glob, os, shutil, sys
sys.path.insert(0, os.path.dirname(__file__))
from _union import hex_rgba, num, sim

GRUPO = 'Pastas'
PADROES = {
    'ativo': 'true',
    'linhas': '0',          # 0-100: visibilidade das linhas de separação (0 = nenhuma)
    'unificar': 'true',     # fundo das listas com a cor da interface (esquema Vidro: vale para as listas de todos os apps KDE)
    'cor': 'interface',     # interface | cor — cor do fundo da área de arquivos
    'cor_fundo': '#25282d', # usada quando cor = cor
    'escuro': '0',          # 0-100: fundo da área de arquivos — 0 = igual à interface, 100 = escuro original
    'espaco': '6',          # px: respiro entre as partes
}
DADOS = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
BASE = os.path.join(DADOS, 'union', 'styles', 'vidro')
EST = os.path.join(DADOS, 'union', 'styles', 'vidro-dolphin')
APPS = os.path.join(DADOS, 'applications', 'org.kde.dolphin.desktop')
DBUS = os.path.join(DADOS, 'dbus-1', 'services', 'org.kde.dolphin.FileManager1.service')
MARCA = '# gerado por vidro-config (módulo pastas)'
ESQUEMA = os.path.join(DADOS, 'color-schemes', 'Vidro.colors')
ORIG = os.path.join(DADOS, 'vidro', 'listas-original.txt')   # cor original das listas (para voltar)


def _rgb(t):
    return [int(x) for x in t.split(',')[:3]]


def _listas(escuro, ligar, cor=None):
    """Fundo das listas ([Colors:View] do esquema Vidro): de "igual à interface" (0) até o escuro original (1).
    O KDE só permite isso no esquema de cores, então vale para as listas de todos os apps do KDE."""
    import subprocess
    if not os.path.exists(ESQUEMA):
        return
    rd = lambda f, g, k: subprocess.run(['kreadconfig6', '--file', f, '--group', g, '--key', k], capture_output=True, text=True).stdout.strip()
    if not os.path.exists(ORIG):
        os.makedirs(os.path.dirname(ORIG), exist_ok=True)
        open(ORIG, 'w').write(rd(ESQUEMA, 'Colors:View', 'BackgroundNormal') + '\n' + rd(ESQUEMA, 'Colors:View', 'BackgroundAlternate') + '\n')
    on, oa = open(ORIG).read().split()
    if ligar:
        jan = _rgb(rd(ESQUEMA, 'Colors:Window', 'BackgroundNormal'))
        if cor:  # cor personalizada no lugar da cor da interface
            jan = [int(cor[i:i + 2], 16) for i in (1, 3, 5)]
        mix = lambda a, b: ','.join(str(round(x + (y - x) * escuro)) for x, y in zip(a, b))
        nn = mix(jan, _rgb(on)); na = mix([min(255, v + 6) for v in jan], _rgb(oa))
    else:
        nn, na = on, oa
    ativo = subprocess.run(['kreadconfig6', '--file', 'kdeglobals', '--group', 'General', '--key', 'ColorScheme'], capture_output=True, text=True).stdout.strip()
    for k, v in (('BackgroundNormal', nn), ('BackgroundAlternate', na)):
        subprocess.run(['kwriteconfig6', '--file', ESQUEMA, '--group', 'Colors:View', '--key', k, v])
        if ativo == 'Vidro':
            subprocess.run(['kwriteconfig6', '--notify', '--file', 'kdeglobals', '--group', 'Colors:View', '--key', k, v])


def _estilo(vars_css, css):
    cdir = os.path.join(EST, 'contents', 'css')
    shutil.rmtree(EST, ignore_errors=True)
    os.makedirs(cdir)
    with open(os.path.join(EST, 'metadata.json'), 'w') as f:
        f.write('{\n "input-type": "css",\n "input-version": 1,\n "name": "Vidro Dolphin",\n'
                ' "description": "Vidro para o Dolphin: sem linhas de separação (gerado pelo vidro-config).",\n'
                ' "version": "1.0",\n "license": "BSD-2-Clause",\n "authors": [ "Vidro" ]\n}\n')
    base_css = os.path.join(BASE, 'contents', 'css')
    for p in glob.glob(os.path.join(base_css, '*.css')):
        n = os.path.basename(p)
        if n != 'style.css':
            os.symlink(os.path.relpath(p, cdir), os.path.join(cdir, n))
    img = os.path.join(BASE, 'contents', 'images')
    if os.path.isdir(img):
        os.symlink(os.path.relpath(img, os.path.join(EST, 'contents')), os.path.join(EST, 'contents', 'images'))
    # o Union resolve var() na ordem de leitura: as variáveis entram logo após defaults.css
    st = open(os.path.join(base_css, 'style.css')).read().rstrip('\n')
    st = st.replace('@import "defaults.css";', '@import "defaults.css";\n@import "dolphin-pastas-vars.css";', 1)
    with open(os.path.join(cdir, 'style.css'), 'w') as f:
        f.write(st + '\n@import "dolphin-pastas.css";\n')
    with open(os.path.join(cdir, 'dolphin-pastas-vars.css'), 'w') as f:
        f.write('/* gerado por vidro-config (módulo pastas) */\n' + vars_css)
    with open(os.path.join(cdir, 'dolphin-pastas.css'), 'w') as f:
        f.write('/* gerado por vidro-config (módulo pastas) */\n' + css)


def _lancadores(ligar):
    for p in (APPS, DBUS):
        if os.path.exists(p) and MARCA in open(p).read():
            os.remove(p)
    if not ligar:
        return
    env = 'UNION_STYLE_NAME=vidro-dolphin'
    src = '/usr/share/applications/org.kde.dolphin.desktop'
    if os.path.exists(src):
        s = open(src).read()
        s = s.replace('Exec=dolphin', f'Exec=env {env} dolphin')
        os.makedirs(os.path.dirname(APPS), exist_ok=True)
        if not os.path.exists(APPS):
            open(APPS, 'w').write(s.replace('[Desktop Entry]', '[Desktop Entry]\n' + MARCA, 1))
    os.makedirs(os.path.dirname(DBUS), exist_ok=True)
    if not os.path.exists(DBUS):
        open(DBUS, 'w').write(f'{MARCA}\n[D-BUS Service]\nName=org.freedesktop.FileManager1\n'
                              f'Exec=/usr/bin/env {env} /usr/bin/dolphin --daemon\n')


def aplicar(cfg):
    if not sim(cfg, 'ativo'):
        shutil.rmtree(EST, ignore_errors=True)
        _lancadores(False)
        _listas(1, False)
        return
    linhas = num(cfg, 'linhas', 0, 100, 0) / 100 * 0.18
    escuro = num(cfg, 'escuro', 0, 100, 0) / 100
    esp = int(num(cfg, 'espaco', 0, 16, 6))
    borda = f'modify-color(var(--window-text-color) set-alpha {linhas:.3f})'
    css = f""":root {{
    --window-border-color: {borda};
    --window-inactive-border-color: {borda};
    --view-border-color: {borda};
    --header-border-color: {borda};
    --hairline-color: {borda};
    --bar-active-border-color: {borda};
    --window-active-border-color: {borda};
    --header-active-border-color: {borda};
    --header-inactive-border-color: {borda};
"""
    vars_css = css + '}\n'
    css = f"""splitter {{ width: {max(1, esp)}px; background-color: transparent; }}
splitview handle {{ background-color: transparent; }}
toolbar, statusbar {{ border: none; border-top: none; border-bottom: none; }}
"""
    _estilo(vars_css, css)
    import re as _re
    cor = cfg.get('cor_fundo', '') if cfg.get('cor', 'interface') == 'cor' else None
    if cor and not _re.fullmatch(r'#[0-9a-fA-F]{6}', cor):
        cor = None
    _listas(escuro, sim(cfg, 'unificar') or bool(cor), cor)
    _lancadores(True)
