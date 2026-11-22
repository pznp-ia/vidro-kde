#!/bin/bash
# Installs the Vidro login theme into SDDM.
# Usage: sudo bash components/sddm/install-sddm.sh [background-image]
#   Without an image it uses KDE's Honeywave wallpaper (or Next).
# To undo: sudo bash components/sddm/undo-sddm.sh
# (Vidro Settings → Login screen builds a customized copy and installs it with its own button.)
set -e
[ "$(id -u)" = 0 ] || { echo "Run with sudo."; exit 1; }
AQUI="$(cd "$(dirname "$0")" && pwd)"
DEST=/usr/local/share/sddm/themes/vidro

IMG="${1:-}"
if [ -z "$IMG" ]; then
    for w in /usr/share/wallpapers/Honeywave /usr/share/wallpapers/Next; do
        [ -d "$w/contents/images" ] || continue
        IMG=$(ls -S "$w"/contents/images/*.{jpg,png} 2>/dev/null | head -1); [ -n "$IMG" ] && break
    done
fi
[ -f "$IMG" ] || { echo "Background image not found. Pass one: sudo bash $0 /path/image.jpg"; exit 1; }

# backup of the SDDM configuration
B=/var/backups/vidro-sddm-$(date +%Y%m%d-%H%M%S); mkdir -p "$B"
cp -a /etc/sddm.conf.d "$B/" 2>/dev/null || true; [ -f /etc/sddm.conf ] && cp -a /etc/sddm.conf "$B/"

rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
cp -r "$AQUI/vidro" "$DEST"
if command -v magick >/dev/null; then
    magick "$IMG" -resize 2560x\> -quality 90 "$DEST/background.jpg"
    magick "$IMG" -resize 1280x -blur 0x28 -modulate 92,135 -quality 88 "$DEST/background-blur.jpg"
else
    cp "$IMG" "$DEST/background.jpg"; cp "$IMG" "$DEST/background-blur.jpg"
fi
chmod -R a+rX "$DEST"

mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/zzz-vidro.conf <<'CONF'
[General]
# empty = no Qt virtual keyboard; the on-screen keyboard comes from the compositor (e.g. plasma-keyboard)
InputMethod=

[Theme]
ThemeDir=/usr/local/share/sddm/themes
Current=vidro
CONF
echo "Done. Backup in $B. The Vidro login appears at the next boot."
echo "Test without rebooting: sddm-greeter-qt6 --test-mode --theme $DEST"
echo "If your system logs in automatically (autologin), SDDM is never shown — see the README."
