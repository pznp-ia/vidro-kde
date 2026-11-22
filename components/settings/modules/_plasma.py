"""Helper for modules: talks to plasmashell (Plasma scripts) to read and change
panels and widgets live, without restarting Plasma."""
import json, subprocess


def script(js):
    """Run a Plasma script and return what it printed (print)."""
    try:
        r = subprocess.run(['dbus-send', '--session', '--print-reply', '--dest=org.kde.plasmashell',
                            '/PlasmaShell', 'org.kde.PlasmaShell.evaluateScript', 'string:' + js],
                           capture_output=True, text=True, timeout=15)
    except (OSError, subprocess.TimeoutExpired):
        return ''
    out = r.stdout
    i = out.find('string "')
    if i < 0:
        return ''
    return out[i + 8:].rstrip().removesuffix('"')


def script_json(js):
    """Run a script that does print(JSON.stringify(...)) and return the object (or None)."""
    t = script(js)
    try:
        return json.loads(t)
    except ValueError:
        return None


def js_str(s):
    return json.dumps(str(s))


# JS helpers: the main panel is the one with the launcher (otherwise the first one)
PANEL_JS = '''
var LAUNCHERS = ["org.kde.plasma.kickoff", "org.kde.plasma.kicker", "org.kde.plasma.kickerdash"];
function mainPanel() {
    var ps = panels();
    for (var i = 0; i < ps.length; i++) {
        var ws = ps[i].widgets();
        for (var j = 0; j < ws.length; j++) if (LAUNCHERS.indexOf(ws[j].type) >= 0) return ps[i];
    }
    return ps.length ? ps[0] : null;
}
function widgetsOf(p, types) {
    var out = [];
    if (!p) return out;
    var ws = p.widgets();
    for (var j = 0; j < ws.length; j++) if (types.indexOf(ws[j].type) >= 0) out.push(ws[j]);
    return out;
}
function readCfg(w, group, key) { w.currentConfigGroup = [group]; return w.readConfig(key); }
function writeCfg(w, group, key, value) {
    w.currentConfigGroup = [group];
    if (String(w.readConfig(key)) !== String(value)) { w.writeConfig(key, value); return 1; }
    return 0;
}
'''
