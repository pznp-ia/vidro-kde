"""Tela de login (SDDM, tema Vidro): fundo, desfoque, escurecimento, relógio, cores, avatar e posição.
Monta uma cópia completa do tema em ~/.local/share/vidro/login/tema (dá para testar numa janela).
Passar para o sistema precisa de senha de administrador: botão "Aplicar na tela de login"
(roda ~/.local/share/vidro/login/aplicar.sh com pkexec)."""
import glob, json, os, re, shutil, subprocess, sys, urllib.parse
sys.path.insert(0, os.path.dirname(__file__))
from _union import num, sim

GRUPO = 'Login'
PADROES = {
    'fundo': 'honeywave',      # honeywave | papel (papel de parede atual) | arquivo | cor
    'arquivo': '',
    'cor_fundo': '#15161b',
    'desfoque': 'true',
    'forca': '28',             # desfoque (0-60)
    'escurecer': '30',         # %
    'relogio': '24h',          # 24h | 12h
    'segundos': 'false',
    'tamanho': '100',          # % do relógio
    'peso': 'ExtraLight',      # ExtraLight | Light | Normal | DemiBold | Bold
    'data': 'true',
    'mostrar_relogio': 'true',
    'destaque': '#ffffff',
    'vidro': '8',              # opacidade das pílulas (%)
    'posicao': 'centro',       # centro | esquerda
    'avatar': 'true',
    'forma_avatar': 'circulo', # circulo | quadrado
    'fonte': 'Noto Sans',
}
DATA = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
PASTA = os.path.join(DATA, 'vidro', 'login')
BASE, TEMA = os.path.join(PASTA, 'base'), os.path.join(PASTA, 'tema')
DESTINO = '/usr/local/share/sddm/themes/vidro'
ULTIMO = os.path.join(PASTA, 'ultimo-fundo')


def _papel():
    try:
        s = open(os.path.expanduser('~/.config/plasma-org.kde.plasma.desktop-appletsrc')).read()
    except OSError:
        return ''
    for m in re.finditer(r'^\[Containments\]\[(\d+)\]\[Wallpaper\]\[org\.kde\.image\]\[General\]\n((?:[^\[\n].*\n?)*)', s, re.M):
        im = re.search(r'^Image=(.*)$', m.group(2), re.M)
        if im:
            p = urllib.parse.unquote(im.group(1).replace('file://', ''))
            if os.path.isdir(p):
                fs = [f for f in glob.glob(os.path.join(p, '**', '*'), recursive=True) if re.search(r'\.(jpe?g|png|webp)$', f, re.I)]
                p = max(fs, key=os.path.getsize) if fs else ''
            return p
    return ''


def _imagem(cfg):
    f = cfg.get('fundo', 'honeywave')
    if f == 'papel':
        return _papel()
    if f == 'arquivo':
        return os.path.expanduser(cfg.get('arquivo', ''))
    if f == 'cor':
        return None
    for w in ('/usr/share/wallpapers/Honeywave', '/usr/share/wallpapers/Next'):
        fs = glob.glob(os.path.join(w, 'contents', 'images', '*.jpg')) + glob.glob(os.path.join(w, 'contents', 'images', '*.png'))
        if fs:
            return max(fs, key=os.path.getsize)
    return ''


def _fundos(cfg):
    img = _imagem(cfg)
    forca = int(num(cfg, 'forca', 0, 60, 28))
    chave = json.dumps([cfg.get('fundo'), img, cfg.get('cor_fundo'), forca,
                        os.path.getmtime(img) if img and os.path.isfile(img) else 0])
    try:
        if open(ULTIMO).read() == chave and os.path.isfile(os.path.join(TEMA, 'fundo.jpg')):
            return
    except OSError:
        pass
    a, b = os.path.join(TEMA, 'fundo.jpg'), os.path.join(TEMA, 'fundo-desfocado.jpg')
    if img is None:   # cor lisa
        cor = cfg.get('cor_fundo', '#15161b')
        cor = cor if re.fullmatch(r'#[0-9a-fA-F]{6}', cor or '') else '#15161b'
        subprocess.run(['magick', '-size', '1920x1080', f'xc:{cor}', '-quality', '92', a], capture_output=True)
        shutil.copy(a, b)
    elif img and os.path.isfile(img):
        subprocess.run(['magick', img, '-resize', '2560x>', '-quality', '90', a], capture_output=True)
        if forca > 0:
            subprocess.run(['magick', img, '-resize', '1280x', '-blur', f'0x{forca}', '-modulate', '92,135', '-quality', '88', b], capture_output=True)
        else:
            shutil.copy(a, b)
    open(ULTIMO, 'w').write(chave)


def aplicar(cfg):
    if not os.path.isfile(os.path.join(BASE, 'Main.qml')):
        return
    os.makedirs(TEMA, exist_ok=True)
    for f in os.listdir(BASE):
        shutil.copy(os.path.join(BASE, f), os.path.join(TEMA, f))
    _fundos(cfg)
    hexa = lambda v, d: v if re.fullmatch(r'#[0-9a-fA-F]{6}', v or '') else d
    pesos = ('ExtraLight', 'Light', 'Normal', 'DemiBold', 'Bold')
    linhas = {
        'useBlur': 'true' if sim(cfg, 'desfoque') and cfg.get('fundo') != 'cor' else 'false',
        'dim': str(int(num(cfg, 'escurecer', 0, 90, 30))),
        'clockFormat': '12h' if cfg.get('relogio') == '12h' else '24h',
        'clockSeconds': 'true' if sim(cfg, 'segundos') else 'false',
        'clockScale': str(int(num(cfg, 'tamanho', 40, 180, 100))),
        'clockWeight': cfg.get('peso') if cfg.get('peso') in pesos else 'ExtraLight',
        'showDate': 'true' if sim(cfg, 'data') else 'false',
        'showClock': 'true' if sim(cfg, 'mostrar_relogio') else 'false',
        'accent': hexa(cfg.get('destaque'), '#ffffff'),
        'glass': str(int(num(cfg, 'vidro', 0, 40, 8))),
        'layout': 'esquerda' if cfg.get('posicao') == 'esquerda' else 'centro',
        'showAvatar': 'true' if sim(cfg, 'avatar') else 'false',
        'avatarShape': 'quadrado' if cfg.get('forma_avatar') == 'quadrado' else 'circulo',
        'font': re.sub(r'[^\w \-]', '', cfg.get('fonte', 'Noto Sans')) or 'Noto Sans',
    }
    with open(os.path.join(TEMA, 'theme.conf.user'), 'w') as f:
        f.write('[General]\n' + ''.join(f'{k}={v}\n' for k, v in linhas.items()))
    # script que o botão "Aplicar na tela de login" roda como administrador (pkexec)
    with open(os.path.join(PASTA, 'aplicar.sh'), 'w') as f:
        f.write(f'''#!/bin/bash
# Gerado pelas Configurações do Vidro: copia o tema de login montado em {TEMA} para o sistema.
set -e
[ "$(id -u)" = 0 ] || {{ echo "precisa ser administrador"; exit 1; }}
ORIGEM={TEMA!r}
DEST={DESTINO}
[ -f "$ORIGEM/Main.qml" ] || {{ echo "tema não encontrado"; exit 1; }}
B=/var/backups/vidro-sddm-$(date +%Y%m%d-%H%M%S); mkdir -p "$B"
cp -a /etc/sddm.conf.d "$B/" 2>/dev/null || true
[ -d "$DEST" ] && cp -a "$DEST" "$B/tema-anterior"
rm -rf "$DEST.novo"; mkdir -p "$DEST.novo"
cp "$ORIGEM"/* "$DEST.novo/"
chmod -R a+rX "$DEST.novo"; chown -R root:root "$DEST.novo"
rm -rf "$DEST"; mv "$DEST.novo" "$DEST"
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/zzz-vidro.conf <<'CONF'
[General]
# vazio = sem o teclado virtual do Qt; quem abre o teclado de tela é o compositor (ex.: plasma-keyboard)
InputMethod=

[Theme]
ThemeDir=/usr/local/share/sddm/themes
Current=vidro
CONF
echo "ok: tela de login atualizada (backup em $B)"
''')
