#!/bin/bash
# Vidro — quick installer: downloads the newest release from GitHub and runs its installer
# (opens a window to choose the extras when there is a graphical session).
#
#   Terminal:  bash <(curl -fsSL https://github.com/pznp-ia/vidro-kde/releases/latest/download/install-vidro.sh)
#   Options go after it, e.g.  … install-vidro.sh) --all      (everything, no questions)
#   Graphical: download this file, Properties → Permissions → "Is executable", then double-click it.
#   A specific version: VIDRO_VERSION=v25 bash install-vidro.sh
#
# The files are kept in ~/.local/share/vidro-kde (there you find uninstall.sh). Per user, no sudo.
set -euo pipefail
REPO=pznp-ia/vidro-kde
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/vidro-kde"
gui() { [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && command -v kdialog >/dev/null && [ ! -t 1 ]; }
msg() { if gui; then kdialog --title "Vidro" --msgbox "$1"; else printf '%s\n' "$1"; fi; }
fail() { if gui; then kdialog --title "Vidro" --error "$1"; else printf 'erro: %s\n' "$1" >&2; fi; exit 1; }
command -v curl >/dev/null || fail "Precisa do curl para baixar o Vidro."
command -v tar >/dev/null || fail "Precisa do tar."
if [ -n "${VIDRO_VERSION:-}" ]; then
    API="https://api.github.com/repos/$REPO/releases/tags/$VIDRO_VERSION"
else
    API="https://api.github.com/repos/$REPO/releases/latest"
fi
INFO=$(curl -fsSL --max-time 30 "$API") || fail "Não consegui falar com o GitHub (sem internet?)."
TAG=$(printf '%s' "$INFO" | grep -m1 '"tag_name"' | cut -d'"' -f4)
URL=$(printf '%s' "$INFO" | grep -m1 '"tarball_url"' | cut -d'"' -f4)
[ -n "$URL" ] || fail "Versão não encontrada."
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
echo "Baixando o Vidro $TAG…"
curl -fL --progress-bar --max-time 300 "$URL" -o "$T/vidro.tar.gz" || fail "O download falhou."
mkdir -p "$T/src"; tar -xzf "$T/vidro.tar.gz" -C "$T/src" --strip-components=1 || fail "O arquivo baixado está corrompido."
rm -rf "$DEST.new"; mkdir -p "$(dirname "$DEST")"; mv "$T/src" "$DEST.new"; rm -rf "$DEST"; mv "$DEST.new" "$DEST"
cd "$DEST"
bash ./install.sh "$@"
echo
echo "Arquivos do Vidro em $DEST (para remover: bash $DEST/uninstall.sh)"
