#!/bin/bash
# Puts /etc/xdg/kdeglobals back to Bazzite's original (screen locking disabled).
set -e
[ "$(id -u)" = 0 ] || { echo "Rode com: sudo bash $0"; exit 1; }
F=/etc/xdg/kdeglobals
[ -f $F.antes-vidro ] && cp -a $F.antes-vidro $F && echo "Restaurado." || echo "Sem backup; nada feito."
