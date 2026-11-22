"""Cursor studio: generates the "VidroCursor" cursor theme (shape, colors, outline, corners, shadow)
and applies it. The app preview uses ~/.cache/vidro/cursor-preview (SVG only, fast).
Off = back to the cursor you used before (stored in ~/.local/share/vidro/cursor/previous)."""
import json, os, subprocess, sys, time
sys.path.insert(0, os.path.dirname(__file__))
from _common import flag as sim, num

GROUP = 'Cursor'
DEFAULTS = {
    'enabled': 'false',          # use the Vidro cursor system-wide
    'shape': 'modern',        # classic | modern | minimal | triangle
    'fill': '#1d1e23',        # inside color
    'outline': '#ffffff',
    'accent': '#5b9cf5',     # details (wait spinner, badges)
    'outline_width': '1.3',            # outline thickness
    'roundness': '1',             # roundness
    'shadow': '45',
    'size': '24',           # system cursor size
}
DATA = os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share'))
GENERATOR = os.path.join(DATA, 'vidro', 'cursor', 'make-cursor.py')
THEME = os.path.join(DATA, 'icons', 'VidroCursor')
PREVIEW = os.path.expanduser('~/.cache/vidro/cursor-preview')
PREVIOUS = os.path.join(DATA, 'vidro', 'cursor', 'previous')
LAST = os.path.expanduser('~/.cache/vidro/cursor-last')


def _env(cfg):
    e = dict(os.environ)
    e.update(VIDRO_CURSOR_SHAPE=cfg.get('shape', 'modern'), VIDRO_CURSOR_FILL=cfg.get('fill', '#1d1e23'),
             VIDRO_CURSOR_OUTLINE=cfg.get('outline', '#ffffff'), VIDRO_CURSOR_ACCENT=cfg.get('accent', '#5b9cf5'),
             VIDRO_CURSOR_OUTLINE_WIDTH=str(num(cfg, 'outline_width', 0, 3, 1.3)), VIDRO_CURSOR_ROUNDNESS=str(num(cfg, 'roundness', 0, 3, 1)),
             VIDRO_CURSOR_SHADOW=str(num(cfg, 'shadow', 0, 100, 45)))
    return e


def _read(key, default=''):
    r = subprocess.run(['kreadconfig6', '--file', 'kcminputrc', '--group', 'Mouse', '--key', key], capture_output=True, text=True)
    return r.stdout.strip() or default


def _use(theme, size):
    subprocess.run(['kwriteconfig6', '--file', 'kcminputrc', '--group', 'Mouse', '--key', 'cursorSize', str(size)])
    if theme == 'VidroCursor':   # make KWin re-read the theme (same name)
        subprocess.run(['plasma-apply-cursortheme', 'breeze_cursors'], capture_output=True)
        time.sleep(0.2)
    subprocess.run(['plasma-apply-cursortheme', '--size', str(size), theme], capture_output=True)
    subprocess.run(['kwriteconfig6', '--file', 'kcminputrc', '--group', 'Mouse', '--key', 'cursorSize', str(size)])


def apply(cfg):
    if not os.path.isfile(GENERATOR):
        return
    env = _env(cfg)
    style = json.dumps({k: env[k] for k in env if k.startswith('VIDRO_CURSOR_')}, sort_keys=True)
    # preview (always, fast)
    subprocess.run(['python3', '-I', GENERATOR, PREVIEW, '--svg-only'], env=env, capture_output=True)
    current = _read('cursorTheme', 'breeze_cursors')
    size = int(num(cfg, 'size', 16, 96, 24))
    if sim(cfg, 'enabled'):
        if current != 'VidroCursor':
            os.makedirs(os.path.dirname(PREVIOUS), exist_ok=True)
            open(PREVIOUS, 'w').write(json.dumps({'theme': current, 'size': _read('cursorSize', '24')}))
        try: before = open(LAST).read()
        except OSError: before = ''
        changed = before != style or not os.path.isdir(os.path.join(THEME, 'cursors'))
        if changed:
            subprocess.run(['python3', '-I', GENERATOR, THEME, '--svg-only'], env=env, capture_output=True)
            # Xcursor (X11 apps) in the background: takes a few seconds
            os.makedirs(os.path.dirname(LAST), exist_ok=True)
            open(LAST, 'w').write(style)
            # wait 2 s; if another change arrived meanwhile, give up (the newest one generates);
            # generate into a temporary folder and only then swap, so it is never half-written
            import hashlib, shlex
            h = hashlib.sha1(style.encode()).hexdigest()
            open(LAST + '.hash', 'w').write(h)
            q = shlex.quote
            tmp = THEME + '.building-' + h[:8]
            sh = (f'sleep 2; [ "$(cat {q(LAST + ".hash")})" = {h} ] || exit 0; '
                  f'python3 -I {q(GENERATOR)} {q(tmp)} && [ "$(cat {q(LAST + ".hash")})" = {h} ] '
                  f'&& rm -rf {q(THEME + "/cursors")} && mv {q(tmp + "/cursors")} {q(THEME + "/cursors")}; rm -rf {q(tmp)}')
            subprocess.Popen(['sh', '-c', sh], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        # Plasma only lists cursors from ~/.icons and /usr/share/icons: link the theme there
        icons_dir = os.path.expanduser('~/.icons')
        os.makedirs(icons_dir, exist_ok=True)
        lnk = os.path.join(icons_dir, 'VidroCursor')
        if not os.path.lexists(lnk):
            os.symlink(os.path.relpath(THEME, icons_dir), lnk)
        if changed or current != 'VidroCursor' or _read('cursorSize', '24') != str(size):
            _use('VidroCursor', size)
    elif current == 'VidroCursor':
        try: prev = json.loads(open(PREVIOUS).read())
        except (OSError, ValueError): prev = {'theme': 'breeze_cursors', 'size': '24'}
        _use(prev.get('theme', 'breeze_cursors'), prev.get('size', '24'))
