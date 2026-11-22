#!/bin/bash
# Vidro installer — installs for your user only (no sudo, except the optional login screen).
#
#   ./install.sh                     choose the components in a window (or in the terminal) and install
#   ./install.sh --all               install everything without asking
#   ./install.sh --only=effects,weather      core + only these optional components
#   ./install.sh --skip=notepadk,sddm        everything except these
#   ./install.sh --no-gui            ask in the terminal instead of a window
#   ./install.sh --no-apply          only copy the files (turn it on later with: vidro-theme on)
#   ./install.sh --update            used by vidro-update: refresh installed parts, keep your settings
#
# Optional components: effects, lockscreen, native, weather, sddm, notepadk
# Before changing any setting, a backup is saved to ~/.local/share/vidro/backup-<date>.
# To undo: ./uninstall.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
C="$HERE/components"
D="${XDG_DATA_HOME:-$HOME/.local/share}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
VERSION=$(cat "$HERE/VERSION" 2>/dev/null || cat "$HERE/VERSAO" 2>/dev/null || echo "?")

APPLY=1; UPDATE=0; GUI=auto; MODE=ask; LIST=""
for a in "$@"; do
    case "$a" in
        --all) MODE=all ;;
        --only=*) MODE=only; LIST="${a#--only=}" ;;
        --skip=*) MODE=skip; LIST="${a#--skip=}" ;;
        --no-gui) GUI=no ;;
        --no-apply|--sem-ligar) APPLY=0 ;;
        --update|--atualizar) UPDATE=1 ;;
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $a (see --help)"; exit 1 ;;
    esac
done

ok()   { printf '  \e[32m✓\e[0m %s\n' "$*"; SUMMARY+="✓ $*\n"; }
warn() { printf '  \e[33m!\e[0m %s\n' "$*"; SUMMARY+="! $*\n"; }
fail() { printf '\e[31mError:\e[0m %s\n' "$*" >&2; gui_error "$*"; exit 1; }
SUMMARY=""

# ---------- dialogs (kdialog, zenity or terminal) ----------
has_display() { [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; }
if [ "$GUI" = auto ]; then
    if has_display && command -v kdialog >/dev/null; then GUI=kdialog
    elif has_display && command -v zenity >/dev/null; then GUI=zenity
    else GUI=no; fi
fi
gui_error() {
    case "$GUI" in
        kdialog) kdialog --title "Vidro" --error "$1" 2>/dev/null ;;
        zenity) zenity --error --title "Vidro" --text "$1" 2>/dev/null ;;
    esac
}
# progress: kdialog progress bar driven over D-Bus; zenity reads percentages from a pipe
PROGRESS=""
progress_start() {
    if [ "$GUI" = kdialog ]; then
        PROGRESS=$(kdialog --title "Vidro" --progressbar "Instalando o Vidro $VERSION…" 100 2>/dev/null)
    elif [ "$GUI" = zenity ]; then
        exec 7> >(zenity --progress --title "Vidro" --text "Instalando o Vidro $VERSION…" --auto-close --no-cancel 2>/dev/null)
        PROGRESS=zenity
    fi
}
progress() { # progress <percent> <label>
    echo "→ $2"
    if [ "$GUI" = kdialog ] && [ -n "$PROGRESS" ]; then
        set -- "$1" "$2" $PROGRESS
        dbus-send --session --dest="$3" "$4" org.freedesktop.DBus.Properties.Set \
            string:org.kde.kdialog.ProgressDialog string:value variant:int32:"$1" >/dev/null 2>&1
        dbus-send --session --dest="$3" "$4" org.kde.kdialog.ProgressDialog.setLabelText string:"$2" >/dev/null 2>&1
    elif [ "$PROGRESS" = zenity ]; then
        printf '%s\n# %s\n' "$1" "$2" >&7
    fi
}
progress_end() {
    if [ "$GUI" = kdialog ] && [ -n "$PROGRESS" ]; then
        set -- $PROGRESS
        dbus-send --session --dest="$1" "$2" org.kde.kdialog.ProgressDialog.close >/dev/null 2>&1
    elif [ "$PROGRESS" = zenity ]; then
        echo 100 >&7; exec 7>&-
    fi
}

# ---------- requirements ----------
command -v plasmashell >/dev/null || fail "KDE Plasma não encontrado."
command -v kwriteconfig6 >/dev/null || fail "kwriteconfig6 não encontrado (o Vidro precisa do Plasma 6)."
command -v python3 >/dev/null || fail "python3 é necessário."
PV=$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true)
[ -n "$PV" ] || PV=$(rpm -q --qf '%{VERSION}' plasma-workspace 2>/dev/null || dpkg-query -W -f '${Version}' plasma-workspace 2>/dev/null || true)
case "$PV" in 6.*) ;; *) fail "o Vidro é para o Plasma 6 (encontrado: ${PV:-desconhecido}).";; esac
UNION=0
if [ -d /usr/share/union/styles/breeze ] || ls /usr/lib*/qt6/plugins/styles/*nion* >/dev/null 2>&1; then UNION=1; fi
HAS_KDENLIVE=0; flatpak info org.kde.kdenlive >/dev/null 2>&1 && HAS_KDENLIVE=1

# ---------- choose components ----------
OPTIONAL="effects lockscreen native weather sddm notepadk"
declare -A LABEL=(
    [effects]="Animações e transparência das janelas (efeitos da KWin)"
    [lockscreen]="Telas de bloqueio e de sair no estilo Vidro (Plasma 6.8)"
    [native]="Barra de rolagem por cima do conteúdo + janela de prévia"
    [weather]="Widget de clima leve"
    [sddm]="Tela de login (SDDM) — pede a senha de administrador"
    [notepadk]="NotepadK, bloco de notas sem distrações (precisa compilar)"
)
declare -A DEFAULT_ON=([effects]=on [lockscreen]=on [native]=on [weather]=on [sddm]=off [notepadk]=off)
[[ "$PV" == 6.8* ]] || DEFAULT_ON[lockscreen]=off
declare -A WANT=()

if [ "$UPDATE" = 1 ]; then   # keep what is already installed
    [ -d "$D/kwin/effects/vidro_opacity" ] && WANT[effects]=1
    [ -d "$D/plasma/shells/org.vidro.desktop" ] && WANT[lockscreen]=1
    [ -f "$D/vidro/qtplugins/styles/libvidroscroll.so" ] && WANT[native]=1
    [ -d "$D/plasma/plasmoids/org.vidro.weather" ] && WANT[weather]=1
    GUI=no
elif [ "$MODE" = all ]; then
    for k in $OPTIONAL; do WANT[$k]=1; done
elif [ "$MODE" = only ]; then
    for k in ${LIST//,/ }; do WANT[$k]=1; done
elif [ "$MODE" = skip ]; then
    for k in $OPTIONAL; do [[ ",$LIST," == *",$k,"* ]] || WANT[$k]=1; done
elif [ "$GUI" = kdialog ]; then
    args=()
    for k in $OPTIONAL; do args+=("$k" "${LABEL[$k]}" "${DEFAULT_ON[$k]}"); done
    chosen=$(kdialog --title "Vidro $VERSION" --geometry 640x420 --checklist \
        "O essencial do Vidro (decoração das janelas, estilo do Plasma e dos apps, cores, ícones, cursor e o app Configurações do Vidro) sempre é instalado.\n\nEscolha os extras:" \
        "${args[@]}" 2>/dev/null) || { echo "Instalação cancelada."; exit 0; }
    for k in $chosen; do WANT[${k//\"/}]=1; done
    kdialog --title "Vidro" --yesno "Ligar o Vidro agora?\n\n(Se escolher \"Não\", ligue depois com: vidro-theme on)" 2>/dev/null || APPLY=0
elif [ "$GUI" = zenity ]; then
    args=()
    for k in $OPTIONAL; do args+=("$([ "${DEFAULT_ON[$k]}" = on ] && echo TRUE || echo FALSE)" "$k" "${LABEL[$k]}"); done
    chosen=$(zenity --list --checklist --title "Vidro $VERSION" --width 640 --height 420 \
        --text "O essencial do Vidro sempre é instalado. Escolha os extras:" \
        --column "" --column "id" --column "Componente" --hide-column 2 --separator " " "${args[@]}" 2>/dev/null) || { echo "Instalação cancelada."; exit 0; }
    for k in $chosen; do WANT[$k]=1; done
    zenity --question --title "Vidro" --text "Ligar o Vidro agora?" 2>/dev/null || APPLY=0
elif [ -t 0 ]; then
    echo "Vidro $VERSION — o essencial sempre é instalado. Extras (Enter = padrão):"
    for k in $OPTIONAL; do
        d=${DEFAULT_ON[$k]}; hint=$([ "$d" = on ] && echo "S/n" || echo "s/N")
        read -r -p "  ${LABEL[$k]}? [$hint] " r
        if [ -z "$r" ]; then [ "$d" = on ] && WANT[$k]=1; elif [[ "$r" =~ ^[sSyY] ]]; then WANT[$k]=1; fi
    done
else
    for k in $OPTIONAL; do [ "${DEFAULT_ON[$k]}" = on ] && WANT[$k]=1; done
fi
want() { [ -n "${WANT[$1]:-}" ]; }

if [ "$UPDATE" = 1 ]; then echo "Vidro — updating to $VERSION"; else echo "Vidro $VERSION — installing"; fi
progress_start

# ---------- backup ----------
progress 5 "Guardando uma cópia das suas configurações…"
B="$D/vidro/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$B"
for f in kdeglobals kwinrc plasmarc kcminputrc ksplashrc kscreenlockerrc dolphinrc; do
    [ -f "$CFG/$f" ] && cp -a "$CFG/$f" "$B/"
done
[ -d "$CFG/kdedefaults" ] && cp -a "$CFG/kdedefaults" "$B/"
# "last-backup" is what the uninstaller restores: keep the one from BEFORE Vidro, not from an update
LAST=$(cat "$D/vidro/last-backup" 2>/dev/null || cat "$D/vidro/ultimo-backup" 2>/dev/null || true)
if [ -z "$LAST" ] || [ ! -d "$LAST" ]; then echo "$B" > "$D/vidro/last-backup"; fi
ok "backup das configurações em $B"

# ---------- core ----------
put() { rm -rf "$2"; mkdir -p "$(dirname "$2")"; cp -a "$1" "$2"; }   # put <source> <target> (replaces target)
progress 15 "Decoração, estilo do Plasma, cores e ícones…"
put "$C/decoration"               "$D/aurorae/themes/Vidro"
put "$C/plasma-style/Vidro"       "$D/plasma/desktoptheme/Vidro"
mkdir -p "$D/color-schemes"
cp "$C/color-schemes/Vidro.colors" "$C/color-schemes/VidroClaro.colors" "$D/color-schemes/"
put "$C/icons/Vidro"              "$D/icons/Vidro"
put "$C/look-and-feel"            "$D/plasma/look-and-feel/org.vidro.desktop"
put "$C/widget-opacity"           "$D/plasma/plasmoids/org.vidro.transparencia"
if [ "$UNION" = 1 ]; then
    put "$C/union/vidro" "$D/union/styles/vidro"
else
    warn "Union (plasma-union) não está instalado: os apps ficam com o estilo atual."
fi
# icons: mirror a base theme for the app icons Vidro does not redraw
BASE_ICONS=""
for t in "$D/icons/Tela-red-dark" /usr/share/icons/Tela-red-dark "$D/icons/Tela-dark" /usr/share/icons/Tela-dark /usr/share/icons/breeze-dark; do
    [ -f "$t/index.theme" ] && { BASE_ICONS="$t"; break; }
done
if [ -n "$BASE_ICONS" ]; then
    name=$(basename "$BASE_ICONS")
    inherits="$name,breeze-dark,hicolor"; [ "$name" = breeze-dark ] && inherits="breeze-dark,hicolor"
    sed -i "s|^Inherits=.*|Inherits=$inherits|" "$D/icons/Vidro/index.theme"
    python3 -I "$D/icons/Vidro/source/link-base-icons.py" "$D/icons/Vidro" "$BASE_ICONS" >/dev/null
fi
ok "decoração das janelas, estilo do Plasma, cores, ícones e tema global"

progress 35 "Comandos e o app Configurações do Vidro…"
mkdir -p "$BIN"
for s in vidro-theme vidro-opacity vidro-titlebar vidro-config vidro-update vidro-profile; do install -m 755 "$HERE/bin/$s" "$BIN/$s"; done
for pair in "vidro-tema vidro-theme" "vidro-transparencia vidro-opacity" "vidro-cor-titulo vidro-titlebar" "vidro-atualizar vidro-update"; do
    set -- $pair; ln -sfn "$2" "$BIN/$1"   # Portuguese names from older versions keep working
done
mkdir -p "$CFG/systemd/user"
cp "$HERE/systemd/vidro-titlebar.path" "$HERE/systemd/vidro-titlebar.service" "$CFG/systemd/user/"
systemctl --user disable --now vidro-cor-titulo.path >/dev/null 2>&1; rm -f "$CFG"/systemd/user/vidro-cor-titulo.*
if command -v magick >/dev/null; then
    systemctl --user daemon-reload
    systemctl --user enable --now vidro-titlebar.path >/dev/null 2>&1 || true
else
    warn "ImageMagick (magick) não encontrado: a cor automática da barra de título fica desligada."
fi
put "$C/settings/widget"  "$D/plasma/plasmoids/org.vidro.config"
mkdir -p "$D/vidro" "$D/applications"
rm -rf "$D/vidro/modulos" "$D/vidro/modelos"   # Portuguese folders of older versions
put "$C/settings/modules"   "$D/vidro/modules"
put "$C/settings/templates" "$D/vidro/templates"
put "$C/settings/cursor"    "$D/vidro/cursor"
put "$C/sddm/vidro"         "$D/vidro/login/base"
cp "$C/settings/vidro-settings.desktop" "$D/applications/"
rm -f "$D/applications/vidro-configuracoes.desktop"
echo "$VERSION" > "$D/vidro/version"; rm -f "$D/vidro/versao"
ok "comandos vidro-* e o app \"Configurações do Vidro\""

# ---------- optional ----------
if want effects; then
    progress 50 "Animações e transparência…"
    for e in "$C"/kwin-effects/vidro_*; do put "$e" "$D/kwin/effects/$(basename "$e")"; done
    ok "animações (abrir, fechar, minimizar, maximizar, mostrar área de trabalho) e transparência"
fi

if want native; then
    progress 58 "Barra de rolagem sobreposta…"
    # built with the Qt in components/native/QT; Qt does not load a plugin built with a newer version
    QT_SYS=$(rpm -q --qf '%{VERSION}' qt6-qtbase 2>/dev/null || pkg-config --modversion Qt6Core 2>/dev/null || true)
    QT_BUILT=$(cat "$C/native/QT" 2>/dev/null)
    native_ok=0
    if [ -n "$QT_SYS" ] && [ -f "$C/native/libvidroscroll.so" ] \
       && [ "$(printf '%s\n%s\n' "$QT_BUILT" "$QT_SYS" | sort -V | head -1)" = "$QT_BUILT" ]; then
        native_ok=1
    elif bash "$C/native/build.sh" "$C/native" >/dev/null 2>&1; then
        native_ok=1
    fi
    if [ "$native_ok" = 1 ]; then
        mkdir -p "$D/vidro/bin" "$D/vidro/qtplugins/styles"
        install -m 755 "$C/native/vidro-preview" "$D/vidro/bin/vidro-preview"
        ln -sfn vidro-preview "$D/vidro/bin/vidro-previa"
        install -m 755 "$C/native/libvidroscroll.so" "$D/vidro/qtplugins/styles/libvidroscroll.so"
        ok "barra de rolagem por cima do conteúdo e janela de prévia"
    else
        warn "Qt ${QT_SYS:-?} mais antigo que ${QT_BUILT} e sem compilador: barra sobreposta fica de fora."
    fi
fi

if want weather; then
    progress 64 "Widget de clima…"
    put "$C/weather" "$D/plasma/plasmoids/org.vidro.weather"
    ok "widget \"Clima (Vidro)\" (adicione pelo menu de widgets)"
fi

if want lockscreen; then
    progress 70 "Telas de bloqueio e de sair…"
    # the QML files are from Plasma 6.8; other versions may not open them, and a broken
    # lock screen would stop you from unlocking — so it only installs on 6.8
    SHELL_SYS=/usr/share/plasma/shells/org.kde.plasma.desktop
    if [[ "$PV" == 6.8* ]] && [ -d "$SHELL_SYS/contents" ]; then
        S="$D/plasma/shells/org.vidro.desktop"
        rm -rf "$S"; mkdir -p "$S/contents"
        cp -a "$C/shell/metadata.json" "$S/"
        cp -a "$C/shell/contents/lockscreen" "$C/shell/contents/logout" "$S/contents/"
        for x in "$SHELL_SYS"/contents/*; do
            n=$(basename "$x"); [ -e "$S/contents/$n" ] || ln -s "$x" "$S/contents/$n"
        done
        mkdir -p "$CFG/systemd/user/plasma-kwin_wayland.service.d" "$D/dbus-1/services"
        printf '[Service]\n# Vidro: lock screen from the org.vidro.desktop shell package\nEnvironment=PLASMA_DEFAULT_SHELL=org.vidro.desktop\n' \
            > "$CFG/systemd/user/plasma-kwin_wayland.service.d/vidro.conf"
        printf '[D-BUS Service]\nName=org.kde.LogoutPrompt\nExec=/usr/bin/env PLASMA_DEFAULT_SHELL=org.vidro.desktop /usr/libexec/ksmserver-logout-greeter\n' \
            > "$D/dbus-1/services/org.kde.LogoutPrompt.service"
        ok "telas de bloqueio e de sair (o bloqueio vale a partir do próximo login)"
    else
        warn "telas de bloqueio/sair puladas (feitas para o Plasma 6.8; o seu é $PV)."
    fi
fi

if want sddm; then
    progress 78 "Tela de login (pede a senha de administrador)…"
    if pkexec bash "$C/sddm/install-sddm.sh" >/dev/null 2>&1; then
        ok "tela de login Vidro (aparece no próximo boot)"
    else
        warn "tela de login não instalada (senha cancelada ou erro). Depois: sudo bash components/sddm/install-sddm.sh"
    fi
fi

if want notepadk; then
    progress 84 "NotepadK (compilando)…"
    if bash "$C/notepadk/install-notepadk.sh" >/dev/null 2>&1; then
        ok "NotepadK"
    else
        warn "NotepadK não compilou (faltam pacotes de desenvolvimento?). Veja components/notepadk/install-notepadk.sh"
    fi
fi

# ---------- turn on ----------
progress 90 "Aplicando…"
if [ "$UPDATE" = 1 ]; then
    # turns nothing on or off: only regenerates what the modules make, from ~/.config/vidrorc
    if [ "$(kreadconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage)" = org.vidro.desktop ]; then
        "$BIN/vidro-config" apply >/dev/null 2>&1 || warn "algum módulo falhou ao reaplicar: abra as Configurações do Vidro."
        "$BIN/vidro-titlebar" --force >/dev/null 2>&1 || true
        dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure
    fi
    progress_end
    echo; echo "Updated to $VERSION. Some parts (scrollbar, lock screen) take effect after logging out and in."
    exit 0
fi
if [ "$APPLY" = 1 ]; then
    UNION_OK=$UNION "$BIN/vidro-theme" on >/dev/null 2>&1 || true
    [ -n "$(kreadconfig6 --file kwinrc --group Effect-vidro_opacity --key Level)" ] || "$BIN/vidro-opacity" 50 >/dev/null
    "$BIN/vidro-config" apply >/dev/null 2>&1 || warn "algum módulo das Configurações do Vidro falhou."
    [ "$HAS_KDENLIVE" = 1 ] && ok "EditorKden (Kdenlive minimalista) no menu de apps"
    ok "Vidro ligado"
fi
progress_end

TIPS="Pronto!\n\n• Ajustes de tudo: app \"Configurações do Vidro\" (menu de apps).\n• Adicione o widget \"Transparência das janelas\" ao painel.\n• Ligar/desligar: vidro-theme on | off\n• Atualizar: vidro-update (ou a aba Atualizações)\n• Remover tudo: ./uninstall.sh\n\nSaia e entre de novo na sessão para tudo valer."
echo; printf "%b" "$TIPS" | sed 's/^/  /'; echo
case "$GUI" in
    kdialog) kdialog --title "Vidro $VERSION" --msgbox "$(printf '%b\n\n%b' "$SUMMARY" "$TIPS")" 2>/dev/null ;;
    zenity) zenity --info --title "Vidro $VERSION" --width 520 --text "$(printf '%b\n\n%b' "$SUMMARY" "$TIPS")" 2>/dev/null ;;
esac
exit 0
