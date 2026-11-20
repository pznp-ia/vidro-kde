#!/bin/bash
# Remove o tema de login Vidro do SDDM (volta ao tema anterior).
[ "$(id -u)" = 0 ] || { echo "Rode com sudo."; exit 1; }
rm -f /etc/sddm.conf.d/zzz-vidro.conf
rm -rf /usr/local/share/sddm/themes/vidro
echo "Desfeito: o SDDM volta ao tema anterior no próximo boot."
