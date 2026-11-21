#!/bin/bash
# Compila a janela de prévia (vidro-previa) e o plugin da barra de rolagem (libvidroscroll.so)
# com o Qt do seu sistema. Precisa de cmake, g++ e os pacotes de desenvolvimento do Qt 6
# (Fedora: qt6-qtbase-devel). No Bazzite/Silverblue rode dentro de uma distrobox Fedora.
#   bash compilar.sh [pasta-de-saída]     (padrão: esta pasta)
set -euo pipefail
AQUI="$(cd "$(dirname "$0")" && pwd)"
SAIDA="${1:-$AQUI}"
command -v cmake >/dev/null && command -v g++ >/dev/null || { echo "precisa de cmake e g++"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
for p in menuteste vidroscroll; do
    cmake -S "$AQUI/fonte/$p" -B "$T/$p" -DCMAKE_BUILD_TYPE=Release >/dev/null
    cmake --build "$T/$p" -j"$(nproc)" >/dev/null
done
install -m 755 "$T/menuteste/vidro-previa" "$SAIDA/vidro-previa"
install -m 755 "$T/vidroscroll/libvidroscroll.so" "$SAIDA/libvidroscroll.so"
echo "pronto: $SAIDA/vidro-previa e $SAIDA/libvidroscroll.so"
