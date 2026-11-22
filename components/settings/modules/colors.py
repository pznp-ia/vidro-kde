"""Colors: accent color (selection, focus, highlights — e.g. the selected folder in Dolphin) and text color.
Edits the "Vidro" color scheme (and kdeglobals when it is active); open apps update immediately.
The original values are kept in ~/.local/share/vidro/colors-original.json and come back when disabled."""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import DATA, VIDRO, hex_rgb, kread, kwrite, num

GROUP = 'Colors'
DEFAULTS = {
    'accent': 'theme',          # theme | custom
    'accent_color': '#3daee9',
    'strength': '100',          # 0-100: accent strength in selections (less = subtler selection)
    'text': 'theme',            # theme | custom
    'text_color': '#fcfcfc',
    'secondary': '41',          # 0-80: how much secondary text is dimmed
}
SCHEME = os.path.join(DATA, 'color-schemes', 'Vidro.colors')
ORIGINAL = os.path.join(VIDRO, 'colors-original.json')
OLD_ORIGINAL = os.path.join(VIDRO, 'cores-original.json')
GROUPS = ['Colors:Button', 'Colors:Complementary', 'Colors:Header', 'Colors:Header][Inactive', 'Colors:Selection',
          'Colors:Tooltip', 'Colors:View', 'Colors:Window']
KEYS = ['BackgroundNormal', 'BackgroundAlternate', 'DecorationFocus', 'DecorationHover', 'ForegroundNormal', 'ForegroundInactive']


def _rgb(text):
    return [int(x) for x in text.split(',')[:3]]


def _text(c):
    return ','.join(str(max(0, min(255, round(v)))) for v in c)


def _mix(a, b, t):
    return [x + (y - x) * t for x, y in zip(a, b)]


def _originals():
    if not os.path.exists(ORIGINAL) and os.path.exists(OLD_ORIGINAL):
        os.rename(OLD_ORIGINAL, ORIGINAL)
    if os.path.exists(ORIGINAL):
        return json.load(open(ORIGINAL))
    d = {g: {k: kread(SCHEME, g, k) for k in KEYS} for g in GROUPS}
    os.makedirs(os.path.dirname(ORIGINAL), exist_ok=True)
    json.dump(d, open(ORIGINAL, 'w'), indent=1)
    return d


def apply(cfg):
    if not os.path.exists(SCHEME):
        return
    o = _originals()
    new = {g: dict(v) for g, v in o.items()}
    sel0 = _rgb(o['Colors:Selection']['BackgroundNormal'])     # original accent
    alt0 = _rgb(o['Colors:Selection']['BackgroundAlternate'])
    # ---- accent ----
    if cfg.get('accent') == 'custom':
        a = list(hex_rgb(cfg.get('accent_color'), sel0))
        strength = num(cfg, 'strength', 0, 100, 100) / 100
        view = _rgb(o['Colors:View']['BackgroundNormal'])
        sel = _mix(view, a, max(0.25, strength))
        alt = _mix(view, a, max(0.15, strength) * 0.5)
        lum = (0.299 * sel[0] + 0.587 * sel[1] + 0.114 * sel[2]) / 255
        for g in GROUPS:
            for k in KEYS:
                v = o[g][k]
                if not v:
                    continue
                if _rgb(v) == sel0 and k in ('DecorationFocus', 'DecorationHover', 'BackgroundNormal'):
                    new[g][k] = _text(a if k != 'BackgroundNormal' else sel)
                elif _rgb(v) == alt0 and k == 'BackgroundAlternate':
                    new[g][k] = _text(alt)
        new['Colors:Selection']['ForegroundNormal'] = '20,20,24' if lum > 0.62 else '252,252,252'
    # ---- text ----
    if cfg.get('text') == 'custom':
        t = list(hex_rgb(cfg.get('text_color'), (252, 252, 252)))
        sec = num(cfg, 'secondary', 0, 80, 41) / 100
        for g in GROUPS:
            if g == 'Colors:Selection':
                continue
            bg = _rgb(o[g]['BackgroundNormal'] or '32,35,38')
            new[g]['ForegroundNormal'] = _text(t)
            new[g]['ForegroundInactive'] = _text(_mix(t, bg, sec))
    # ---- write to the scheme and, if active, to kdeglobals (notify apps only on the last write) ----
    active = kread('kdeglobals', 'General', 'ColorScheme') == 'Vidro'

    def owned(g, k):  # keys of this module (list backgrounds belong to the Dolphin module)
        if k in ('DecorationFocus', 'DecorationHover', 'ForegroundNormal', 'ForegroundInactive') or g == 'Colors:Selection':
            return True
        return k == 'BackgroundAlternate' and o[g][k] and _rgb(o[g][k]) == alt0
    changes = [(g, k, v) for g in GROUPS for k, v in new[g].items() if v and owned(g, k)]
    for i, (g, k, v) in enumerate(changes):
        kwrite(SCHEME, g, k, v)
        if active:
            kwrite('kdeglobals', g, k, v, notify=(i == len(changes) - 1))
