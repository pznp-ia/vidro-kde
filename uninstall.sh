#!/bin/bash
# Vidro uninstaller. Switches back to Breeze Dark, removes the Vidro files and offers to restore
# the settings saved by the installer. Your profiles (~/.local/share/vidro/profiles) are kept.
#   ./uninstall.sh            asks before restoring the backup
#   ./uninstall.sh --restore  restores the last backup without asking
set -uo pipefail
D="${XDG_DATA_HOME:-$HOME/.local/share}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"

echo "Vidro — uninstall"
# undo what the modules change outside the Vidro files (colors of every app, Dolphin, scrollbar,
# EditorKden, cursor, panel glass) — vidrorc is put back as it was
if [ -x "$BIN/vidro-config" ]; then
    RC="$CFG/vidrorc"; [ -f "$RC" ] && cp -a "$RC" "$RC.uninstall"
    for gk in "Dolphin enabled false" "Colors accent theme" "Colors text theme" "Light enabled false" \
              "Scrollbar enabled false" "EditorKden enabled false" "Cursor enabled false" "Panel glass_enabled false" \
              "AppStyle enabled false"; do
        set -- $gk; "$BIN/vidro-config" set "$1" "$2" "$3" >/dev/null 2>&1
    done
    "$BIN/vidro-config" apply dolphin colors light scrollbar editorkden cursor panel appstyle >/dev/null 2>&1
    if [ -f "$RC.uninstall" ]; then mv "$RC.uninstall" "$RC"; else rm -f "$RC"; fi
fi
rm -f "$CFG/plasma-workspace/env/vidro-scrollbar.sh" "$CFG/plasma-workspace/env/vidro-barra.sh"
for f in "$D/applications/org.kde.dolphin.desktop" "$D/dbus-1/services/org.kde.dolphin.FileManager1.service"; do
    grep -q 'vidro-config' "$f" 2>/dev/null && rm -f "$f"
done
rm -rf "$D/union/styles/vidro-dolphin"
[ -x "$BIN/vidro-theme" ] && "$BIN/vidro-theme" off >/dev/null 2>&1

for u in vidro-titlebar vidro-cor-titulo; do
    systemctl --user disable --now "$u.path" >/dev/null 2>&1
    rm -f "$CFG/systemd/user/$u.path" "$CFG/systemd/user/$u.service"
done
rm -f "$CFG/systemd/user/plasma-kwin_wayland.service.d/vidro.conf"{,.off}
rm -f "$D/dbus-1/services/org.kde.LogoutPrompt.service"{,.off}
rm -rf "$D/aurorae/themes/Vidro" "$D/plasma/desktoptheme/Vidro" "$D/color-schemes/Vidro.colors" "$D/color-schemes/VidroClaro.colors" \
       "$D/icons/Vidro" "$D/icons/VidroCursor" "$D/union/styles/vidro" "$D/plasma/look-and-feel/org.vidro.desktop" \
       "$D/plasma/plasmoids/org.vidro.transparencia" "$D/plasma/plasmoids/org.vidro.config" "$D/plasma/plasmoids/org.vidro.weather" \
       "$D/plasma/shells/org.vidro.desktop" "$D"/kwin/effects/vidro_* \
       "$D/vidro/modules" "$D/vidro/modulos" "$D/vidro/templates" "$D/vidro/modelos" "$D/vidro/bin" "$D/vidro/qtplugins" \
       "$D/vidro/cursor" "$D/vidro/login"
[ -L "$HOME/.icons/VidroCursor" ] && rm -f "$HOME/.icons/VidroCursor"
rm -f "$D/applications/vidro-settings.desktop" "$D/applications/vidro-configuracoes.desktop" "$D/vidro/version" "$D/vidro/versao"
for c in vidro-theme vidro-opacity vidro-titlebar vidro-config vidro-update vidro-profile \
         vidro-tema vidro-transparencia vidro-cor-titulo vidro-atualizar; do rm -f "$BIN/$c"; done
for e in vidro_opacity vidro_popups vidro_windows vidro_minimize vidro_maximize vidro_desktop; do
    kwriteconfig6 --file kwinrc --group Plugins --key "${e}Enabled" false
done
systemctl --user daemon-reload
echo "  ✓ Vidro files removed (profiles kept in $D/vidro/profiles)"

LAST=$(cat "$D/vidro/last-backup" 2>/dev/null || cat "$D/vidro/ultimo-backup" 2>/dev/null || true)
if [ -n "$LAST" ] && [ -d "$LAST" ]; then
    r=n
    if [ "${1:-}" = "--restore" ] || [ "${1:-}" = "--restaurar" ]; then r=y
    else read -r -p "Restore the settings from before Vidro ($LAST)? [y/N] " r; fi
    if [[ "$r" =~ ^[sSyY] ]]; then
        for f in "$LAST"/*; do
            n=$(basename "$f")
            if [ -d "$f" ]; then rm -rf "$CFG/$n"; cp -a "$f" "$CFG/$n"; else cp -a "$f" "$CFG/$n"; fi
        done
        echo "  ✓ settings restored"
    fi
fi
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure
echo "Done. Log out and in for everything to go back to normal."
echo "(The login screen has its own undo: sudo bash components/sddm/undo-sddm.sh)"
