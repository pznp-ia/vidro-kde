#!/usr/bin/env python3
"""Generates the folder, file and sidebar icons of the Vidro icon theme (dark and minimalist).
Usage: python3 -I make-icons.py <theme-folder> <places.txt> <mimes.txt>"""
import os, re, sys
OUT, PLACES, MIMES = sys.argv[1], sys.argv[2], sys.argv[3]
GLYPH_COLOR = '#d9dae0'
# Big folder colors (Vidro Settings → Icons passes them through environment variables)
E = os.environ.get
PF1, PF2 = E('VIDRO_FOLDER_FRONT1', '#3a3c45'), E('VIDRO_FOLDER_FRONT2', '#1c1d22')
PB1, PB2 = E('VIDRO_FOLDER_BACK1', '#26272d'), E('VIDRO_FOLDER_BACK2', '#131417')
PGLIFO = E('VIDRO_FOLDER_GLYPH', GLYPH_COLOR)
PBRILHO = E('VIDRO_FOLDER_SHINE', '.22')
# Files (Vidro Settings → File icons)
FILE_STYLE = E('VIDRO_FILE_STYLE', 'dark')         # dark | light | colored | flat
FILE_LABEL = E('VIDRO_FILE_LABEL', '1') == '1'     # extension label (PDF, PNG…)
FILE_COLORS = E('VIDRO_FILE_COLORS', 'type')       # type (color per type) | single | gray
FILE_COLOR = E('VIDRO_FILE_COLOR', '#58a6ff')      # color when FILE_COLORS = single
FILE_FOLD = E('VIDRO_FILE_FOLD', '1') == '1'       # folded corner
try: FILE_RADIUS = max(0.0, min(10.0, float(E('VIDRO_FILE_RADIUS', '3'))))
except ValueError: FILE_RADIUS = 3.0
# Sidebar (small 16/22 px icons: Dolphin, open/save dialogs)
SIDEBAR_STYLE = E('VIDRO_SIDEBAR_STYLE', 'line')    # line | filled | colored
SIDEBAR_COLOR = E('VIDRO_SIDEBAR_COLOR', GLYPH_COLOR)
try: SIDEBAR_STROKE = max(0.8, min(2.2, float(E('VIDRO_SIDEBAR_STROKE', '1.3'))))
except ValueError: SIDEBAR_STROKE = 1.3
SIDEBAR_COLORS = {'home': '#5b8def', 'desktop': '#a371f7', 'documents': '#58a6ff', 'download': '#3fb950', 'music': '#f778ba',
              'pictures': '#39c5cf', 'video': '#bc8cff', 'templates': '#d29922', 'share': '#f0883e', 'games': '#e5534b',
              'recent': '#d29922', 'network': '#39c5cf', 'trash': '#8b949e', 'cloud': '#58a6ff', 'git': '#f0883e', None: '#8b949e'}

# ---------- glyphs (strokes in a 16x16 box) ----------
G = {
 'home':      '<path d="M2 8 8 2.6 14 8M4 6.6V14h8V6.6"/><path d="M6.8 14v-3.6h2.4V14"/>',
 'documents': '<path d="M4 1.8h5.6L12.5 4.7V14.2H4Z"/><path d="M6 7.5h4.5M6 10h4.5M6 12.3h3"/>',
 'download':  '<path d="M8 2v8.6M4.6 7.4 8 10.8l3.4-3.4M3 14h10"/>',
 'music':     '<circle cx="5" cy="12.3" r="1.9"/><circle cx="12" cy="10.8" r="1.9"/><path d="M6.9 12.3V3.6L13.9 2v8.8"/>',
 'pictures':  '<rect x="2" y="3" width="12" height="10" rx="1.8"/><path d="M2.6 12 6.5 8.2l3 2.8 1.8-1.6 2.3 2.1"/><circle cx="10.8" cy="6.1" r="1"/>',
 'video':     '<rect x="1.6" y="3.4" width="12.8" height="9.2" rx="2"/><path d="M6.6 6v4l3.4-2Z" fill="{c}"/>',
 'desktop':   '<rect x="2" y="2.5" width="12" height="8.5" rx="1.3"/><path d="M5.8 14h4.4M8 11v3"/>',
 'templates': '<rect x="2.5" y="2" width="11" height="12" rx="1.5"/><path d="M2.5 6h11M6.5 6v8"/>',
 'share':     '<circle cx="4" cy="8" r="1.8"/><circle cx="12" cy="3.8" r="1.8"/><circle cx="12" cy="12.2" r="1.8"/><path d="M5.6 7.1 10.4 4.7M5.6 8.9l4.8 2.4"/>',
 'git':       '<circle cx="4.6" cy="3.4" r="1.6"/><circle cx="4.6" cy="12.6" r="1.6"/><circle cx="11.4" cy="6.4" r="1.6"/><path d="M4.6 5v6M11.4 8c0 2.4-3 2.6-5.6 3.6"/>',
 'cloud':     '<path d="M4.6 12.5h7a2.9 2.9 0 0 0 .4-5.8A4 4 0 0 0 4.3 7.4a2.6 2.6 0 0 0 .3 5.1Z"/>',
 'games':     '<rect x="1.6" y="4.4" width="12.8" height="7.6" rx="3.6"/><path d="M5 6.8v2.8M3.6 8.2h2.8"/><circle cx="10.6" cy="7.4" r=".6" fill="{c}"/><circle cx="11.8" cy="9.2" r=".6" fill="{c}"/>',
 'recent':    '<circle cx="8" cy="8" r="6"/><path d="M8 4.6V8l2.4 1.6"/>',
 'bookmark':  '<path d="M4.5 2h7v12L8 11 4.5 14Z"/>',
 'star':      '<path d="m8 2 1.8 3.7 4 .6-2.9 2.8.7 4L8 11.2l-3.6 1.9.7-4-2.9-2.8 4-.6Z"/>',
 'lock':      '<rect x="3.2" y="7" width="9.6" height="7" rx="1.6"/><path d="M5.2 7V5a2.8 2.8 0 0 1 5.6 0v2"/>',
 'script':    '<path d="M3 4.6 6.4 8 3 11.4M8 12h5"/>',
 'build':     '<circle cx="8" cy="8" r="2.2"/><path d="M8 1.8v2M8 12.2v2M1.8 8h2M12.2 8h2M3.6 3.6 5 5M11 11l1.4 1.4M3.6 12.4 5 11M11 5l1.4-1.4"/>',
 'archive':   '<rect x="2" y="2.6" width="12" height="3.4" rx="1"/><path d="M3 6v6.6A1.4 1.4 0 0 0 4.4 14h7.2a1.4 1.4 0 0 0 1.4-1.4V6M6.4 8.6h3.2"/>',
 'camera':    '<path d="M2 5.6A1.4 1.4 0 0 1 3.4 4.2h1.8l1.2-1.6h3.2l1.2 1.6h1.8A1.4 1.4 0 0 1 14 5.6v6.4a1.4 1.4 0 0 1-1.4 1.4H3.4A1.4 1.4 0 0 1 2 12Z"/><circle cx="8" cy="8.6" r="2.4"/>',
 'mail':      '<rect x="1.8" y="3.4" width="12.4" height="9.2" rx="1.6"/><path d="m2.4 4.2 5.6 4.6 5.6-4.6"/>',
 'important': '<path d="M8 2.6v7"/><circle cx="8" cy="13" r=".8" fill="{c}"/>',
 'print':     '<path d="M4.4 6V2h7.2v4M4.4 11.4H2.6V6.6A1 1 0 0 1 3.6 6h8.8a1 1 0 0 1 1 .6v4.8h-1.8"/><rect x="4.4" y="9.4" width="7.2" height="4.6"/>',
 'search':    '<circle cx="7" cy="7" r="4.4"/><path d="m10.2 10.2 3.6 3.6"/>',
 'stack':     '<path d="m8 2 6 3.2-6 3.2-6-3.2Z"/><path d="m2 8.2 6 3.2 6-3.2M2 11.2l6 3.2 6-3.2"/>',
 'grid':      '<rect x="2.4" y="2.4" width="4.6" height="4.6" rx="1"/><rect x="9" y="2.4" width="4.6" height="4.6" rx="1"/><rect x="2.4" y="9" width="4.6" height="4.6" rx="1"/><rect x="9" y="9" width="4.6" height="4.6" rx="1"/>',
 'system':    '<path d="M8 1.8 13.4 4v4.2c0 3-2.4 5.2-5.4 6-3-.8-5.4-3-5.4-6V4Z"/>',
 'network':   '<circle cx="8" cy="8" r="6"/><path d="M2 8h12M8 2c-2.4 3.4-2.4 8.6 0 12M8 2c2.4 3.4 2.4 8.6 0 12"/>',
 'android':   '<path d="M3.6 9.6a4.4 4.4 0 0 1 8.8 0v3H3.6Z"/><path d="m4.8 5.4-1.2-1.8M11.2 5.4l1.2-1.8"/>',
 'book':      '<path d="M2.4 3.4c2-.8 3.8-.6 5.6.6 1.8-1.2 3.6-1.4 5.6-.6v9.4c-2-.8-3.8-.6-5.6.6-1.8-1.2-3.6-1.4-5.6-.6Z"/><path d="M8 4v9.4"/>',
 'trash':     None,
}
FOLDER_RULES = [  # (regex no nome, glifo) — a primeira que casar vence
 (r'home', 'home'), (r'document|text', 'documents'), (r'download', 'download'),
 (r'music|audio|podcast', 'music'), (r'picture|image|photo', 'pictures'), (r'video|movie', 'video'),
 (r'desktop', 'desktop'), (r'template', 'templates'), (r'public|share', 'share'),
 (r'git', 'git'), (r'cloud|drive|dropbox|nextcloud|owncloud|remote|mega|sync', 'cloud'),
 (r'game|steam', 'games'), (r'recent', 'recent'), (r'bookmark', 'bookmark'),
 (r'favorite|starred|favourite', 'star'), (r'lock|crypt|private|vault', 'lock'),
 (r'script|code|dev|develop|programming|project', 'script'), (r'build|config|setting', 'build'),
 (r'tar|archive|backup|zip', 'archive'), (r'camera|dcim', 'camera'), (r'mail|inbox', 'mail'),
 (r'important', 'important'), (r'print', 'print'), (r'search', 'search'), (r'stack', 'stack'),
 (r'activit|apps|application', 'grid'), (r'system|root|admin', 'system'),
 (r'network|remote|server|smb|ftp|nfs|ssh|dav', 'network'), (r'android', 'android'), (r'book|library', 'book'),
]

def glyph(name, x, y, size, color=GLYPH_COLOR, width=1.6, opacity=0.9):
    g = G[name].replace('{c}', color)
    s = size / 16
    return (f'<g transform="translate({x} {y}) scale({s})" fill="none" stroke="{color}" stroke-opacity="{opacity}" '
            f'stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round">{g}</g>')

def svg(body, defs=''):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
            f'<defs>{defs}</defs>{body}</svg>\n')

def folder(gname=None, opened=False):
    defs = (f'<linearGradient id="f" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{PF1}"/><stop offset="1" stop-color="{PF2}"/></linearGradient>'
            f'<linearGradient id="b" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{PB1}"/><stop offset="1" stop-color="{PB2}"/></linearGradient>')
    back = ('<path d="M9 9.5h13.2a3 3 0 0 1 2.4 1.2L27.4 14.5H55a5 5 0 0 1 5 5V49a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5V14.5a5 5 0 0 1 5-5Z" '
            'fill="url(#b)" stroke="#fff" stroke-opacity=".07"/>')
    paper = '<rect x="9" y="17.5" width="46" height="16" rx="2" fill="#c9cbd3" fill-opacity=".75"/>'
    if opened:
        front = ('<path d="M8.6 26.5a4 4 0 0 1 3.8-2.8H59a3 3 0 0 1 2.8 4l-6 20.6A5 5 0 0 1 51 52H9a5 5 0 0 1-4.8-6.4Z" '
                 'fill="url(#f)" stroke="#fff" stroke-opacity=".10"/>'
                 '<path d="M12.4 24.2H59" stroke="#fff" stroke-opacity=".18"/>')
        gx, gy = 23.5, 30
    else:
        front = ('<path d="M4 26a5 5 0 0 1 5-5H55a5 5 0 0 1 5 5V49a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5Z" '
                 'fill="url(#f)" stroke="#fff" stroke-opacity=".10"/>'
                 f'<path d="M9 21.6H55" stroke="#fff" stroke-opacity="{PBRILHO}"/>')
        gx, gy = 23, 29.2
    body = back + paper + front + (glyph(gname, gx, gy, 18, color=PGLIFO, width=1.5, opacity=.95) if gname else '')
    return svg(body, defs)

def trash(full=False):
    defs = '<linearGradient id="t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a3c45"/><stop offset="1" stop-color="#1a1b20"/></linearGradient>'
    body = ''
    if full:
        body += ('<rect x="21" y="7" width="11" height="10" rx="2" transform="rotate(-14 26.5 12)" fill="#c9cbd3" fill-opacity=".75"/>'
                 '<rect x="31" y="6" width="12" height="11" rx="2" transform="rotate(10 37 11.5)" fill="#9fa2ac" fill-opacity=".75"/>')
    body += ('<rect x="12" y="15" width="40" height="5" rx="2.5" fill="#4a4d57"/>'
             '<path d="M15 20h34l-3 34a4 4 0 0 1-4 3.6H22a4 4 0 0 1-4-3.6Z" fill="url(#t)" stroke="#fff" stroke-opacity=".10"/>'
             '<path d="M26 27v22M32 27v22M38 27v22" stroke="#d9dae0" stroke-opacity=".55" stroke-width="2" stroke-linecap="round"/>')
    return svg(body, defs)

# ---------- files ----------
CAT_COLORS = {'pdf':'#e5534b','image':'#58a6ff','video':'#bc8cff','audio':'#f778ba','archive':'#d29922',
              'code':'#3fb950','text':'#9da5b4','sheet':'#3fb950','slides':'#f0883e','doc':'#58a6ff',
              'font':'#c9cbd3','exec':'#8b949e','disk':'#8b949e','package':'#d29922','web':'#f0883e','generic':'#8b949e'}
DOC_GLYPH = {'image':'pictures','video':'video','audio':'music','archive':'archive','code':'script','exec':'build',
             'disk':'archive','package':'archive','web':'network','pdf':None,'text':None,'doc':None,'sheet':None,'slides':None,'font':None,'generic':None}
EXT = {'pdf':'PDF','x-python':'PY','javascript':'JS','x-javascript':'JS','json':'JSON','xml':'XML','html':'HTML','x-csrc':'C',
       'x-chdr':'H','x-c++src':'C++','x-java':'JAVA','x-rust':'RS','x-go':'GO','x-ruby':'RB','x-php':'PHP','x-shellscript':'SH',
       'markdown':'MD','x-markdown':'MD','css':'CSS','x-csharp':'C#','x-kotlin':'KT','x-lua':'LUA','x-sql':'SQL','x-yaml':'YAML',
       'x-tex':'TEX','csv':'CSV','plain':'TXT','x-log':'LOG','zip':'ZIP','x-7z-compressed':'7Z','x-rar':'RAR','vnd.rar':'RAR',
       'x-tar':'TAR','x-compressed-tar':'TGZ','gzip':'GZ','x-xz':'XZ','x-iso9660-image':'ISO','x-cd-image':'ISO','x-rpm':'RPM',
       'vnd.debian.binary-package':'DEB','x-deb':'DEB','x-flatpak':'PAK','vnd.flatpak':'PAK','x-appimage':'APP','x-desktop':'APP',
       'x-executable':'EXE','x-ms-dos-executable':'EXE','x-msi':'MSI','png':'PNG','jpeg':'JPG','gif':'GIF','svg+xml':'SVG','webp':'WEBP',
       'mpeg':'MP3','mp4':'MP4','x-matroska':'MKV','webm':'WEBM','flac':'FLAC','ogg':'OGG','x-wav':'WAV','epub+zip':'EPUB'}

def classify(n):
    m = n.lower()
    if 'pdf' in m: return 'pdf'
    if m.startswith('image') or 'image-x' in m or re.search(r'png|jpe?g|gif|svg|bmp|tiff|webp|raw|photo|picture|drawing|graphics', m): return 'image'
    if m.startswith('video') or re.search(r'video|movie|matroska|mp4|avi|webm', m): return 'video'
    if m.startswith('audio') or re.search(r'audio|sound|music|mp3|flac|ogg|wav|midi', m): return 'audio'
    if re.search(r'iso|cd-image|disk|dmg|img\b|floppy', m): return 'disk'
    if re.search(r'rpm|deb|package|flatpak|snap|appimage|apk', m): return 'package'
    if re.search(r'zip|tar|rar|7z|compress|archive|gzip|bzip|xz|lzma|zstd|cpio|cab', m): return 'archive'
    if re.search(r'spreadsheet|calc|excel|xls|csv|sheet|ods', m): return 'sheet'
    if re.search(r'presentation|impress|powerpoint|ppt|slide|odp', m): return 'slides'
    if re.search(r'font|ttf|otf|woff', m): return 'font'
    if re.search(r'html|web|url|bookmark', m): return 'web'
    if re.search(r'exec|desktop|shellscript|msdos|msi|binary|sharedlib|object|library|java-archive|jar', m) and 'script' not in m.replace('shellscript', ''): return 'exec'
    if re.search(r'script|src|source|hdr|python|java|javascript|json|xml|yaml|css|sql|rust|golang|php|ruby|perl|lua|makefile|cmake|patch|diff|code', m): return 'code'
    if re.search(r'word|document|writer|odt|rtf|msword|abiword|epub|ebook|richtext', m): return 'doc'
    if m.startswith('text') or 'text' in m: return 'text'
    return 'generic'

def label(n, cat):
    m = n.lower()
    parts = m.split('-', 1)
    sub = parts[1] if len(parts) > 1 else m
    for k in sorted(EXT, key=len, reverse=True):
        if sub == k or sub.endswith('-' + k) or m.endswith(k):
            return EXT[k]
    if cat in ('sheet',): return 'XLS' if 'ms' in m or 'excel' in m else 'ODS' if 'opendocument' in m else ''
    if cat in ('slides',): return 'PPT' if 'ms' in m or 'powerpoint' in m else 'ODP' if 'opendocument' in m else ''
    if cat == 'doc': return 'DOC' if 'msword' in m or 'ms-word' in m else 'ODT' if 'opendocument' in m else ''
    if cat == 'font': return 'FONT'
    return ''

def _mix(a, b, t):
    a = [int(a[i:i+2], 16) for i in (1, 3, 5)]; b = [int(b[i:i+2], 16) for i in (1, 3, 5)]
    return '#%02x%02x%02x' % tuple(round(x + (y - x) * t) for x, y in zip(a, b))

def document(n):
    cat = classify(n); lab = label(n, cat)
    col = CAT_COLORS[cat] if FILE_COLORS == 'type' else FILE_COLOR if FILE_COLORS == 'single' else '#9da5b4'
    r = FILE_RADIUS
    if FILE_STYLE == 'light': c1, c2, fold, edge = '#f6f7f9', '#dcdfe5', '#b9bdc7', '#000'
    elif FILE_STYLE == 'colored': c1, c2, fold, edge = _mix(col, '#2a2c33', .55), _mix(col, '#15161a', .78), _mix(col, '#ffffff', .25), '#fff'
    elif FILE_STYLE == 'flat': c1 = c2 = '#2c2e35'; fold, edge = '#4a4d57', '#fff'
    else: c1, c2, fold, edge = '#363841', '#1b1c21', '#555865', '#fff'
    defs = (f'<linearGradient id="p" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>')
    if FILE_FOLD:
        outline = f'M{12+r} 4h25.5L51 17.5V{60-r}a{r} {r} 0 0 1-{r} {r}H{12+r}a{r} {r} 0 0 1-{r}-{r}V{4+r}a{r} {r} 0 0 1 {r}-{r}Z'
    else:
        outline = f'M{12+r} 4H{51-r}a{r} {r} 0 0 1 {r} {r}V{60-r}a{r} {r} 0 0 1-{r} {r}H{12+r}a{r} {r} 0 0 1-{r}-{r}V{4+r}a{r} {r} 0 0 1 {r}-{r}Z'
    body = f'<path d="{outline}" fill="url(#p)" stroke="{edge}" stroke-opacity=".12"/>'
    if FILE_FOLD:
        body += f'<path d="M37.5 4v10.5a3 3 0 0 0 3 3H51Z" fill="{fold}"/>'
    if FILE_STYLE != 'claro':
        body += f'<path d="M{12+r+.5} 5.2H37" stroke="#fff" stroke-opacity=".14"/>'
    g = DOC_GLYPH.get(cat)
    if cat in ('text', 'doc', 'generic') and not g:
        body += '<path d="M20 26h20M20 32h22M20 38h16" stroke="#d9dae0" stroke-opacity=".5" stroke-width="2.2" stroke-linecap="round"/>'
    elif cat == 'sheet':
        body += '<rect x="19" y="23" width="25" height="18" rx="2" fill="none" stroke="#d9dae0" stroke-opacity=".6" stroke-width="2"/><path d="M19 29h25M19 35h25M27.5 23v18" stroke="#d9dae0" stroke-opacity=".6" stroke-width="2"/>'
    elif cat == 'slides':
        body += '<rect x="18" y="24" width="27" height="16" rx="2" fill="none" stroke="#d9dae0" stroke-opacity=".6" stroke-width="2"/><path d="M27 28.5v7l6-3.5Z" fill="#d9dae0" fill-opacity=".6"/>'
    elif cat == 'pdf':
        body += '<path d="M20 26h20M20 32h22M20 38h12" stroke="#d9dae0" stroke-opacity=".5" stroke-width="2.2" stroke-linecap="round"/>'
    elif cat == 'font':
        body += '<text x="31.5" y="40" font-family="serif" font-size="20" text-anchor="middle" fill="#d9dae0" fill-opacity=".75">Aa</text>'
    elif g:
        body += glyph(g, 22, 22, 19, width=1.5, opacity=.75)
    # subtle accent strip + label
    body += f'<rect x="12" y="47" width="39" height="0" />'
    if FILE_STYLE == 'light': col = _mix(col, '#000000', .3)
    if lab and FILE_LABEL:
        fs = 9 if len(lab) <= 3 else 7.5 if len(lab) == 4 else 6.5
        body += (f'<rect x="17" y="45" width="29" height="10" rx="3" fill="{col}" fill-opacity=".22"/>'
                 f'<text x="31.5" y="{50 + fs*0.36:.1f}" font-family="sans-serif" font-weight="700" font-size="{fs}" '
                 f'text-anchor="middle" fill="{col}" fill-opacity=".95" letter-spacing=".4">{lab}</text>')
    else:
        body += f'<rect x="24" y="49" width="15" height="3" rx="1.5" fill="{col}" fill-opacity=".8"/>'
    if FILE_STYLE == 'light':
        body = body.replace('#d9dae0', '#3a3d45')
    return svg(body, defs)

# ---------- assembly ----------
COLOR_PREFIX = r'^(blue|brown|custom|default|green|grey|gray|orange|pink|purple|red|yellow|black|teal|magenta|cyan|violet|white|nordic|deepblue|darkcyan|manjaro|ubuntu|black)-'
HOME_ALIASES = {'akonadi-phone-home','gnome-fs-home','gnome-home','go-home','gohome','go-home-large','gtg-home','gtk-home','kfm_home','redhat-home','stock_home','user-home'}
DESKTOP_ALIASES = {'desktop','gnome-fs-desktop','user-desktop','other-desktop'}

def place_icon(n):
    if n.endswith('-symbolic'): return None
    if 'trash' in n or n in ('edittrash','emptytrash'):
        return trash(full=bool(re.search(r'full', n)) or n == 'edittrash')
    if n in HOME_ALIASES: return folder('home')
    if n in DESKTOP_ALIASES: return folder('desktop')
    base = re.sub(COLOR_PREFIX, '', n)
    base = re.sub(r'folder_color_[a-z]+_?', 'folder-', base)
    if not re.search(r'folder|director|^user-|^inode', base): return None
    opened = bool(re.search(r'open|visiting|drag-accept|accept', base))
    rest = re.sub(r'folder|director(y)?|^user-|inode-|gnome-fs-|open|visiting|drag-accept|accept|[-_]', ' ', base)
    for rx, gname in FOLDER_RULES:
        if re.search(rx, rest): return folder(gname, opened)
    return folder(None, opened)

os.makedirs(f'{OUT}/scalable/places', exist_ok=True); os.makedirs(f'{OUT}/scalable/mimetypes', exist_ok=True)
np = nm = 0
for n in open(PLACES).read().split():
    s = place_icon(n)
    if s: open(f'{OUT}/scalable/places/{n}.svg', 'w').write(s); np += 1
for n in open(MIMES).read().split():
    if n.endswith('-symbolic'): continue
    if re.search(r'inode-directory|folder', n):
        open(f'{OUT}/scalable/mimetypes/{n}.svg', 'w').write(folder()); nm += 1; continue
    open(f'{OUT}/scalable/mimetypes/{n}.svg', 'w').write(document(n)); nm += 1
print('folders/places:', np, 'files:', nm)

# ---------- small versions (16/22 px): outline + glyph only, readable on dark backgrounds ----------
FOLDER_OUTLINE = '<path d="M1.8 4.2a1.2 1.2 0 0 1 1.2-1.2h3.3l1.4 1.6H13a1.2 1.2 0 0 1 1.2 1.2v6.8A1.2 1.2 0 0 1 13 13.8H3a1.2 1.2 0 0 1-1.2-1.2Z"/>'
TRASH_SMALL = '<path d="M2.8 4.4h10.4M6.2 4.2V2.6h3.6v1.6M4 4.4l.7 9a1 1 0 0 0 1 .9h4.6a1 1 0 0 0 1-.9l.7-9M6.8 7v4.6M9.2 7v4.6"/>'
def small(name):
    if name.endswith('-symbolic'): return None
    if 'trash' in name or name in ('edittrash','emptytrash'): inner = TRASH_SMALL
    else:
        if place_icon(name) is None: return None
        g = None
        if name in HOME_ALIASES: g = 'home'
        elif name in DESKTOP_ALIASES: g = 'desktop'
        else:
            base = re.sub(COLOR_PREFIX, '', name); base = re.sub(r'folder_color_[a-z]+_?', 'folder-', base)
            rest = re.sub(r'folder|director(y)?|^user-|inode-|gnome-fs-|open|visiting|drag-accept|accept|[-_]', ' ', base)
            for rx, gname in FOLDER_RULES:
                if re.search(rx, rest): g = gname; break
        inner = G[g] if g else FOLDER_OUTLINE
    return sidebar_svg(inner, 'trash' if inner is TRASH_SMALL else g)

def sidebar_svg(inner, g):
    """Small sidebar icon in the chosen style."""
    color = SIDEBAR_COLORS.get(g, SIDEBAR_COLORS[None]) if SIDEBAR_STYLE == 'colored' else SIDEBAR_COLOR
    if SIDEBAR_STYLE == 'filled':
        ink = '#16171b'
        return ('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">'
                f'<rect x=".5" y=".5" width="15" height="15" rx="4" fill="{color}" fill-opacity=".92"/>'
                f'<g transform="translate(8 8) scale(.68) translate(-8 -8)" fill="none" stroke="{ink}" stroke-width="{SIDEBAR_STROKE * 1.35:.2f}" '
                f'stroke-linecap="round" stroke-linejoin="round">{inner.replace("{c}", ink)}</g></svg>\n')
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">'
            f'<g fill="none" stroke="{color}" stroke-width="{SIDEBAR_STROKE}" stroke-linecap="round" stroke-linejoin="round">{inner.replace("{c}", color)}</g></svg>\n')
n16 = 0
for d in ('16/places', '22/places'):
    os.makedirs(f'{OUT}/{d}', exist_ok=True)
for n in open(PLACES).read().split():
    s = small(n)
    if s:
        for d in ('16/places', '22/places'):
            open(f'{OUT}/{d}/{n}.svg', 'w').write(s.replace('width="16" height="16"', 'width="22" height="22"') if d.startswith('22') else s)
        n16 += 1
print('small:', n16)

# sidebar items that are not folders (small versions only)
SIDEBAR_EXTRA = {'document-open-recent': 'recent', 'network-workgroup': 'network'}
for n, g in SIDEBAR_EXTRA.items():
    s = sidebar_svg(G[g], g)
    for d in ('16/places', '22/places'):
        open(f'{OUT}/{d}/{n}.svg', 'w').write(s)
print('sidebar extras:', len(SIDEBAR_EXTRA))
