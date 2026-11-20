#!/bin/bash
# Vidro: libera o bloqueio de tela (Win+L) removendo a trava kiosk do Bazzite.
# Só mexe na linha action/lock_screen=false de /etc/xdg/kdeglobals (backup antes).
set -e
[ "$(id -u)" = 0 ] || { echo "Rode com: sudo bash $0"; exit 1; }
F=/etc/xdg/kdeglobals
[ -f $F.antes-vidro ] || cp -a $F $F.antes-vidro
sed -i '/^action\/lock_screen=false$/d' $F
echo "Pronto. Trava removida (backup: $F.antes-vidro)."
echo "Faça logout/login (ou reinicie) para o Win+L funcionar."
