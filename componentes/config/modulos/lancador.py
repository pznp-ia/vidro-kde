"""Menu iniciar: tipo de menu (Kickoff, menu clássico, tela cheia) e as opções do Kickoff.
Muda na hora pelo plasmashell. Os valores mostrados no app vêm do seu painel (atual()),
então nada muda até você mexer."""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import _plasma as P

GRUPO = 'Lancador'
TIPOS = {'kickoff': 'org.kde.plasma.kickoff', 'classico': 'org.kde.plasma.kicker', 'telacheia': 'org.kde.plasma.kickerdash'}
# chave no vidrorc -> (chave do widget, padrão do Plasma, tipo)
OPCOES = {
    'favoritos': ('favoritesDisplay', '0', 'int'),        # 0 grade, 1 lista
    'aplicativos': ('applicationsDisplay', '1', 'int'),   # 0 grade, 1 lista
    'compacto': ('compactMode', 'false', 'bool'),
    'lateral_direita': ('paneSwap', 'false', 'bool'),
    'passar_mouse': ('switchCategoryOnHover', 'false', 'bool'),
    'rodape': ('primaryActions', '0', 'int'),            # 0 energia, 1 sessão, 3 os dois
    'legendas': ('showActionButtonCaptions', 'true', 'bool'),
    'nomes': ('appNameFormat', '2', 'int'),              # 0 nome, 1 descrição, 2 nome+descrição, 3 descrição+nome
    'alfabetica': ('alphaSort', 'false', 'bool'),
    'novos': ('highlightNewlyInstalledApps', 'true', 'bool'),
    'icone': ('icon', 'start-here-kde-symbolic', 'str'),
    'texto': ('menuLabel', '', 'str'),
}
PADROES = {'tipo': 'kickoff', **{k: v[1] for k, v in OPCOES.items()}}


def atual():
    """Valores de agora no painel (para o app mostrar o que você já tem)."""
    js = P.PAINEL + 'var k = widgetsDe(painelPrincipal(), LANC)[0]; var o = {};' \
        'if (k) { o.__tipo = k.type;' + ''.join(
            f'o[{json.dumps(k)}] = ler(k, "General", {json.dumps(v[0])});' for k, v in OPCOES.items()) + \
        '} print(JSON.stringify(o));'
    o = P.script_json(js) or {}
    out = {}
    tipo = o.pop('__tipo', None)
    for nome, plug in TIPOS.items():
        if plug == tipo:
            out['tipo'] = nome
    for k, v in o.items():
        if v not in ('', None):
            out[k] = str(v)
    return out


def _trocar_tipo(plug):
    """Troca o widget do menu pelo outro tipo no mesmo lugar do painel, levando as opções dele."""
    js = P.PAINEL + f'''
var p = painelPrincipal(); var velho = widgetsDe(p, LANC)[0];
if (p && velho && velho.type !== {json.dumps(plug)}) {{
    p.currentConfigGroup = ["General"];
    var ordem = String(p.readConfig("AppletOrder") || "").split(";");
    velho.currentConfigGroup = ["General"];
    var chaves = velho.configKeys, vals = {{}};
    for (var c = 0; c < chaves.length; c++) vals[chaves[c]] = velho.readConfig(chaves[c]);
    // o painel põe o widget novo no ponto (x, y) dado: usa o lugar do antigo
    var g = velho.geometry;
    var novo = p.addWidget({json.dumps(plug)}, g.x + 1, g.y + 1, g.width, g.height);
    for (var c2 in vals) gravar(novo, "General", c2, vals[c2]);
    velho.remove();
    print("trocado");
}}'''
    return P.script(js)


def aplicar(cfg):
    plug = TIPOS.get(cfg.get('tipo', 'kickoff'), TIPOS['kickoff'])
    _trocar_tipo(plug)
    linhas = []
    for k, (chave, padrao, tipo) in OPCOES.items():
        v = str(cfg.get(k, padrao))
        if tipo == 'bool':
            v = 'true' if v == 'true' else 'false'
        elif tipo == 'int':
            v = str(int(float(v))) if v.replace('.', '', 1).lstrip('-').isdigit() else padrao
        linhas.append(f'n += gravar(k, "General", {json.dumps(chave)}, {json.dumps(v)});')
    js = P.PAINEL + 'var n = 0; widgetsDe(painelPrincipal(), LANC).forEach(function (k) {' + ''.join(linhas) + \
        'if (n) k.reloadConfig(); }); print(n);'
    P.script(js)
