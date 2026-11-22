"""Taskbar (main panel): size, floating, opacity, hiding, position; app icons (task manager)
and clock; optional own glass for the panel background. Changes live through plasmashell.
The values shown in the app come from your panel (current()), so nothing changes until you edit them."""
import gzip, json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
import _plasma as P

GROUP = 'Panel'
# panel properties: key -> (script property, default, type)
PANEL = {
    'height': ('height', '44', 'int'),
    'floating': ('floating', 'true', 'bool'),
    'opacity': ('opacity', 'translucent', 'str'),     # adaptive | opaque | translucent
    'hiding': ('hiding', 'none', 'str'),               # none | autohide | dodgewindows | windowsgobelow
    'length': ('lengthMode', 'fill', 'str'),           # fill | fit
    'alignment': ('alignment', 'center', 'str'),      # left | center | right
    'location': ('location', 'bottom', 'str'),           # bottom | top | left | right
}
TASKS_TYPES = ['org.kde.plasma.icontasks', 'org.kde.plasma.taskmanager']
TASKS = {  # key -> (widget key, default, type); group General
    'icon_spacing': ('iconSpacing', '1', 'int'),
    'grouping': ('groupingStrategy', '1', 'int'),
    'current_desktop_only': ('showOnlyCurrentDesktop', 'true', 'bool'),
    'current_screen_only': ('showOnlyCurrentScreen', 'false', 'bool'),
    'audio_indicator': ('indicateAudioStreams', 'true', 'bool'),
    'tooltips': ('showToolTips', 'true', 'bool'),
    'hover_effect': ('taskHoverEffect', 'true', 'bool'),
    'highlight_windows': ('highlightWindows', 'false', 'bool'),
    'middle_click': ('middleClickAction', '2', 'int'),
    'rows': ('maxStripes', '1', 'int'),
}
SHOWDESKTOP_TYPES = ['org.kde.plasma.showdesktop']
SHOWDESKTOP = {  # group General
    'showdesktop_icon': ('icon', 'user-desktop-symbolic', 'str'),
}
CLOCK_TYPES = ['org.kde.plasma.digitalclock']
CLOCK = {  # group Appearance
    'clock_seconds': ('showSeconds', '1', 'int'),            # 0 never, 1 in tooltip, 2 always
    'clock_date': ('showDate', 'true', 'bool'),
    'date_format': ('dateFormat', 'shortDate', 'str'), # shortDate | longDate | isoDate | custom
    'custom_date': ('customDateFormat', 'ddd d', 'str'),
    'date_position': ('dateDisplayFormat', '0', 'int'),  # 0 automatic, 1 beside, 2 below
    'hour_format': ('use24hFormat', '1', 'int'),              # 0 12 h, 1 from locale, 2 24 h
    'clock_bold': ('boldText', 'false', 'bool'),
    'clock_auto_font': ('autoFontAndSize', 'true', 'bool'),
    'clock_font_size': ('fontSize', '10', 'int'),
}
GLASS = {  # panel background look (Plasma style "Vidro"); only touched when glass_enabled = true
    'glass_enabled': 'false', 'glass_radius': '6', 'glass_opacity': '42', 'glass_border': '0',
    'glass_shadow': '0', 'glass_background': 'theme', 'glass_color': '#1c1e24',
}
DEFAULTS = {**GLASS, **{k: v[1] for k, v in PANEL.items()},
           **{k: v[1] for k, v in TASKS.items()},
           **{k: v[1] for k, v in CLOCK.items()},
           **{k: v[1] for k, v in SHOWDESKTOP.items()}}


def current():
    js = P.PANEL_JS + 'var p = mainPanel(); var o = {}; if (p) {' + ''.join(
        f'o[{json.dumps(k)}] = p.{v[0]};' for k, v in PANEL.items()) + \
        'var t = widgetsOf(p, ' + json.dumps(TASKS_TYPES) + ')[0]; if (t) {' + ''.join(
        f'o[{json.dumps(k)}] = readCfg(t, "General", {json.dumps(v[0])});' for k, v in TASKS.items()) + \
        '} var c = widgetsOf(p, ' + json.dumps(CLOCK_TYPES) + ')[0]; if (c) {' + ''.join(
        f'o[{json.dumps(k)}] = readCfg(c, "Appearance", {json.dumps(v[0])});' for k, v in CLOCK.items()) + \
        '} var d = widgetsOf(p, ' + json.dumps(SHOWDESKTOP_TYPES) + ')[0]; if (d) {' + ''.join(
        f'o[{json.dumps(k)}] = readCfg(d, "General", {json.dumps(v[0])});' for k, v in SHOWDESKTOP.items()) + \
        '} } print(JSON.stringify(o));'
    o = P.script_json(js) or {}
    return {k: str(v).lower() if isinstance(v, bool) else str(v) for k, v in o.items() if v not in ('', None)}


def _value(v, default, kind):
    v = str(v)
    if kind == 'bool':
        return 'true' if v == 'true' else 'false'
    if kind == 'int':
        try:
            return str(int(float(v)))
        except ValueError:
            return default
    return v


def apply(cfg):
    js = [P.PANEL_JS, 'var p = mainPanel(); if (p) {']
    for k, (prop, default, kind) in PANEL.items():
        v = _value(cfg.get(k, default), default, kind)
        if kind == 'int':
            js.append(f'if (p.{prop} != {v}) p.{prop} = {v};')
        elif kind == 'bool':
            js.append(f'if (p.{prop} != {v}) p.{prop} = {v};')
        else:
            js.append(f'if (p.{prop} != {json.dumps(v)}) p.{prop} = {json.dumps(v)};')
    for kinds, options, group in ((TASKS_TYPES, TASKS, 'General'), (CLOCK_TYPES, CLOCK, 'Appearance'), (SHOWDESKTOP_TYPES, SHOWDESKTOP, 'General')):
        js.append(f'widgetsOf(p, {json.dumps(kinds)}).forEach(function (w) {{ var n = 0;')
        for k, (key, default, kind) in options.items():
            js.append(f'n += writeCfg(w, {json.dumps(group)}, {json.dumps(key)}, {json.dumps(_value(cfg.get(k, default), default, kind))});')
        js.append('if (n) w.reloadConfig(); });')
    js.append('}')
    P.script(''.join(js))
    _glass(cfg)


DATA = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
THEME = os.path.join(DATA, 'plasma', 'desktoptheme', 'Vidro')
TEMPLATES = os.path.join(DATA, 'vidro', 'templates')
LAST = os.path.expanduser('~/.cache/vidro/panel-glass')
FILES = {  # file in the theme -> original template
    os.path.join('translucent', 'widgets', 'panel-background.svgz'): 'translucent-widgets-panel-background.svg',
    os.path.join('widgets', 'panel-background.svgz'): 'widgets-panel-background.svg',
}


def _glass_svg(cfg, template):
    import popups
    from _common import num
    R = int(num(cfg, 'glass_radius', 0, 30, 6))
    op = num(cfg, 'glass_opacity', 5, 100, 42) / 100
    border = num(cfg, 'glass_border', 0, 60, 0) / 100
    strength = num(cfg, 'glass_shadow', 0, 100, 0) / 100 * 0.5
    color = cfg.get('glass_color', '') if cfg.get('glass_background') == 'custom' else None
    if color and not re.fullmatch(r'#[0-9a-fA-F]{6}', color):
        color = None
    svg = popups.dialog_svg(max(R, 2), op, border, strength, 10, color, margin=4)
    # floating-panel sizes ("inset" hints) copied from the original
    extra = ''.join(re.findall(r'<rect[^>]*id="(?:shadow-)?hint-[a-z]+-inset"[^>]*/>', template, re.S))
    return svg.replace('</svg>', extra + '</svg>')


def _glass(cfg):
    key = json.dumps({k: cfg.get(k) for k in GLASS}, sort_keys=True)
    try:
        if open(LAST).read() == key:
            return
    except OSError:
        if cfg.get('glass_enabled') != 'true':
            return  # never touched: leave it as it is
    if not os.path.isdir(THEME):
        return
    for name, tpl in FILES.items():
        target, template = os.path.join(THEME, name), os.path.join(TEMPLATES, tpl)
        if not (os.path.isfile(template) and os.path.isdir(os.path.dirname(target))):
            continue
        text = open(template).read()
        if cfg.get('glass_enabled') == 'true':
            text = _glass_svg(cfg, text)
        with gzip.open(target, 'wb') as f:
            f.write(text.encode())
    os.makedirs(os.path.dirname(LAST), exist_ok=True)
    open(LAST, 'w').write(key)
    import popups
    popups.reload_theme()
