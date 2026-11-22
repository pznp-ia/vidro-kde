#!/bin/bash
# (the .deb/.rpm are x86_64 because they carry the prebuilt native parts; on other CPUs install.sh compiles them)
# Builds the release files into dist/: source tarball, .deb, .rpm and SHA256SUMS.
# Needs: git, tar, dpkg-deb (deb) and rpmbuild (rpm). On Fedora: sudo dnf install dpkg rpm-build
#   bash packaging/build-packages.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VER=$(sed 's/^v//' "$ROOT/VERSION")
DIST="$ROOT/dist"; rm -rf "$DIST"; mkdir -p "$DIST"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
# 1) source tarball (what GitHub would give, plus a top folder named vidro-kde-<ver>)
git -C "$ROOT" archive --format=tar.gz --prefix="vidro-kde-$VER/" -o "$DIST/vidro-kde-$VER.tar.gz" HEAD
# staging tree: /usr/share/vidro-kde + /usr/bin/vidro-kde-install
S="$T/root"; mkdir -p "$S/usr/share/vidro-kde" "$S/usr/bin"
tar -xzf "$DIST/vidro-kde-$VER.tar.gz" -C "$T"
cp -a "$T/vidro-kde-$VER/." "$S/usr/share/vidro-kde/"
install -m755 "$ROOT/packaging/vidro-kde-install" "$S/usr/bin/vidro-kde-install"
DESC="Glassy translucent look for KDE Plasma 6 with a settings app. After installing, each user runs: vidro-kde-install"
# 2) .deb
if command -v dpkg-deb >/dev/null; then
    D="$T/deb"; cp -a "$S" "$D"; mkdir -p "$D/DEBIAN"
    cat > "$D/DEBIAN/control" <<CTRL
Package: vidro-kde
Version: $VER
Section: x11
Priority: optional
Architecture: amd64
Depends: python3, python3-pil, imagemagick, ffmpeg, pipewire-bin, libkf6config-bin, qt6-tools-dev-tools, qml6-module-qtmultimedia, kwin-wayland | kwin-x11
Recommends: kate, qml6-module-qtquick-dialogs
Maintainer: Vidro <noreply@github.com>
Homepage: https://github.com/pznp-ia/vidro-kde
Description: Vidro - glassy look for KDE Plasma 6
 $DESC
CTRL
    dpkg-deb --root-owner-group --build "$D" "$DIST/vidro-kde_${VER}_amd64.deb" >/dev/null
fi
# 3) .rpm
if command -v rpmbuild >/dev/null; then
    R="$T/rpm"; mkdir -p "$R"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    tar -czf "$R/SOURCES/stage.tar.gz" -C "$S" .
    cat > "$R/SPECS/vidro-kde.spec" <<SPEC
Name:           vidro-kde
Version:        $VER
Release:        1
Summary:        Vidro - glassy look for KDE Plasma 6
License:        GPL-3.0-or-later
URL:            https://github.com/pznp-ia/vidro-kde
BuildArch:      x86_64
%global debug_package %{nil}
%global __strip /bin/true
%global _build_id_links none
Source0:        stage.tar.gz
Requires:       python3, python3-pillow, ImageMagick, pipewire-utils, kf6-kconfig, qt6-qttools, qt6-qtmultimedia, kwin
Recommends:     kate, ffmpeg-free
%description
$DESC
%prep
%install
mkdir -p %{buildroot}
tar -xzf %{SOURCE0} -C %{buildroot}
%files
/usr/share/vidro-kde
/usr/bin/vidro-kde-install
SPEC
    rpmbuild --quiet --define "_topdir $R" --define "__brp_mangle_shebangs %{nil}" -bb "$R/SPECS/vidro-kde.spec"
    cp "$R"/RPMS/x86_64/*.rpm "$DIST/"
fi
cp "$ROOT/packaging/install-deps.sh" "$ROOT/packaging/install-vidro.sh" "$DIST/"
sed "s/^pkgver=.*/pkgver=$VER/" "$ROOT/packaging/PKGBUILD" > "$DIST/PKGBUILD"
( cd "$DIST" && sha256sum * > SHA256SUMS )
ls -la "$DIST"
