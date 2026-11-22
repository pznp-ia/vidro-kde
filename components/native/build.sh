#!/bin/bash
# Builds the preview window (vidro-preview) and the scrollbar plugin (libvidroscroll.so)
# with your system's Qt. Needs cmake, g++ and the Qt 6 development packages
# (Fedora: qt6-qtbase-devel). On Bazzite/Silverblue run it inside a Fedora distrobox.
#   bash build.sh [output-folder]     (default: this folder)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$HERE}"
command -v cmake >/dev/null && command -v g++ >/dev/null || { echo "needs cmake and g++"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
for p in preview vidroscroll login-preview; do
    cmake -S "$HERE/src/$p" -B "$T/$p" -DCMAKE_BUILD_TYPE=Release >/dev/null
    cmake --build "$T/$p" -j"$(nproc)" >/dev/null
done
install -m 755 "$T/preview/vidro-preview" "$OUT/vidro-preview"
install -m 755 "$T/vidroscroll/libvidroscroll.so" "$OUT/libvidroscroll.so"
install -m 755 "$T/login-preview/vidro-login-preview" "$OUT/vidro-login-preview"
echo "done: $OUT/vidro-preview and $OUT/libvidroscroll.so"
