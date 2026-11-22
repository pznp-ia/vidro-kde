"""NotepadK options: editor font, color theme, line spacing, word wrap, and the focus-mode plugin
(fade duration, drag strip height, open in focus mode). Written to NotepadK's own katerc;
the normal Kate is unchanged. Takes effect the next time NotepadK opens."""
import configparser, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import DATA, flag, num

GROUP = 'NotepadK'
DEFAULTS = {
    'font_family': 'Noto Sans Mono',
    'font_size': '11',
    'color_theme': 'auto',      # auto (follows light/dark) | a KSyntaxHighlighting theme name
    'line_height': '1.2',       # line spacing multiplier
    'word_wrap': 'true',
    'fade_ms': '320',           # focus <-> full interface transition
    'strip_height': '30',       # invisible drag strip at the top in focus mode
    'start_focused': 'true',    # open in focus mode
    # window
    'window_opacity': '100',    # % (whole window, via KWin)
    'keep_above': 'false',      # focus mode: always on top
    'hide_titlebar': 'true',    # focus mode: no titlebar
    'show_button': 'true',      # floating focus/interface button
    'button_opacity': '35',     # % when idle
    # animations
    'transition': 'fade',       # fade | slide | zoom | none
    'easing': 'smooth',         # smooth | fast | bounce | linear
    'open_animation': 'true',   # text fades in when NotepadK opens
    # text block
    'margin': '24',             # side margin (px)
    'margin_top': '8',          # top/bottom margin (px)
    'column_chars': '0',        # 0 = full width; N = centered column of ~N characters
    'current_line': 'false',    # subtle highlight of the current line
    'word_count': 'false',      # discreet word counter (bottom right)
    'typewriter': 'false',      # keeps the cursor line near the middle
}
_INTS = {'window_opacity': ('WindowOpacity', 30, 100), 'button_opacity': ('ButtonOpacity', 5, 100),
         'margin': ('Margin', 0, 300), 'margin_top': ('MarginTop', 0, 200), 'column_chars': ('ColumnChars', 0, 200)}
_FLAGS = {'keep_above': 'KeepAbove', 'hide_titlebar': 'HideTitlebar', 'show_button': 'ShowButton',
          'open_animation': 'OpenAnimation', 'current_line': 'CurrentLine', 'word_count': 'WordCount'}
_CHOICES = {'transition': ('Transition', ('fade', 'slide', 'zoom', 'none')), 'easing': ('Easing', ('smooth', 'fast', 'bounce', 'linear'))}


def _katerc():
    for base in ('notepadk', 'kate-vidro'):
        p = os.path.join(DATA, base, 'config', 'katerc')
        if os.path.isfile(p):
            return p
    return None


def _load(path):
    c = configparser.RawConfigParser(strict=False, interpolation=None)
    c.optionxform = str
    c.read(path)
    return c


def current():
    path = _katerc()
    if not path:
        return {}
    c = _load(path)
    out = {}
    r = 'KTextEditor Renderer'
    if c.has_option(r, 'Text Font'):
        parts = c.get(r, 'Text Font').split(',')
        out['font_family'], out['font_size'] = parts[0], parts[1] if len(parts) > 1 else '11'
    if c.has_option(r, 'Auto Color Theme Selection') and c.get(r, 'Auto Color Theme Selection') == 'true':
        out['color_theme'] = 'auto'
    elif c.has_option(r, 'Color Theme'):
        out['color_theme'] = c.get(r, 'Color Theme')
    if c.has_option(r, 'Line Height Multiplier'):
        out['line_height'] = c.get(r, 'Line Height Multiplier')
    v = 'KTextEditor View'
    if c.has_option(v, 'Dynamic Word Wrap'):
        out['word_wrap'] = c.get(v, 'Dynamic Word Wrap')
    n = 'NotepadK'
    for key, name in (('fade_ms', 'FadeMs'), ('strip_height', 'StripHeight')):
        if c.has_option(n, name):
            out[key] = c.get(n, name)
    for key, (name, _a, _b) in _INTS.items():
        if c.has_option(n, name):
            out[key] = c.get(n, name)
    for key, name in _FLAGS.items():
        if c.has_option(n, name):
            out[key] = 'true' if c.get(n, name) in ('1', 'true') else 'false'
    for key, (name, _opts) in _CHOICES.items():
        if c.has_option(n, name):
            out[key] = c.get(n, name)
    if c.has_option(v, 'Auto Center Lines'):
        out['typewriter'] = 'true' if c.get(v, 'Auto Center Lines') not in ('0', '') else 'false'
    if c.has_option(n, 'StartFocused'):
        out['start_focused'] = 'true' if c.get(n, 'StartFocused') in ('1', 'true') else 'false'
    return out


def apply(cfg):
    path = _katerc()
    if not path:
        return   # NotepadK is not installed
    c = _load(path)
    for g in ('KTextEditor Renderer', 'KTextEditor View', 'NotepadK'):
        if not c.has_section(g):
            c.add_section(g)
    family = cfg.get('font_family', 'Noto Sans Mono').replace(',', ' ').strip() or 'Noto Sans Mono'
    size = int(num(cfg, 'font_size', 6, 40, 11))
    c.set('KTextEditor Renderer', 'Text Font', f'{family},{size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1')
    theme = cfg.get('color_theme', 'auto')
    c.set('KTextEditor Renderer', 'Auto Color Theme Selection', 'true' if theme == 'auto' else 'false')
    if theme != 'auto':
        c.set('KTextEditor Renderer', 'Color Theme', theme)
    c.set('KTextEditor Renderer', 'Line Height Multiplier', f"{num(cfg, 'line_height', 1, 2.5, 1.2):.2f}")
    c.set('KTextEditor View', 'Dynamic Word Wrap', 'true' if flag(cfg, 'word_wrap') else 'false')
    c.set('NotepadK', 'FadeMs', str(int(num(cfg, 'fade_ms', 0, 1500, 320))))
    c.set('NotepadK', 'StripHeight', str(int(num(cfg, 'strip_height', 16, 60, 30))))
    c.set('NotepadK', 'StartFocused', '1' if flag(cfg, 'start_focused') else '0')
    for key, (name, lo, hi) in _INTS.items():
        c.set('NotepadK', name, str(int(num(cfg, key, lo, hi, int(DEFAULTS[key])))))
    for key, name in _FLAGS.items():
        c.set('NotepadK', name, '1' if flag(cfg, key) else '0')
    for key, (name, opts) in _CHOICES.items():
        c.set('NotepadK', name, cfg.get(key) if cfg.get(key) in opts else DEFAULTS[key])
    c.set('KTextEditor View', 'Auto Center Lines', '200' if flag(cfg, 'typewriter') else '0')
    tmp = path + '.tmp'
    with open(tmp, 'w') as f:
        c.write(f, space_around_delimiters=False)
    os.replace(tmp, path)
