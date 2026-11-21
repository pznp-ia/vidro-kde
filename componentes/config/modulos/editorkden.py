"""EditorKden: Kdenlive (flatpak) com visual minimalista inspirado no macOS.
Configuração própria em ~/.var/app/org.kde.kdenlive/editorkden/config (o Kdenlive normal não muda).
Lança com: editorkden (ou pelo menu "EditorKden"). Desligado = remove o lançador."""
import configparser, glob, os, re, shutil, sys
sys.path.insert(0, os.path.dirname(__file__))
from _union import num, sim

GRUPO = 'EditorKden'
PADROES = {
    'ativo': 'true',
    'cor': '#0a84ff',        # destaque (azul do macOS)
    'fundo': '12',           # 0-100: claridade do grafite (0 = quase preto)
    'contraste': '35',       # 0-100: painéis x área de conteúdo
    'arredondamento': '8',   # px
    'fonte': '10',           # pt
    'titulos': 'false',      # títulos nos painéis (docks)
    'boasvindas': 'false',   # tela de boas-vindas ao abrir
    # visual estiloso
    'estilo': 'pilula',      # pilula (abas em pílula, botões planos) | padrao (Union normal)
    'rotulos': 'false',      # texto nos botões da barra de ferramentas
    'menu': 'true',          # barra de menus (Ctrl+M mostra/esconde)
    'status': 'true',        # barra de status
    'clips': 'suaves',       # tema | suaves | destaque (cor dos clipes na linha do tempo)
    'onda': 'destaque',      # padrao | destaque (cor da forma de onda do áudio)
    'monitor': 'grafite',    # preto | grafite (fundo do monitor)
}
APP = os.path.expanduser('~/.var/app/org.kde.kdenlive')
CFG = os.path.join(APP, 'editorkden', 'config')
DADOS = os.path.join(APP, 'data')
BIN = os.path.expanduser('~/.local/bin/editorkden')
DESK = os.path.expanduser('~/.local/share/applications/editorkden.desktop')
UNION_VIDRO = os.path.expanduser('~/.local/share/union/styles/vidro')
ESTADO = os.path.join(APP, 'editorkden', 'state')   # posição dos painéis, separada do Kdenlive normal


def _rgb(h):
    h = h.lstrip('#'); h = h if len(h) == 6 else '0a84ff'
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def _c(t):
    return ','.join(str(max(0, min(255, int(round(v))))) for v in t)


def _ini(path):
    c = configparser.RawConfigParser(strict=False, interpolation=None); c.optionxform = str
    c.read(path); return c


def _salvar(c, path):
    with open(path, 'w') as f:
        c.write(f, space_around_delimiters=False)


def _cores(cfg):
    f = num(cfg, 'fundo', 0, 100, 12) / 100
    k = num(cfg, 'contraste', 0, 100, 35) / 100
    conteudo = 22 + 30 * f              # área de vídeo/linha do tempo
    painel = conteudo + 6 + 16 * k      # painéis e barras
    botao = painel + 12
    texto, texto2 = (230, 230, 232), (152, 152, 157)
    a = _rgb(cfg.get('cor', '#0a84ff'))
    c = _ini('/usr/share/color-schemes/BreezeDark.colors')
    def grupo(g, fundo, alt):
        if not c.has_section(g): c.add_section(g)
        c.set(g, 'BackgroundNormal', _c((fundo,) * 3)); c.set(g, 'BackgroundAlternate', _c((alt,) * 3))
        c.set(g, 'ForegroundNormal', _c(texto)); c.set(g, 'ForegroundInactive', _c(texto2))
        c.set(g, 'DecorationFocus', _c(a)); c.set(g, 'DecorationHover', _c(a))
    grupo('Colors:Window', painel, painel - 4)
    grupo('Colors:View', conteudo, conteudo + 4)
    grupo('Colors:Button', botao, botao - 6)
    grupo('Colors:Header', painel, painel - 4)
    grupo('Colors:Tooltip', botao, botao)
    grupo('Colors:Complementary', conteudo - 6, conteudo)
    for g in ('Colors:Selection',):
        if not c.has_section(g): c.add_section(g)
        c.set(g, 'BackgroundNormal', _c(a)); c.set(g, 'BackgroundAlternate', _c(tuple(v * 0.7 for v in a)))
        c.set(g, 'ForegroundNormal', '255,255,255'); c.set(g, 'DecorationFocus', _c(a)); c.set(g, 'DecorationHover', _c(a))
    if not c.has_section('General'): c.add_section('General')
    for o in [o for o in c.options('General') if o.startswith('Name[')]: c.remove_option('General', o)
    c.set('General', 'Name', 'EditorKden'); c.set('General', 'ColorScheme', 'EditorKden')
    os.makedirs(os.path.join(DADOS, 'color-schemes'), exist_ok=True)
    _salvar(c, os.path.join(DADOS, 'color-schemes', 'EditorKden.colors'))


def _css_estilo(cfg, r):
    if cfg.get('estilo', 'pilula') != 'pilula':
        return '/* estilo padrão */\n'
    a = cfg.get('cor', '#0a84ff')
    a = a if re.fullmatch(r'#[0-9a-fA-F]{6}', a or '') else '#0a84ff'
    return f'''/* gerado por vidro-config (EditorKden): abas em pílula, botões planos */
tabbutton {{
    background-color: transparent;
    border: none;
    border-radius: {max(r, 6) + 4}px;
    margin: 2px;
    color: modify-color(var(--window-text-color) set-alpha 0.6);
    &[direction="top"], &[direction="bottom"] {{ border: none; border-radius: {max(r, 6) + 4}px; }}
    &:hovered {{ background-color: modify-color(var(--window-text-color) set-alpha 0.07); color: var(--window-text-color); }}
    &:checked, &:highlighted {{
        background-color: modify-color(var(--highlight-color) set-alpha 0.22);
        color: var(--window-text-color);
        border: none;
    }}
}}
tabbar {{ border: none; background-color: transparent; }}
toolbutton {{
    background-color: transparent;
    border: 1px solid transparent;
    border-radius: {max(r, 4)}px;
    &:hovered {{ background-color: modify-color(var(--window-text-color) set-alpha 0.08); border-color: transparent; }}
    &:pressed {{ background-color: modify-color(var(--window-text-color) set-alpha 0.14); }}
    &:checked {{ background-color: modify-color(var(--highlight-color) set-alpha 0.28); border-color: modify-color(var(--highlight-color) set-alpha 0.45); }}
}}
toolseparator {{ background-color: transparent; }}
combobox {{ border-color: modify-color(var(--window-text-color) set-alpha 0.08); }}
statusbar {{ background-color: transparent; }}
'''


def _estilo(cfg):
    dst = os.path.join(DADOS, 'union', 'styles', 'editorkden')
    shutil.rmtree(dst, ignore_errors=True)
    if not os.path.isdir(UNION_VIDRO):
        return False
    shutil.copytree(UNION_VIDRO, dst, symlinks=False)   # cópia real: o flatpak não enxerga ~/.local/share
    css = os.path.join(dst, 'contents', 'css')
    r = int(num(cfg, 'arredondamento', 0, 16, 8))
    open(os.path.join(css, 'editorkden-vars.css'), 'w').write(
        f'/* gerado por vidro-config (EditorKden) */\n:root {{\n    --corner-radius: {r}px;\n'
        '    --window-border-color: modify-color(var(--window-text-color) set-alpha 0.06);\n'
        '    --header-active-border-color: modify-color(var(--window-text-color) set-alpha 0.06);\n'
        '    --window-active-border-color: modify-color(var(--window-text-color) set-alpha 0.06);\n}\n')
    open(os.path.join(css, 'editorkden-estilo.css'), 'w').write(_css_estilo(cfg, r))
    st = os.path.join(css, 'style.css'); s = open(st).read()
    s = s.replace('@import "defaults.css";', '@import "defaults.css";\n@import "editorkden-vars.css";', 1)
    s = s.rstrip('\n') + '\n@import "editorkden-estilo.css";\n'
    open(st, 'w').write(s)
    md = os.path.join(dst, 'metadata.json'); m = open(md).read().replace('"Vidro"', '"EditorKden"', 1)
    open(md, 'w').write(m)
    return True


def _kdenlive_instalado():
    import subprocess
    try:
        return subprocess.run(['flatpak', 'info', 'org.kde.kdenlive'], capture_output=True).returncode == 0
    except OSError:
        return False


def aplicar(cfg):
    if not sim(cfg, 'ativo') or not _kdenlive_instalado():
        for p in (BIN, DESK):
            if os.path.exists(p): os.remove(p)
        return
    os.makedirs(CFG, exist_ok=True)
    if not os.path.isdir(ESTADO):   # começa com a disposição atual do Kdenlive
        os.makedirs(ESTADO, exist_ok=True)
        orig = os.path.join(APP, '.local', 'state', 'kdenlivestaterc')
        if os.path.exists(orig): shutil.copy2(orig, os.path.join(ESTADO, 'kdenlivestaterc'))
    rc = os.path.join(CFG, 'kdenlive-flatpakrc')
    if not os.path.exists(rc):
        orig = os.path.join(APP, 'config', 'kdenlive-flatpakrc')
        if os.path.exists(orig): shutil.copy2(orig, rc)
    _cores(cfg)
    union = _estilo(cfg)
    k = _ini(rc)
    for g in ('UiSettings', 'unmanaged', 'startup'):
        if not k.has_section(g): k.add_section(g)
    k.set('UiSettings', 'ColorScheme', 'EditorKden')
    k.set('unmanaged', 'widgetstyle', 'Union' if union else 'Breeze')
    k.set('unmanaged', 'showtitlebars', 'true' if sim(cfg, 'titulos') else 'false')
    k.set('startup', 'showWelcome', 'true' if sim(cfg, 'boasvindas') else 'false')
    if not k.has_section('MainWindow'): k.add_section('MainWindow')
    k.set('MainWindow', 'MenuBar', 'Enabled' if sim(cfg, 'menu') else 'Disabled')
    k.set('MainWindow', 'StatusBar', 'Enabled' if sim(cfg, 'status') else 'Disabled')
    a = _rgb(cfg.get('cor', '#0a84ff'))
    hexa = lambda t: '#%02x%02x%02x' % tuple(max(0, min(255, round(v))) for v in t)
    mix = lambda c1, c2, t: tuple(x + (y - x) * t for x, y in zip(c1, c2))
    clips = cfg.get('clips', 'suaves')
    if clips == 'tema':
        cores = {'videoColor': '#00000000', 'audioColor': '#00000000', 'titleColor': '#00000000', 'imageColor': '#00000000'}
    elif clips == 'destaque':
        cores = {'videoColor': hexa(mix(a, (30, 31, 36), .45)), 'audioColor': hexa(mix(a, (30, 31, 36), .65)),
                 'titleColor': hexa(mix(a, (255, 255, 255), .15)), 'imageColor': hexa(mix(a, (30, 31, 36), .3))}
    else:  # suaves: tons dessaturados que combinam com o grafite
        cores = {'videoColor': '#3f5f8a', 'audioColor': '#3e7a64', 'titleColor': '#6e5a9e', 'imageColor': '#8a6d3f'}
    for c, v in cores.items():
        k.set('unmanaged', c, v)
    if cfg.get('onda', 'destaque') == 'destaque':
        k.set('unmanaged', 'thumbColor1', hexa(mix(a, (255, 255, 255), .2))); k.set('unmanaged', 'thumbColor2', hexa(a))
    else:
        k.set('unmanaged', 'thumbColor1', '#2ac1a0'); k.set('unmanaged', 'thumbColor2', '#2ed172')
    if not k.has_section('sdl'): k.add_section('sdl')
    k.set('sdl', 'monitor_background', '#1c1d21' if cfg.get('monitor', 'grafite') == 'grafite' else 'black')
    _salvar(k, rc)
    g = _ini(os.path.join(CFG, 'kdeglobals'))
    for s in ('General', 'KDE', 'Icons'):
        if not g.has_section(s): g.add_section(s)
    fonte = int(num(cfg, 'fonte', 8, 14, 10))
    g.set('General', 'ColorScheme', 'EditorKden')
    g.set('General', 'font', f'Noto Sans,{fonte},-1,5,400,0,0,0,0,0,0,0,0,0,0,1')
    g.set('General', 'smallestReadableFont', f'Noto Sans,{max(7, fonte - 2)},-1,5,400,0,0,0,0,0,0,0,0,0,0,1')
    g.set('KDE', 'widgetStyle', 'Union' if union else 'Breeze')
    g.set('Icons', 'Theme', 'breeze-dark')
    if not g.has_section('Toolbar style'): g.add_section('Toolbar style')
    estilo_barra = 'TextBesideIcon' if sim(cfg, 'rotulos') else 'NoText'
    g.set('Toolbar style', 'ToolButtonStyle', estilo_barra)
    g.set('Toolbar style', 'ToolButtonStyleOtherToolbars', estilo_barra)
    _salvar(g, os.path.join(CFG, 'kdeglobals'))
    os.makedirs(os.path.dirname(BIN), exist_ok=True)
    with open(BIN, 'w') as f:
        f.write('#!/bin/bash\n# EditorKden: Kdenlive com visual minimalista (configuração em ~/.var/app/org.kde.kdenlive/editorkden)\n'
                '# o flatpak redefine XDG_CONFIG_HOME, então a variável é posta já dentro do sandbox\n'
                f'exec flatpak run --command=sh org.kde.kdenlive -c \'XDG_CONFIG_HOME={CFG} XDG_STATE_HOME={ESTADO} '
                + ('QT_STYLE_OVERRIDE=Union UNION_STYLE_NAME=editorkden ' if union else '')
                + 'exec kdenlive "$@"\' editorkden "$@"\n')
    os.chmod(BIN, 0o755)
    os.makedirs(os.path.dirname(DESK), exist_ok=True)
    with open(DESK, 'w') as f:
        f.write('[Desktop Entry]\nType=Application\nName=EditorKden\nGenericName=Editor de vídeo minimalista\n'
                'Comment=Kdenlive com visual minimalista inspirado no macOS\nExec=editorkden %F\nIcon=kdenlive\n'
                'Terminal=false\nCategories=AudioVideo;Video;AudioVideoEditing;Qt;KDE;\nMimeType=application/x-kdenlive;\n'
                'StartupWMClass=kdenlive\n')
