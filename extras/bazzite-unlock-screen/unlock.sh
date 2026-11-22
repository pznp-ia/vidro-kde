#!/bin/bash
# Vidro: enables screen locking (Win+L) by removing Bazzite's kiosk lock.
# Only touches the action/lock_screen=false line of /etc/xdg/kdeglobals (backs it up first).
set -e
[ "$(id -u)" = 0 ] || { echo "Rode com: sudo bash $0"; exit 1; }
F=/etc/xdg/kdeglobals
[ -f $F.antes-vidro ] || cp -a $F $F.antes-vidro
sed -i '/^action\/lock_screen=false$/d' $F
echo "Pronto. Trava removida (backup: $F.antes-vidro)."
echo "Faça logout/login (ou reinicie) para o Win+L funcionar."
