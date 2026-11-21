"""Janelas: transparência (kwinrc, vidro-transparencia) e cor da barra de título (decoração Vidro)."""
import os, subprocess
GRUPO = 'Janelas'
def _nivel():
    try:
        return subprocess.run(['kreadconfig6', '--file', 'kwinrc', '--group', 'Effect-vidro_opacity', '--key', 'Level', '--default', '50'],
                              capture_output=True, text=True).stdout.strip() or '50'
    except Exception:
        return '50'
PADROES = {
    'transparencia': _nivel(),
    'barra': 'tema',          # tema (escura/clara automática pelo papel de parede) | cor
    'cor_barra': '#262830',   # cor da barra de título quando barra = cor
}
_ULTIMA = os.path.expanduser('~/.cache/vidro-janelas-barra')

def aplicar(cfg):
    subprocess.run([os.path.expanduser('~/.local/bin/vidro-transparencia'), str(cfg.get('transparencia', '50'))])
    # só refaz a decoração (pisca de leve) se a cor da barra mudou
    chave = f"{cfg.get('barra', 'tema')}|{cfg.get('cor_barra', '')}"
    try: antes = open(_ULTIMA).read()
    except OSError: antes = None
    if chave != antes:
        subprocess.run([os.path.expanduser('~/.local/bin/vidro-cor-titulo'), '--force'], capture_output=True)
        os.makedirs(os.path.dirname(_ULTIMA), exist_ok=True)
        open(_ULTIMA, 'w').write(chave)
