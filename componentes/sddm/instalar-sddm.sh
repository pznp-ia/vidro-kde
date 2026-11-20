#!/bin/bash
# Instala o tema de login Vidro no SDDM.
# Uso: sudo bash componentes/sddm/instalar-sddm.sh [imagem-de-fundo]
#   Sem imagem, usa o papel de parede Honeywave do KDE (ou Next, se não houver).
# Para desfazer: sudo bash componentes/sddm/desfazer-sddm.sh
set -e
[ "$(id -u)" = 0 ] || { echo "Rode com sudo."; exit 1; }
AQUI="$(cd "$(dirname "$0")" && pwd)"
DEST=/usr/local/share/sddm/themes/vidro

IMG="${1:-}"
if [ -z "$IMG" ]; then
    for w in /usr/share/wallpapers/Honeywave /usr/share/wallpapers/Next; do
        [ -d "$w/contents/images" ] || continue
        IMG=$(ls -S "$w"/contents/images/*.{jpg,png} 2>/dev/null | head -1); [ -n "$IMG" ] && break
    done
fi
[ -f "$IMG" ] || { echo "Imagem de fundo não encontrada. Passe uma: sudo bash $0 /caminho/imagem.jpg"; exit 1; }

# backup da configuração do SDDM
B=/var/backups/vidro-sddm-$(date +%Y%m%d-%H%M%S); mkdir -p "$B"
cp -a /etc/sddm.conf.d "$B/" 2>/dev/null || true; [ -f /etc/sddm.conf ] && cp -a /etc/sddm.conf "$B/"

rm -rf "$DEST"; mkdir -p "$(dirname "$DEST")"
cp -r "$AQUI/vidro" "$DEST"
if command -v magick >/dev/null; then
    magick "$IMG" -resize 2560x\> -quality 90 "$DEST/fundo.jpg"
    magick "$IMG" -resize 1280x -blur 0x28 -modulate 92,135 -quality 88 "$DEST/fundo-desfocado.jpg"
else
    cp "$IMG" "$DEST/fundo.jpg"; cp "$IMG" "$DEST/fundo-desfocado.jpg"
fi
chmod -R a+rX "$DEST"

mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/zzz-vidro.conf <<'CONF'
[General]
# vazio = sem o teclado virtual do Qt; quem abre o teclado de tela é o compositor (ex.: plasma-keyboard)
InputMethod=

[Theme]
ThemeDir=/usr/local/share/sddm/themes
Current=vidro
CONF
echo "Pronto. Backup em $B. O login Vidro aparece no próximo boot."
echo "Testar sem reiniciar: sddm-greeter-qt6 --test-mode --theme $DEST"
echo "Se o seu sistema entra direto sem pedir senha (login automático), o SDDM não aparece — veja o README."
