"""Ajudante dos módulos: fala com o plasmashell (scripts do Plasma) para ler e mudar
painéis e widgets na hora, sem reiniciar o Plasma."""
import json, subprocess


def script(js):
    """Roda um script do Plasma e devolve o que ele imprimiu (print)."""
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
    """Roda um script que faz print(JSON.stringify(...)) e devolve o objeto (ou None)."""
    t = script(js)
    try:
        return json.loads(t)
    except ValueError:
        return None


def js_str(s):
    return json.dumps(str(s))


# script que encontra o painel principal (o que tem o menu iniciar; senão o primeiro)
PAINEL = '''
var LANC = ["org.kde.plasma.kickoff", "org.kde.plasma.kicker", "org.kde.plasma.kickerdash"];
function painelPrincipal() {
    var ps = panels();
    for (var i = 0; i < ps.length; i++) {
        var ws = ps[i].widgets();
        for (var j = 0; j < ws.length; j++) if (LANC.indexOf(ws[j].type) >= 0) return ps[i];
    }
    return ps.length ? ps[0] : null;
}
function widgetsDe(p, tipos) {
    var out = [];
    if (!p) return out;
    var ws = p.widgets();
    for (var j = 0; j < ws.length; j++) if (tipos.indexOf(ws[j].type) >= 0) out.push(ws[j]);
    return out;
}
function ler(w, grupo, chave) { w.currentConfigGroup = [grupo]; return w.readConfig(chave); }
function gravar(w, grupo, chave, valor) {
    w.currentConfigGroup = [grupo];
    if (String(w.readConfig(chave)) !== String(valor)) { w.writeConfig(chave, valor); return 1; }
    return 0;
}
'''
