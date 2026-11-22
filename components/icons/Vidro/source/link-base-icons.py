#!/usr/bin/env python3
"""Mirrors (with relative links) every icon folder of a base theme (Tela, Breeze...), except the folders/files
that Vidro redraws, keeping the original sizes and contexts. Stops KDE's fallback from replacing system icons
with Vidro's ones. Usage: python3 -I link-base-icons.py <vidro-icon-theme> [base-theme-folder]"""
import os, sys, glob, re, configparser
I = sys.argv[1]; T = os.path.realpath(os.path.expanduser(sys.argv[2] if len(sys.argv) > 2 else '~/.local/share/icons/Tela-red-dark'))
mine = set()
for d in ['16/places','22/places','scalable/places','scalable/mimetypes','scalable/apps']:
    if os.path.isdir(f'{I}/{d}'): mine |= {os.path.splitext(f)[0] for f in os.listdir(f'{I}/{d}')}
tc = configparser.RawConfigParser(strict=False); tc.optionxform = str; tc.read(T + '/index.theme')
dirs = [d for key in ('Directories','ScaledDirectories') for d in tc.get('Icon Theme', key, fallback='').split(',') if d]
import shutil
base = I + '/t'; shutil.rmtree(base, ignore_errors=True)
sections = []; n = 0
for d in dirs:
    ctx = d.split('/')[-1]
    if ctx in ('mimetypes', 'places') or not tc.has_section(d): continue
    src = os.path.join(T, d)
    if not os.path.isdir(src): continue
    os.makedirs(f'{base}/{d}', exist_ok=True)
    for f in os.listdir(src):
        if os.path.splitext(f)[0] in mine: continue
        os.symlink(os.path.relpath(os.path.realpath(os.path.join(src, f)), os.path.realpath(f"{base}/{d}")), f"{base}/{d}/{f}"); n += 1
    sections.append(('t/' + d, dict(tc.items(d))))
# rewrite index.theme: keep Vidro's header/sections and append the base theme's ones
p = I + '/index.theme'; s = open(p).read()
s = re.sub(r'\n\[t/[^\]]*\][^\[]*', '\n', s)          # remove old t/ sections
s = re.sub(r'\n\[scalable/tela\][^\[]*', '\n', s)
own = [x for x in re.search(r'^Directories=(.*)$', s, re.M).group(1).split(',') if x and not x.startswith('t/') and x != 'scalable/tela']
scaled_own = [x for x in (re.search(r'^ScaledDirectories=(.*)$', s, re.M).group(1).split(',') if re.search(r'^ScaledDirectories=', s, re.M) else []) if x and not x.startswith('t/')]
tdirs = [d for d, _ in sections]
s = re.sub(r'^Directories=.*$', 'Directories=' + ','.join(own + [d for d in tdirs if '@' not in d.split('/')[1]]), s, flags=re.M)
s = re.sub(r'^ScaledDirectories=.*$', 'ScaledDirectories=' + ','.join(scaled_own + [d for d in tdirs if '@' in d.split('/')[1]]), s, flags=re.M)
s = s.rstrip('\n') + '\n'
for d, items in sections:
    s += f'\n[{d}]\n' + ''.join(f'{k}={v}\n' for k, v in items.items())
open(p, 'w').write(s)
print('links:', n, 'folders:', len(sections))
