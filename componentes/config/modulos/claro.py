"""Claro (TESTE): versão clara do Vidro mantendo as transparências.
Liga: esquema de cores "Vidro Claro" + barra de título em vidro claro (opacidade ajustável).
Desliga (padrão): volta ao esquema "Vidro" escuro e à cor automática da barra."""
import os, subprocess, sys
sys.path.insert(0, os.path.dirname(__file__))
from _union import num, sim

GRUPO = 'Claro'
PADROES = {
    'ativo': 'false',
    'vidro': '100',   # 20-160: opacidade do vidro da barra de título (100 = normal; menos = mais transparente)
}
TEMA = os.path.expanduser('~/.local/share/aurorae/themes/Vidro')


def _recarregar_decoracao():
    k = lambda *a: subprocess.run(['kwriteconfig6', '--file', 'kwinrc', '--group', 'org.kde.kdecoration2', *a])
    r = lambda: subprocess.run(['dbus-send', '--session', '--type=method_call', '--dest=org.kde.KWin', '/KWin', 'org.kde.KWin.reconfigure'])
    k('--key', 'library', 'org.kde.breeze'); k('--key', 'theme', 'Breeze'); r()
    subprocess.run(['sleep', '0.6'])
    k('--key', 'library', 'org.kde.kwin.aurorae.v2'); k('--key', 'theme', '__aurorae__svg__Vidro'); r()


def aplicar(cfg):
    if sim(cfg, 'ativo'):
        subprocess.run(['plasma-apply-colorscheme', 'VidroClaro'], capture_output=True)
        env = dict(os.environ, VIDRO_ALFA=str(num(cfg, 'vidro', 20, 160, 100) / 100))
        subprocess.run(['python3', '-I', os.path.join(TEMA, 'fonte', 'gerar-vidro.py'), TEMA, 'claro'], env=env, capture_output=True)
        _recarregar_decoracao()
    else:
        subprocess.run(['plasma-apply-colorscheme', 'Vidro'], capture_output=True)
        subprocess.run([os.path.expanduser('~/.local/bin/vidro-cor-titulo'), '--force'], capture_output=True)
