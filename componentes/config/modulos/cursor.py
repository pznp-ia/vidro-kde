"""Estúdio do cursor: gera o tema de cursores "VidroCursor" (forma, cores, contorno, cantos, sombra)
e aplica no sistema. A prévia do app usa ~/.cache/vidro/cursor-previa (só SVG, rápido).
Desligado = volta ao cursor que você usava antes (guardado em ~/.local/share/vidro/cursor/anterior)."""
import json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(__file__))
from _union import num, sim

GRUPO = 'Cursor'
PADROES = {
    'ativo': 'false',          # usar o cursor do Vidro no sistema
    'forma': 'moderna',        # classica | moderna | minima | triangulo
    'fundo': '#1d1e23',        # cor de dentro
    'contorno': '#ffffff',
    'destaque': '#5b9cf5',     # detalhes (espera, selos)
    'borda': '1.3',            # espessura do contorno
    'cantos': '1',             # arredondamento
    'sombra': '45',
    'tamanho': '24',           # tamanho do cursor no sistema
}
DATA = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
GERADOR = os.path.join(DATA, 'vidro', 'cursor', 'gerar-cursor.py')
TEMA = os.path.join(DATA, 'icons', 'VidroCursor')
PREVIA = os.path.expanduser('~/.cache/vidro/cursor-previa')
ANTERIOR = os.path.join(DATA, 'vidro', 'cursor', 'anterior')
ULTIMO = os.path.expanduser('~/.cache/vidro/cursor-ultimo')


def _env(cfg):
    e = dict(os.environ)
    e.update(VIDRO_CUR_FORMA=cfg.get('forma', 'moderna'), VIDRO_CUR_FUNDO=cfg.get('fundo', '#1d1e23'),
             VIDRO_CUR_CONTORNO=cfg.get('contorno', '#ffffff'), VIDRO_CUR_DESTAQUE=cfg.get('destaque', '#5b9cf5'),
             VIDRO_CUR_BORDA=str(num(cfg, 'borda', 0, 3, 1.3)), VIDRO_CUR_CANTOS=str(num(cfg, 'cantos', 0, 3, 1)),
             VIDRO_CUR_SOMBRA=str(num(cfg, 'sombra', 0, 100, 45)))
    return e


def _ler(chave, padrao=''):
    r = subprocess.run(['kreadconfig6', '--file', 'kcminputrc', '--group', 'Mouse', '--key', chave], capture_output=True, text=True)
    return r.stdout.strip() or padrao


def _usar(tema, tamanho):
    subprocess.run(['kwriteconfig6', '--file', 'kcminputrc', '--group', 'Mouse', '--key', 'cursorSize', str(tamanho)])
    if tema == 'VidroCursor':   # força o KWin a reler o tema (o nome é o mesmo)
        subprocess.run(['plasma-apply-cursortheme', 'breeze_cursors'], capture_output=True)
        time.sleep(0.2)
    subprocess.run(['plasma-apply-cursortheme', '--size', str(tamanho), tema], capture_output=True)
    subprocess.run(['kwriteconfig6', '--file', 'kcminputrc', '--group', 'Mouse', '--key', 'cursorSize', str(tamanho)])


def aplicar(cfg):
    if not os.path.isfile(GERADOR):
        return
    env = _env(cfg)
    estilo = json.dumps({k: env[k] for k in env if k.startswith('VIDRO_CUR_')}, sort_keys=True)
    # prévia (sempre, rápida)
    subprocess.run(['python3', '-I', GERADOR, PREVIA, '--so-svg'], env=env, capture_output=True)
    atual = _ler('cursorTheme', 'breeze_cursors')
    tamanho = int(num(cfg, 'tamanho', 16, 96, 24))
    if sim(cfg, 'ativo'):
        if atual != 'VidroCursor':
            os.makedirs(os.path.dirname(ANTERIOR), exist_ok=True)
            open(ANTERIOR, 'w').write(json.dumps({'tema': atual, 'tamanho': _ler('cursorSize', '24')}))
        try: antes = open(ULTIMO).read()
        except OSError: antes = ''
        mudou = antes != estilo or not os.path.isdir(os.path.join(TEMA, 'cursors'))
        if mudou:
            subprocess.run(['python3', '-I', GERADOR, TEMA, '--so-svg'], env=env, capture_output=True)
            # Xcursor (apps X11) em segundo plano: leva alguns segundos
            os.makedirs(os.path.dirname(ULTIMO), exist_ok=True)
            open(ULTIMO, 'w').write(estilo)
            # espera 2 s; se outro ajuste chegou nesse meio-tempo, desiste (o mais novo gera);
            # gera numa pasta temporária e só então troca, para nunca ficar pela metade
            import hashlib, shlex
            h = hashlib.sha1(estilo.encode()).hexdigest()
            open(ULTIMO + '.hash', 'w').write(h)
            q = shlex.quote
            tmp = TEMA + '.gerando-' + h[:8]
            sh = (f'sleep 2; [ "$(cat {q(ULTIMO + ".hash")})" = {h} ] || exit 0; '
                  f'python3 -I {q(GERADOR)} {q(tmp)} && [ "$(cat {q(ULTIMO + ".hash")})" = {h} ] '
                  f'&& rm -rf {q(TEMA + "/cursors")} && mv {q(tmp + "/cursors")} {q(TEMA + "/cursors")}; rm -rf {q(tmp)}')
            subprocess.Popen(['sh', '-c', sh], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        # o Plasma só lista cursores de ~/.icons e /usr/share/icons: atalho para o tema
        icons = os.path.expanduser('~/.icons')
        os.makedirs(icons, exist_ok=True)
        lnk = os.path.join(icons, 'VidroCursor')
        if not os.path.lexists(lnk):
            os.symlink(os.path.relpath(TEMA, icons), lnk)
        if mudou or atual != 'VidroCursor' or _ler('cursorSize', '24') != str(tamanho):
            _usar('VidroCursor', tamanho)
    elif atual == 'VidroCursor':
        try: ant = json.loads(open(ANTERIOR).read())
        except (OSError, ValueError): ant = {'tema': 'breeze_cursors', 'tamanho': '24'}
        _usar(ant.get('tema', 'breeze_cursors'), ant.get('tamanho', '24'))
