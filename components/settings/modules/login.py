"""Login screen (SDDM, Vidro theme): background, blur, dim, clock, colors, avatar and layout.
Builds a full copy of the theme in ~/.local/share/vidro/login/theme (can be tested in a window).
Installing it into the system needs the admin password: button "Apply to the login screen"
(runs ~/.local/share/vidro/login/apply.sh with pkexec)."""
import glob, json, os, re, shutil, subprocess, sys, urllib.parse
sys.path.insert(0, os.path.dirname(__file__))
from _common import flag as sim, num

GROUP = 'Login'
DEFAULTS = {
    'background': 'honeywave',      # honeywave | wallpaper (current wallpaper) | file | color
    'file': '',
    'background_color': '#15161b',
    'blur': 'true',
    'blur_strength': '28',             # blur (0-60)
    'dim': '30',         # %
    'clock_format': '24h',          # 24h | 12h
    'clock_seconds': 'false',
    'clock_size': '100',          # % of the clock size
    'clock_weight': 'ExtraLight',      # ExtraLight | Light | Normal | DemiBold | Bold
    'show_date': 'true',
    'show_clock': 'true',
    'accent': '#ffffff',
    'glass': '8',              # opacity of the pills (%)
    'layout': 'center',       # centro | esquerda
    'avatar': 'true',
    'avatar_shape': 'circle', # circulo | quadrado
    'font': 'Noto Sans',
}
DATA = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
FOLDER = os.path.join(DATA, 'vidro', 'login')
BASE, THEME = os.path.join(FOLDER, 'base'), os.path.join(FOLDER, 'theme')
TARGET = '/usr/local/share/sddm/themes/vidro'
LAST = os.path.join(FOLDER, 'last-background')


def _wallpaper():
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


def _image(cfg):
    f = cfg.get('background', 'honeywave')
    if f == 'wallpaper':
        return _wallpaper()
    if f == 'file':
        return os.path.expanduser(cfg.get('file', ''))
    if f == 'color':
        return None
    for w in ('/usr/share/wallpapers/Honeywave', '/usr/share/wallpapers/Next'):
        fs = glob.glob(os.path.join(w, 'contents', 'images', '*.jpg')) + glob.glob(os.path.join(w, 'contents', 'images', '*.png'))
        if fs:
            return max(fs, key=os.path.getsize)
    return ''


def _backgrounds(cfg):
    img = _image(cfg)
    strength = int(num(cfg, 'blur_strength', 0, 60, 28))
    key = json.dumps([cfg.get('background'), img, cfg.get('background_color'), strength,
                        os.path.getmtime(img) if img and os.path.isfile(img) else 0])
    try:
        if open(LAST).read() == key and os.path.isfile(os.path.join(THEME, 'background.jpg')):
            return
    except OSError:
        pass
    a, b = os.path.join(THEME, 'background.jpg'), os.path.join(THEME, 'background-blur.jpg')
    if img is None:   # solid color
        cor = cfg.get('background_color', '#15161b')
        cor = cor if re.fullmatch(r'#[0-9a-fA-F]{6}', cor or '') else '#15161b'
        subprocess.run(['magick', '-size', '1920x1080', f'xc:{cor}', '-quality', '92', a], capture_output=True)
        shutil.copy(a, b)
    elif img and os.path.isfile(img):
        subprocess.run(['magick', img, '-resize', '2560x>', '-quality', '90', a], capture_output=True)
        if strength > 0:
            subprocess.run(['magick', img, '-resize', '1280x', '-blur', f'0x{strength}', '-modulate', '92,135', '-quality', '88', b], capture_output=True)
        else:
            shutil.copy(a, b)
    open(LAST, 'w').write(key)


def apply(cfg):
    if not os.path.isfile(os.path.join(BASE, 'Main.qml')):
        return
    os.makedirs(THEME, exist_ok=True)
    for f in os.listdir(BASE):
        shutil.copy(os.path.join(BASE, f), os.path.join(THEME, f))
    _backgrounds(cfg)
    hexa = lambda v, d: v if re.fullmatch(r'#[0-9a-fA-F]{6}', v or '') else d
    weights = ('ExtraLight', 'Light', 'Normal', 'DemiBold', 'Bold')
    lines = {
        'useBlur': 'true' if sim(cfg, 'blur') and cfg.get('background') != 'color' else 'false',
        'dim': str(int(num(cfg, 'dim', 0, 90, 30))),
        'clockFormat': '12h' if cfg.get('clock_format') == '12h' else '24h',
        'clockSeconds': 'true' if sim(cfg, 'clock_seconds') else 'false',
        'clockScale': str(int(num(cfg, 'clock_size', 40, 180, 100))),
        'clockWeight': cfg.get('clock_weight') if cfg.get('clock_weight') in weights else 'ExtraLight',
        'showDate': 'true' if sim(cfg, 'show_date') else 'false',
        'showClock': 'true' if sim(cfg, 'show_clock') else 'false',
        'accent': hexa(cfg.get('accent'), '#ffffff'),
        'glass': str(int(num(cfg, 'glass', 0, 40, 8))),
        'layout': 'left' if cfg.get('layout') == 'left' else 'center',
        'showAvatar': 'true' if sim(cfg, 'avatar') else 'false',
        'avatarShape': 'square' if cfg.get('avatar_shape') == 'square' else 'circle',
        'font': re.sub(r'[^\w \-]', '', cfg.get('font', 'Noto Sans')) or 'Noto Sans',
    }
    with open(os.path.join(THEME, 'theme.conf.user'), 'w') as f:
        f.write('[General]\n' + ''.join(f'{k}={v}\n' for k, v in lines.items()))
    # script run as administrator (pkexec) by the "Apply to the login screen" button
    with open(os.path.join(FOLDER, 'apply.sh'), 'w') as f:
        f.write(f'''#!/bin/bash
# Generated by Vidro Settings: copies the login theme built in {THEME} into the system.
set -e
[ "$(id -u)" = 0 ] || {{ echo "must run as administrator"; exit 1; }}
SOURCE={THEME!r}
DEST={TARGET}
[ -f "$SOURCE/Main.qml" ] || {{ echo "theme not found"; exit 1; }}
B=/var/backups/vidro-sddm-$(date +%Y%m%d-%H%M%S); mkdir -p "$B"
cp -a /etc/sddm.conf.d "$B/" 2>/dev/null || true
[ -d "$DEST" ] && cp -a "$DEST" "$B/previous-theme"
rm -rf "$DEST.new"; mkdir -p "$DEST.new"
cp "$SOURCE"/* "$DEST.new/"
chmod -R a+rX "$DEST.new"; chown -R root:root "$DEST.new"
rm -rf "$DEST"; mv "$DEST.new" "$DEST"
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/zzz-vidro.conf <<'CONF'
[General]
# empty = no Qt virtual keyboard; the on-screen keyboard comes from the compositor (e.g. plasma-keyboard)
InputMethod=

[Theme]
ThemeDir=/usr/local/share/sddm/themes
Current=vidro
CONF
echo "ok: login screen updated (backup in $B)"
''')
