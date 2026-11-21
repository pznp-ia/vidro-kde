"""Barra de tarefas (painel principal): tamanho, flutuante, opacidade, ocultar, posição;
ícones dos apps (gerenciador de tarefas) e relógio. Muda na hora pelo plasmashell.
Os valores mostrados no app vêm do seu painel (atual()), então nada muda até você mexer."""
import gzip, json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
import _plasma as P

GRUPO = 'Painel'
# propriedades do painel: chave -> (propriedade no script, padrão, tipo)
PAINEL = {
    'altura': ('height', '44', 'int'),
    'flutuante': ('floating', 'true', 'bool'),
    'opacidade': ('opacity', 'translucent', 'str'),     # adaptive | opaque | translucent
    'ocultar': ('hiding', 'none', 'str'),               # none | autohide | dodgewindows | windowsgobelow
    'largura': ('lengthMode', 'fill', 'str'),           # fill | fit
    'alinhamento': ('alignment', 'center', 'str'),      # left | center | right
    'posicao': ('location', 'bottom', 'str'),           # bottom | top | left | right
}
TAREFAS_TIPOS = ['org.kde.plasma.icontasks', 'org.kde.plasma.taskmanager']
TAREFAS = {  # chave -> (chave do widget, padrão, tipo); grupo General
    'espaco_icones': ('iconSpacing', '1', 'int'),
    'agrupar': ('groupingStrategy', '1', 'int'),
    'so_area_atual': ('showOnlyCurrentDesktop', 'true', 'bool'),
    'so_tela_atual': ('showOnlyCurrentScreen', 'false', 'bool'),
    'audio': ('indicateAudioStreams', 'true', 'bool'),
    'dicas': ('showToolTips', 'true', 'bool'),
    'efeito_mouse': ('taskHoverEffect', 'true', 'bool'),
    'destacar_janelas': ('highlightWindows', 'false', 'bool'),
    'clique_meio': ('middleClickAction', '2', 'int'),
    'linhas': ('maxStripes', '1', 'int'),
}
RELOGIO_TIPOS = ['org.kde.plasma.digitalclock']
RELOGIO = {  # grupo Appearance
    'segundos': ('showSeconds', '1', 'int'),            # 0 nunca, 1 na dica, 2 sempre
    'data': ('showDate', 'true', 'bool'),
    'formato_data': ('dateFormat', 'shortDate', 'str'), # shortDate | longDate | isoDate | custom
    'data_personalizada': ('customDateFormat', 'ddd d', 'str'),
    'posicao_data': ('dateDisplayFormat', '0', 'int'),  # 0 automático, 1 ao lado, 2 embaixo
    'horas': ('use24hFormat', '1', 'int'),              # 0 12 h, 1 do idioma, 2 24 h
    'negrito': ('boldText', 'false', 'bool'),
    'fonte_auto': ('autoFontAndSize', 'true', 'bool'),
    'tamanho_fonte': ('fontSize', '10', 'int'),
}
VIDRO = {  # aparência do fundo da barra (estilo do Plasma "Vidro"); só mexe com vidro_ativo = true
    'vidro_ativo': 'false', 'vidro_raio': '6', 'vidro_opacidade': '42', 'vidro_contorno': '0',
    'vidro_sombra': '0', 'vidro_fundo': 'tema', 'vidro_cor': '#1c1e24',
}
PADROES = {**VIDRO, **{k: v[1] for k, v in PAINEL.items()},
           **{k: v[1] for k, v in TAREFAS.items()},
           **{k: v[1] for k, v in RELOGIO.items()}}


def atual():
    js = P.PAINEL + 'var p = painelPrincipal(); var o = {}; if (p) {' + ''.join(
        f'o[{json.dumps(k)}] = p.{v[0]};' for k, v in PAINEL.items()) + \
        'var t = widgetsDe(p, ' + json.dumps(TAREFAS_TIPOS) + ')[0]; if (t) {' + ''.join(
        f'o[{json.dumps(k)}] = ler(t, "General", {json.dumps(v[0])});' for k, v in TAREFAS.items()) + \
        '} var c = widgetsDe(p, ' + json.dumps(RELOGIO_TIPOS) + ')[0]; if (c) {' + ''.join(
        f'o[{json.dumps(k)}] = ler(c, "Appearance", {json.dumps(v[0])});' for k, v in RELOGIO.items()) + \
        '} } print(JSON.stringify(o));'
    o = P.script_json(js) or {}
    return {k: str(v).lower() if isinstance(v, bool) else str(v) for k, v in o.items() if v not in ('', None)}


def _valor(v, padrao, tipo):
    v = str(v)
    if tipo == 'bool':
        return 'true' if v == 'true' else 'false'
    if tipo == 'int':
        try:
            return str(int(float(v)))
        except ValueError:
            return padrao
    return v


def aplicar(cfg):
    js = [P.PAINEL, 'var p = painelPrincipal(); if (p) {']
    for k, (prop, padrao, tipo) in PAINEL.items():
        v = _valor(cfg.get(k, padrao), padrao, tipo)
        if tipo == 'int':
            js.append(f'if (p.{prop} != {v}) p.{prop} = {v};')
        elif tipo == 'bool':
            js.append(f'if (p.{prop} != {v}) p.{prop} = {v};')
        else:
            js.append(f'if (p.{prop} != {json.dumps(v)}) p.{prop} = {json.dumps(v)};')
    for tipos, opcoes, grupo in ((TAREFAS_TIPOS, TAREFAS, 'General'), (RELOGIO_TIPOS, RELOGIO, 'Appearance')):
        js.append(f'widgetsDe(p, {json.dumps(tipos)}).forEach(function (w) {{ var n = 0;')
        for k, (chave, padrao, tipo) in opcoes.items():
            js.append(f'n += gravar(w, {json.dumps(grupo)}, {json.dumps(chave)}, {json.dumps(_valor(cfg.get(k, padrao), padrao, tipo))});')
        js.append('if (n) w.reloadConfig(); });')
    js.append('}')
    P.script(''.join(js))
    _vidro(cfg)


DATA = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
TEMA = os.path.join(DATA, 'plasma', 'desktoptheme', 'Vidro')
MODELOS = os.path.join(DATA, 'vidro', 'modelos')
ULTIMO = os.path.expanduser('~/.cache/vidro/painel-vidro')
ARQS = {  # arquivo no tema -> modelo original
    os.path.join('translucent', 'widgets', 'panel-background.svgz'): 'translucent-widgets-panel-background.svg',
    os.path.join('widgets', 'panel-background.svgz'): 'widgets-panel-background.svg',
}


def _svg_vidro(cfg, modelo):
    import menuiniciar
    from _union import num
    R = int(num(cfg, 'vidro_raio', 0, 30, 6))
    op = num(cfg, 'vidro_opacidade', 5, 100, 42) / 100
    borda = num(cfg, 'vidro_contorno', 0, 60, 0) / 100
    forca = num(cfg, 'vidro_sombra', 0, 100, 0) / 100 * 0.5
    cor = cfg.get('vidro_cor', '') if cfg.get('vidro_fundo') == 'cor' else None
    if cor and not re.fullmatch(r'#[0-9a-fA-F]{6}', cor):
        cor = None
    svg = menuiniciar._dialogo(max(R, 2), op, borda, forca, 10, cor, margem=4)
    # medidas da barra flutuante ("inset") copiadas do original
    extra = ''.join(re.findall(r'<rect[^>]*id="(?:shadow-)?hint-[a-z]+-inset"[^>]*/>', modelo, re.S))
    return svg.replace('</svg>', extra + '</svg>')


def _vidro(cfg):
    chave = json.dumps({k: cfg.get(k) for k in VIDRO}, sort_keys=True)
    try:
        if open(ULTIMO).read() == chave:
            return
    except OSError:
        if cfg.get('vidro_ativo') != 'true':
            return  # nunca mexeu: deixa como está
    if not os.path.isdir(TEMA):
        return
    for arq, mod in ARQS.items():
        destino, modelo = os.path.join(TEMA, arq), os.path.join(MODELOS, mod)
        if not (os.path.isfile(modelo) and os.path.isdir(os.path.dirname(destino))):
            continue
        texto = open(modelo).read()
        if cfg.get('vidro_ativo') == 'true':
            texto = _svg_vidro(cfg, texto)
        with gzip.open(destino, 'wb') as f:
            f.write(texto.encode())
    os.makedirs(os.path.dirname(ULTIMO), exist_ok=True)
    open(ULTIMO, 'w').write(chave)
    import menuiniciar
    menuiniciar._recarregar()
