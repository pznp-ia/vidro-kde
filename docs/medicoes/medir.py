#!/usr/bin/env python3
"""Mede consumo durante N segundos: CPU (total e por processo), GPU (amdgpu) e potência do chip.
Uso: medir.py <rotulo> <segundos> <saida.json> [ativo]
Com 'ativo', move/maximiza/minimiza as janelas "Prévia do Vidro" por scripts do KWin durante a medição."""
import json, os, subprocess, sys, threading, time

ROT, DUR, SAIDA = sys.argv[1], float(sys.argv[2]), sys.argv[3]
ATIVO = len(sys.argv) > 4 and sys.argv[4] == 'ativo'
GPU = '/sys/class/drm/card1/device/gpu_busy_percent'
POT = '/sys/class/hwmon/hwmon5/power1_input'
PROCS = ('kwin_wayland', 'plasmashell', 'Xwayland', 'vidro-previa')
HZ = os.sysconf('SC_CLK_TCK')
S = os.path.dirname(os.path.abspath(__file__))


def ler(p):
    try:
        return open(p).read().strip()
    except OSError:
        return None


def cpu_total():
    v = list(map(int, open('/proc/stat').readline().split()[1:]))
    return sum(v), v[3] + v[4]


def tempos():
    out = {p: 0 for p in PROCS}
    for pid in os.listdir('/proc'):
        if not pid.isdigit():
            continue
        try:
            st = open(f'/proc/{pid}/stat').read()
        except OSError:
            continue
        nome = st[st.index('(') + 1:st.rindex(')')]
        for p in PROCS:
            if nome.startswith(p[:15]):
                c = st[st.rindex(')') + 2:].split()
                out[p] += int(c[11]) + int(c[12])
    return out


def rss(nome):
    t = 0
    for pid in os.listdir('/proc'):
        if pid.isdigit():
            try:
                if open(f'/proc/{pid}/comm').read().strip().startswith(nome[:15]):
                    for l in open(f'/proc/{pid}/status'):
                        if l.startswith('VmRSS'):
                            t += int(l.split()[1])
            except OSError:
                pass
    return t // 1024


ACOES = [
    'for (const w of workspace.windowList()) if (w.caption.indexOf("Prévia do Vidro") >= 0) { w.setMaximize(true, true); }',
    'var i = 0; for (const w of workspace.windowList()) if (w.caption.indexOf("Prévia do Vidro") >= 0) { w.setMaximize(false, false); w.frameGeometry = {x: 120 + i * 260 + Math.random() * 200, y: 80 + Math.random() * 300, width: 700, height: 520}; i++; }',
    'for (const w of workspace.windowList()) if (w.caption.indexOf("Prévia do Vidro") >= 0) { w.minimized = true; }',
    'for (const w of workspace.windowList()) if (w.caption.indexOf("Prévia do Vidro") >= 0) { w.minimized = false; workspace.activeWindow = w; }',
    'var ws = workspace.windowList().filter(function (w) { return w.caption.indexOf("Prévia do Vidro") >= 0; }); if (ws.length) workspace.activeWindow = ws[Math.floor(Math.random() * ws.length)];',
]


def rodar_js(js, n):
    f = os.path.join(S, f'acao{n}.js')
    open(f, 'w').write(js)
    nome = f'vidromedir{n}_{os.getpid()}'
    r = subprocess.run(['dbus-send', '--session', '--print-reply', '--dest=org.kde.KWin', '/Scripting',
                        'org.kde.kwin.Scripting.loadScript', f'string:{f}', f'string:{nome}'], capture_output=True, text=True)
    sid = r.stdout.split()[-1] if r.stdout else ''
    subprocess.run(['dbus-send', '--session', '--print-reply', '--dest=org.kde.KWin', f'/Scripting/Script{sid}',
                    'org.kde.kwin.Script.run'], capture_output=True)
    subprocess.run(['dbus-send', '--session', '--dest=org.kde.KWin', '/Scripting', 'org.kde.kwin.Scripting.unloadScript',
                    f'string:{nome}'], capture_output=True)


parar = threading.Event()


def atividade():
    k = 0
    while not parar.is_set():
        rodar_js(ACOES[k % len(ACOES)], k % len(ACOES))
        k += 1
        parar.wait(0.6)


amostras = []
t0, i0 = cpu_total(); p0 = tempos(); inicio = time.time()
th = threading.Thread(target=atividade, daemon=True)
if ATIVO:
    th.start()
ult = (t0, i0, p0, inicio)
while time.time() - inicio < DUR:
    time.sleep(1)
    t, i, p, agora = *cpu_total(), tempos(), time.time()
    dt = t - ult[0]
    amostras.append({
        'cpu_total': 100 * (1 - (i - ult[1]) / dt) if dt else 0,
        **{f'cpu_{k}': 100 * (p[k] - ult[2][k]) / HZ / (agora - ult[3]) for k in PROCS},
        'gpu': int(ler(GPU) or 0),
        'potencia_w': int(ler(POT) or 0) / 1e6,
    })
    ult = (t, i, p, agora)
parar.set()
media = {k: sum(a[k] for a in amostras) / len(amostras) for k in amostras[0]}
media['rss_kwin_mb'] = rss('kwin_wayland'); media['rss_plasmashell_mb'] = rss('plasmashell')
json.dump({'rotulo': ROT, 'ativo': ATIVO, 'segundos': DUR, 'media': media, 'amostras': amostras}, open(SAIDA, 'w'), indent=1)
print(ROT, 'ativo' if ATIVO else 'ocioso', {k: round(v, 2) for k, v in media.items()})
