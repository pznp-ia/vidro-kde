"""Ajudante dos módulos: grava CSS no estilo Union "vidro".
Cada módulo grava css/modulo-<nome>.css; css/vidro-modulos.css importa todos
(e é importado no fim de style.css). Apps abertos pegam a mudança ao reabrir."""
import glob, os
CSS = os.path.join(os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share')),
                   'union', 'styles', 'vidro', 'contents', 'css')

def escrever_css(nome, texto):
    if not os.path.isdir(CSS):
        return False
    with open(os.path.join(CSS, f'modulo-{nome}.css'), 'w') as f:
        f.write(f'/* gerado por vidro-config (módulo {nome}) — não edite à mão */\n' + texto)
    imports = ''.join(f'@import "{os.path.basename(p)}";\n' for p in sorted(glob.glob(os.path.join(CSS, 'modulo-*.css'))))
    with open(os.path.join(CSS, 'vidro-modulos.css'), 'w') as f:
        f.write('/* gerado por vidro-config */\n' + imports)
    st = os.path.join(CSS, 'style.css'); s = open(st).read()
    if 'vidro-modulos.css' not in s:
        open(st, 'w').write(s.rstrip('\n') + '\n@import "vidro-modulos.css";\n')
    sincronizar_derivados()
    return True

def sincronizar_derivados():
    """Estilos derivados (ex.: vidro-dolphin) usam atalhos para os CSS do vidro. Se um módulo novo
    aparece em vidro-modulos.css e o atalho não existe no derivado, o Union quebra (o Dolphin travava).
    Aqui cada derivado ganha os atalhos que faltam e perde os que apontam para arquivos apagados."""
    estilos = os.path.dirname(os.path.dirname(os.path.dirname(CSS)))
    modulos = sorted(os.path.basename(p) for p in glob.glob(os.path.join(CSS, 'modulo-*.css')))
    for d in glob.glob(os.path.join(estilos, '*', 'contents', 'css')):
        if os.path.realpath(d) == os.path.realpath(CSS):
            continue
        ref = os.path.join(d, 'vidro-modulos.css')
        if not (os.path.islink(ref) and os.path.realpath(ref) == os.path.realpath(os.path.join(CSS, 'vidro-modulos.css'))):
            continue
        for m in modulos:
            alvo = os.path.join(d, m)
            if not os.path.lexists(alvo):
                os.symlink(os.path.relpath(os.path.join(CSS, m), d), alvo)
        for p in glob.glob(os.path.join(d, 'modulo-*.css')):
            if os.path.islink(p) and not os.path.exists(p):
                os.remove(p)

def hex_rgba(h, a):
    h = h.lstrip('#')
    if len(h) != 6: h = '8ab4f8'
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return f'rgba({r}, {g}, {b}, {max(0, min(1, a)):.3f})'

def num(cfg, k, lo, hi, padrao):
    try: v = float(cfg.get(k, padrao))
    except ValueError: v = float(padrao)
    return max(lo, min(hi, v))

def sim(cfg, k):
    return str(cfg.get(k, 'true')).lower() in ('1', 'true', 'sim', 'yes', 'on')
