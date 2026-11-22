#!/bin/bash
# NotepadK — builds the Kate plugin and installs the launcher (for your user only).
# Needs: kate, cmake, g++, extra-cmake-modules and the KTextEditor (KF6) development packages:
#   Fedora:        sudo dnf install cmake gcc-c++ extra-cmake-modules kf6-ktexteditor-devel kf6-syntax-highlighting-devel kf6-kxmlgui-devel kf6-ki18n-devel qt6-qtbase-devel
#   Arch:          sudo pacman -S cmake extra-cmake-modules ktexteditor
#   Debian/Ubuntu: sudo apt install cmake g++ extra-cmake-modules libkf6texteditor-dev libkf6syntaxhighlighting-dev libkf6xmlgui-dev libkf6i18n-dev qt6-base-dev
# On immutable systems (Bazzite, Kinoite...) run this script inside a distrobox/toolbox of the same
# distribution and version as the system — the built plugin is used by the system's Kate.
# Remover: bash instalar-notepadk.sh --remover
set -e
AQUI="$(cd "$(dirname "$0")" && pwd)"
BASE="$HOME/.local/share/notepadk"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
if [ "${1:-}" = "--remover" ]; then
    rm -rf "$BASE" "$HOME/.local/bin/notepadk" "$APPS/notepadk.desktop"
    echo "NotepadK removido."; exit 0
fi
command -v kate >/dev/null || echo "Aviso: o Kate não foi encontrado neste ambiente (precisa estar instalado no sistema)."
command -v cmake >/dev/null || { echo "Instale o cmake e os pacotes listados no topo deste script."; exit 1; }
B=$(mktemp -d)
cmake -S "$AQUI" -B "$B" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$BASE/install" -DKDE_INSTALL_QTPLUGINDIR=lib64/plugins >/dev/null
cmake --build "$B" -j"$(nproc)"
cmake --install "$B" >/dev/null
rm -rf "$B"
install -Dm755 "$AQUI/notepadk" "$HOME/.local/bin/notepadk"
install -Dm644 "$AQUI/notepadk.desktop" "$APPS/notepadk.desktop"
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true
echo "NotepadK instalado. Abra pelo menu ou com: notepadk arquivo.txt"
