#!/bin/bash
# Installs what Vidro uses, on the most common distributions (needs sudo).
#   bash packaging/install-deps.sh            runtime dependencies
#   bash packaging/install-deps.sh --build    + compilers and Qt/KDE headers (native parts, NotepadK)
# Immutable systems (Bazzite, Kinoite, Aurora, SteamOS…): the runtime tools usually come with the image;
# for --build use a distrobox/toolbox with the same Fedora version.
set -e
BUILD=0; [ "$1" = "--build" ] && BUILD=1
. /etc/os-release 2>/dev/null || true
ids=" ${ID:-} ${ID_LIKE:-} "
say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
if [ -e /run/ostree-booted ]; then
    say "Sistema imutável detectado ($NAME). As ferramentas do Vidro normalmente já vêm na imagem."
    say "Para compilar as partes nativas use: distrobox create -i fedora:${VERSION_ID:-latest} && distrobox enter … && bash $0 --build"
    exit 0
fi
case "$ids" in
  *" debian "*|*" ubuntu "*|*" neon "*)
    P="python3 python3-pil imagemagick ffmpeg pipewire-bin libkf6config-bin qt6-tools-dev-tools qml6-module-qtmultimedia qml6-module-qtquick-dialogs"
    B="cmake g++ qt6-base-dev qt6-declarative-dev libkf6texteditor-dev libkf6syntaxhighlighting-dev libkf6xmlgui-dev extra-cmake-modules"
    sudo apt-get update; sudo apt-get install -y $P $([ $BUILD = 1 ] && echo $B) ;;
  *" fedora "*|*" rhel "*)
    P="python3 python3-pillow ImageMagick ffmpeg-free pipewire-utils kf6-kconfig qt6-qttools qt6-qtmultimedia"
    B="cmake gcc-c++ qt6-qtbase-devel qt6-qtdeclarative-devel kf6-ktexteditor-devel kf6-syntax-highlighting-devel kf6-kxmlgui-devel extra-cmake-modules"
    sudo dnf install -y $P $([ $BUILD = 1 ] && echo $B) ;;
  *" arch "*|*" manjaro "*|*" endeavouros "*|*" cachyos "*)
    P="python python-pillow imagemagick ffmpeg pipewire kconfig qt6-tools qt6-multimedia"
    B="cmake gcc qt6-base qt6-declarative ktexteditor syntax-highlighting kxmlgui extra-cmake-modules"
    sudo pacman -S --needed --noconfirm $P $([ $BUILD = 1 ] && echo $B) ;;
  *" opensuse"*|*" suse "*)
    P="python3 python3-Pillow ImageMagick ffmpeg pipewire-tools kf6-kconfig-imports kconfig6 qt6-tools-qdbus qt6-multimedia-imports"
    B="cmake gcc-c++ qt6-base-devel qt6-declarative-devel kf6-ktexteditor-devel kf6-syntax-highlighting-devel kf6-kxmlgui-devel kf6-extra-cmake-modules"
    sudo zypper install -y $P $([ $BUILD = 1 ] && echo $B) ;;
  *)
    say "Distribuição não reconhecida ($ID). Instale: python3 + Pillow, ImageMagick, ffmpeg, pw-play (pipewire),"
    say "kwriteconfig6/kreadconfig6 (KConfig), qdbus (Qt 6 tools) e o módulo QML QtMultimedia."
    exit 1 ;;
esac
say "Pronto. Agora: ./install.sh"
