#!/bin/bash
# Vidro — desinstalador. Volta ao Breeze Dark, remove os arquivos do Vidro e
# oferece restaurar as configurações guardadas pelo instalador.
#   ./desinstalar.sh            pergunta antes de restaurar o backup
#   ./desinstalar.sh --restaurar restaura o último backup sem perguntar
set -uo pipefail
D="${XDG_DATA_HOME:-$HOME/.local/share}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"

echo "Vidro — desinstalação"
# desfaz o que os módulos das Configurações do Vidro mudam fora dos arquivos do Vidro
# (cores de todos os apps, Dolphin, barra de rolagem, EditorKden) — o vidrorc volta como estava
if [ -x "$BIN/vidro-config" ]; then
    RC="$CFG/vidrorc"; [ -f "$RC" ] && cp -a "$RC" "$RC.desinstalar"
    for gk in "Pastas ativo false" "Cores destaque tema" "Cores fonte tema" "Claro ativo false" \
              "Barra ativo false" "EditorKden ativo false"; do
        set -- $gk; "$BIN/vidro-config" set "$1" "$2" "$3" >/dev/null 2>&1
    done
    "$BIN/vidro-config" aplicar pastas cores claro barra editorkden >/dev/null 2>&1
    if [ -f "$RC.desinstalar" ]; then mv "$RC.desinstalar" "$RC"; else rm -f "$RC"; fi
fi
rm -f "$CFG/plasma-workspace/env/vidro-barra.sh"
for f in "$D/applications/org.kde.dolphin.desktop" "$D/dbus-1/services/org.kde.dolphin.FileManager1.service"; do
    grep -q 'vidro-config' "$f" 2>/dev/null && rm -f "$f"
done
rm -rf "$D/union/styles/vidro-dolphin"
[ -x "$BIN/vidro-tema" ] && "$BIN/vidro-tema" desligar >/dev/null 2>&1

systemctl --user disable --now vidro-cor-titulo.path >/dev/null 2>&1
rm -f "$CFG/systemd/user/vidro-cor-titulo.path" "$CFG/systemd/user/vidro-cor-titulo.service"
rm -f "$CFG/systemd/user/plasma-kwin_wayland.service.d/vidro.conf"{,.off}
rm -f "$D/dbus-1/services/org.kde.LogoutPrompt.service"{,.off}
rm -rf "$D/aurorae/themes/Vidro" "$D/plasma/desktoptheme/Vidro" "$D/color-schemes/Vidro.colors" \
       "$D/icons/Vidro" "$D/union/styles/vidro" "$D/plasma/look-and-feel/org.vidro.desktop" \
       "$D/plasma/plasmoids/org.vidro.transparencia" "$D/plasma/shells/org.vidro.desktop" \
       "$D"/kwin/effects/vidro_* "$D/plasma/plasmoids/org.vidro.config" "$D/color-schemes/VidroClaro.colors" \
       "$D/vidro/modulos" "$D/vidro/modelos" "$D/vidro/bin" "$D/vidro/qtplugins"
rm -f "$D/applications/vidro-configuracoes.desktop" "$D/vidro/versao"
rm -f "$BIN/vidro-tema" "$BIN/vidro-transparencia" "$BIN/vidro-cor-titulo" "$BIN/vidro-config" "$BIN/vidro-atualizar"
kwriteconfig6 --file kwinrc --group Plugins --key vidro_opacityEnabled false
kwriteconfig6 --file kwinrc --group Plugins --key vidro_popupsEnabled false
systemctl --user daemon-reload
echo "  ✓ arquivos do Vidro removidos"

ULT=$(cat "$D/vidro/ultimo-backup" 2>/dev/null || true)
if [ -n "$ULT" ] && [ -d "$ULT" ]; then
    r=n
    if [ "${1:-}" = "--restaurar" ]; then r=s
    else read -r -p "Restaurar as configurações de antes do Vidro ($ULT)? [s/N] " r; fi
    if [[ "$r" =~ ^[sSyY] ]]; then
        for f in "$ULT"/*; do
            n=$(basename "$f")
            if [ -d "$f" ]; then rm -rf "$CFG/$n"; cp -a "$f" "$CFG/$n"; else cp -a "$f" "$CFG/$n"; fi
        done
        echo "  ✓ configurações restauradas"
    fi
fi
dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure
echo "Pronto. Saia e entre de novo na sessão para tudo voltar ao normal."
echo "(Login SDDM e NotepadK têm desinstaladores próprios em componentes/sddm e componentes/notepadk.)"
