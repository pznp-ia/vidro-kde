"""Mouse and touchpad: speed, acceleration, scrolling, buttons (applied live to every mouse through KWin
and saved in kcminputrc), double-click time, plus pointer helpers (shake to find, click highlight,
hide when idle/typing — KWin effects)."""
import os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import flag, kread, kwin_effect, kwrite, num

GROUP = 'Mouse'
DEFAULTS = {
    'speed': '0',               # -100..100 (libinput pointer acceleration x100)
    'profile': 'flat',          # flat (constant) | adaptive (faster when moving fast)
    'natural_scroll': 'false',
    'left_handed': 'false',
    'scroll_speed': '100',      # % of the wheel scroll
    'middle_emulation': 'false',  # left+right together = middle click
    'touchpad_tap': 'true',
    'touchpad_natural': 'false',
    'touchpad_speed': '0',
    'double_click_ms': '400',
    'wheel_lines': '3',
    'shake_find': 'true',       # shake the mouse to enlarge the cursor
    'click_highlight': 'false', # circles where you click
    'hide_idle': 'false',       # hide the cursor when it stops
    'hide_seconds': '5',
    'hide_typing': 'false',     # hide the cursor while typing
}
QDBUS = next((q for q in ('/usr/lib64/qt6/bin/qdbus', '/usr/bin/qdbus6', '/usr/bin/qdbus') if os.path.exists(q)), 'qdbus')
PATH = '/org/kde/KWin/InputDevice'


def _q(*a):
    try:
        return subprocess.run([QDBUS, 'org.kde.KWin', *a], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ''


def _devices():
    out = []
    for d in _q(PATH, 'org.kde.KWin.InputDeviceManager.ListPointers').split():
        props = {}
        for line in _q(f'{PATH}/{d}', 'org.freedesktop.DBus.Properties.GetAll', 'org.kde.KWin.InputDevice').splitlines():
            k, _, v = line.partition(': ')
            props[k.strip()] = v.strip()
        if props.get('supportsPointerAcceleration') != 'true' or props.get('enabled') == 'false':
            continue
        if re.search(r'extest fake|InputPlumber', props.get('name', ''), re.I) and props.get('touchpad') != 'true':
            continue   # virtual devices (Steam/InputPlumber), not a real mouse
        props['sys'] = d
        out.append(props)
    return out


def _set(dev, prop, kind, value):
    subprocess.run(['dbus-send', '--session', '--type=method_call', '--dest=org.kde.KWin', f'{PATH}/{dev["sys"]}',
                    'org.freedesktop.DBus.Properties.Set', 'string:org.kde.KWin.InputDevice', f'string:{prop}',
                    f'variant:{kind}:{value}'], capture_output=True)


def _save(dev, key, value):
    subprocess.run(['kwriteconfig6', '--file', 'kcminputrc', '--group', 'Libinput', '--group', dev.get('vendor', '0'),
                    '--group', dev.get('product', '0'), '--group', dev.get('name', ''), '--key', key, str(value)], capture_output=True)


def current():
    out = {}
    for d in _devices():
        pre = 'touchpad_' if d.get('touchpad') == 'true' else ''
        if pre and 'touchpad_speed' in out or not pre and 'speed' in out:
            continue
        try:
            out[pre + 'speed'] = str(round(float(d.get('pointerAcceleration', '0')) * 100))
        except ValueError:
            pass
        if pre:
            out['touchpad_tap'] = d.get('tapToClick', 'true')
            out['touchpad_natural'] = d.get('naturalScroll', 'false')
        else:
            out['natural_scroll'] = d.get('naturalScroll', 'false')
            out['left_handed'] = d.get('leftHanded', 'false')
            out['middle_emulation'] = d.get('middleEmulation', 'false')
            try:
                out['scroll_speed'] = str(round(float(d.get('scrollFactor', '1')) * 100))
            except ValueError:
                pass
            if d.get('pointerAccelerationProfileFlat') in ('true', 'false'):
                out['profile'] = 'flat' if d['pointerAccelerationProfileFlat'] == 'true' else 'adaptive'
    out['double_click_ms'] = kread('kdeglobals', 'KDE', 'DoubleClickInterval', '400')
    out['wheel_lines'] = kread('kdeglobals', 'KDE', 'WheelScrollLines', '3')
    for key, eff in (('shake_find', 'shakecursor'), ('click_highlight', 'mouseclick'), ('hide_idle', 'hidecursor')):
        v = kread('kwinrc', 'Plugins', f'{eff}Enabled', '')
        if v:
            out[key] = v
    return out


def apply(cfg):
    tf = lambda k: 'true' if flag(cfg, k) else 'false'
    for d in _devices():
        if d.get('touchpad') == 'true':
            acc = num(cfg, 'touchpad_speed', -100, 100, 0) / 100
            vals = [('pointerAcceleration', 'double', f'{acc:.2f}', 'PointerAcceleration', f'{acc:.2f}'),
                    ('tapToClick', 'boolean', tf('touchpad_tap'), 'TapToClick', tf('touchpad_tap')),
                    ('naturalScroll', 'boolean', tf('touchpad_natural'), 'NaturalScroll', tf('touchpad_natural'))]
        else:
            acc = num(cfg, 'speed', -100, 100, 0) / 100
            flat = cfg.get('profile', 'flat') != 'adaptive'
            sf = num(cfg, 'scroll_speed', 10, 500, 100) / 100
            vals = [('pointerAcceleration', 'double', f'{acc:.2f}', 'PointerAcceleration', f'{acc:.2f}'),
                    ('pointerAccelerationProfileFlat', 'boolean', 'true' if flat else 'false', 'PointerAccelerationProfile', 1 if flat else 2),
                    ('pointerAccelerationProfileAdaptive', 'boolean', 'false' if flat else 'true', None, None),
                    ('naturalScroll', 'boolean', tf('natural_scroll'), 'NaturalScroll', tf('natural_scroll')),
                    ('leftHanded', 'boolean', tf('left_handed'), 'LeftHanded', tf('left_handed')),
                    ('middleEmulation', 'boolean', tf('middle_emulation'), 'MiddleButtonEmulation', tf('middle_emulation')),
                    ('scrollFactor', 'double', f'{sf:.2f}', 'ScrollFactor', f'{sf:.2f}')]
        for prop, kind, value, key, saved in vals:
            _set(d, prop, kind, value)
            if key:
                _save(d, key, saved)
    kwrite('kdeglobals', 'KDE', 'DoubleClickInterval', int(num(cfg, 'double_click_ms', 150, 1000, 400)), notify=True)
    kwrite('kdeglobals', 'KDE', 'WheelScrollLines', int(num(cfg, 'wheel_lines', 1, 20, 3)), notify=True)
    kwrite('kwinrc', 'Effect-hidecursor', 'InactivityDuration', int(num(cfg, 'hide_seconds', 1, 60, 5)) if flag(cfg, 'hide_idle') else 0)
    kwrite('kwinrc', 'Effect-hidecursor', 'HideOnTyping', tf('hide_typing'))
    for key, eff in (('shake_find', 'shakecursor'), ('click_highlight', 'mouseclick')):
        if kread('kwinrc', 'Plugins', f'{eff}Enabled', '') != tf(key):
            kwin_effect(eff, flag(cfg, key))
    hide = flag(cfg, 'hide_idle') or flag(cfg, 'hide_typing')
    kwin_effect('hidecursor', hide)
