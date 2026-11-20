#!/bin/bash
# Volta /etc/xdg/kdeglobals ao original do Bazzite (bloqueio desativado).
set -e
[ "$(id -u)" = 0 ] || { echo "Rode com: sudo bash $0"; exit 1; }
F=/etc/xdg/kdeglobals
[ -f $F.antes-vidro ] && cp -a $F.antes-vidro $F && echo "Restaurado." || echo "Sem backup; nada feito."
