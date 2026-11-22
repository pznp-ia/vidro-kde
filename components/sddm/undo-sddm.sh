#!/bin/bash
# Removes the Vidro login theme from SDDM (back to the previous theme).
[ "$(id -u)" = 0 ] || { echo "Run with sudo."; exit 1; }
rm -f /etc/sddm.conf.d/zzz-vidro.conf
rm -rf /usr/local/share/sddm/themes/vidro
echo "Undone: SDDM goes back to the previous theme at the next boot."
