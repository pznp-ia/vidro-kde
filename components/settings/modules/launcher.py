"""Launcher: menu type (Kickoff, classic menu, fullscreen) and Kickoff options.
Changes live through plasmashell. The values shown in the app come from your panel (current()),
so nothing changes until you edit them."""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import _plasma as P

GROUP = 'Launcher'
TYPES = {'kickoff': 'org.kde.plasma.kickoff', 'classic': 'org.kde.plasma.kicker', 'fullscreen': 'org.kde.plasma.kickerdash'}
# vidrorc key -> (widget key, Plasma default, type)
OPTIONS = {
    'favorites': ('favoritesDisplay', '0', 'int'),        # 0 grid, 1 list
    'applications': ('applicationsDisplay', '1', 'int'),  # 0 grid, 1 list
    'compact': ('compactMode', 'false', 'bool'),
    'sidebar_right': ('paneSwap', 'false', 'bool'),
    'switch_on_hover': ('switchCategoryOnHover', 'false', 'bool'),
    'footer': ('primaryActions', '0', 'int'),            # 0 power, 1 session, 3 both
    'captions': ('showActionButtonCaptions', 'true', 'bool'),
    'name_format': ('appNameFormat', '2', 'int'),        # 0 name, 1 description, 2 name+description, 3 description+name
    'alphabetical': ('alphaSort', 'false', 'bool'),
    'highlight_new': ('highlightNewlyInstalledApps', 'true', 'bool'),
    'icon': ('icon', 'start-here-kde-symbolic', 'str'),
    'label': ('menuLabel', '', 'str'),
}
DEFAULTS = {'type': 'kickoff', **{k: v[1] for k, v in OPTIONS.items()}}


def current():
    """Current values in the panel (so the app shows what you already have)."""
    js = P.PANEL_JS + 'var k = widgetsOf(mainPanel(), LAUNCHERS)[0]; var o = {};' \
        'if (k) { o.__type = k.type;' + ''.join(
            f'o[{json.dumps(k)}] = readCfg(k, "General", {json.dumps(v[0])});' for k, v in OPTIONS.items()) + \
        '} print(JSON.stringify(o));'
    o = P.script_json(js) or {}
    out = {}
    kind = o.pop('__type', None)
    for name, plug in TYPES.items():
        if plug == kind:
            out['type'] = name
    for k, v in o.items():
        if v not in ('', None):
            out[k] = str(v)
    return out


def _switch_type(plug):
    """Replace the launcher widget with another type at the same place in the panel, keeping its options."""
    js = P.PANEL_JS + f'''
var p = mainPanel(); var old = widgetsOf(p, LAUNCHERS)[0];
if (p && old && old.type !== {json.dumps(plug)}) {{
    p.currentConfigGroup = ["General"];
    var order = String(p.readConfig("AppletOrder") || "").split(";");
    old.currentConfigGroup = ["General"];
    var keys = old.configKeys, values = {{}};
    for (var c = 0; c < keys.length; c++) values[keys[c]] = old.readConfig(keys[c]);
    // the panel inserts the new widget at the given point (x, y): use the old one's place
    var g = old.geometry;
    var added = p.addWidget({json.dumps(plug)}, g.x + 1, g.y + 1, g.width, g.height);
    for (var c2 in values) writeCfg(added, "General", c2, values[c2]);
    old.remove();
    print("switched");
}}'''
    return P.script(js)


def apply(cfg):
    plug = TYPES.get(cfg.get('type', 'kickoff'), TYPES['kickoff'])
    _switch_type(plug)
    lines = []
    for k, (key, default, kind) in OPTIONS.items():
        v = str(cfg.get(k, default))
        if kind == 'bool':
            v = 'true' if v == 'true' else 'false'
        elif kind == 'int':
            v = str(int(float(v))) if v.replace('.', '', 1).lstrip('-').isdigit() else default
        lines.append(f'n += writeCfg(k, "General", {json.dumps(key)}, {json.dumps(v)});')
    js = P.PANEL_JS + 'var n = 0; widgetsOf(mainPanel(), LAUNCHERS).forEach(function (k) {' + ''.join(lines) + \
        'if (n) k.reloadConfig(); }); print(n);'
    P.script(js)
