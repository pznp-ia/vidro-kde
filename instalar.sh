#!/bin/bash
# Vidro — instalador (só para o seu usuário; não precisa de sudo).
#
#   ./instalar.sh              instala e liga o Vidro
#   ./instalar.sh --sem-ligar  só copia os arquivos (ligue depois com: vidro-tema ligar)
#
# Antes de mudar qualquer configuração, guarda uma cópia em ~/.local/share/vidro/backup-<data>.
# Para desfazer: ./desinstalar.sh
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
C="$AQUI/componentes"
D="${XDG_DATA_HOME:-$HOME/.local/share}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
LIGAR=1
[ "${1:-}" = "--sem-ligar" ] && LIGAR=0

ok()   { printf '  \e[32m✓\e[0m %s\n' "$*"; }
aviso(){ printf '  \e[33m!\e[0m %s\n' "$*"; }
erro() { printf '\e[31mErro:\e[0m %s\n' "$*" >&2; exit 1; }

echo "Vidro — instalação"

# ---------- requisitos ----------
command -v plasmashell >/dev/null || erro "KDE Plasma não encontrado."
command -v kwriteconfig6 >/dev/null || erro "kwriteconfig6 não encontrado (precisa do Plasma 6)."
command -v python3 >/dev/null || erro "python3 é necessário."
PV=$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
case "$PV" in 6.*) ok "Plasma $PV";; *) erro "o Vidro é para o Plasma 6 (encontrado: ${PV:-desconhecido}).";; esac
[ "${XDG_SESSION_TYPE:-}" = wayland ] || aviso "sessão não é Wayland: os efeitos foram testados só no Wayland."
command -v magick >/dev/null || aviso "ImageMagick (magick) não encontrado: cor automática da barra de título e fundo do logout ficam desligados."

# ---------- backup das configurações ----------
B="$D/vidro/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$B"
for f in kdeglobals kwinrc plasmarc kcminputrc ksplashrc kscreenlockerrc; do
    [ -f "$CFG/$f" ] && cp -a "$CFG/$f" "$B/"
done
[ -d "$CFG/kdedefaults" ] && cp -a "$CFG/kdedefaults" "$B/"
echo "$B" > "$D/vidro/ultimo-backup"
ok "backup das configurações em $B"

# ---------- arquivos ----------
copia() { # copia <origem> <destino>  (substitui o destino)
    rm -rf "$2"; mkdir -p "$(dirname "$2")"; cp -a "$1" "$2"
}
copia "$C/aurorae-Vidro"            "$D/aurorae/themes/Vidro"
copia "$C/plasma-style/Vidro"       "$D/plasma/desktoptheme/Vidro"
copia "$C/Vidro.colors"             "$D/color-schemes/Vidro.colors"
copia "$C/icones/Vidro"             "$D/icons/Vidro"
copia "$C/look-and-feel"            "$D/plasma/look-and-feel/org.vidro.desktop"
copia "$C/plasmoide-transparencia"  "$D/plasma/plasmoids/org.vidro.transparencia"
for e in "$C"/efeitos-kwin/vidro_*; do copia "$e" "$D/kwin/effects/$(basename "$e")"; done
ok "decoração de janelas, estilo do Plasma, cores, ícones, tema global, efeitos e widget"

# estilo de apps (Union) — só se o Union estiver instalado
UNION=0
if [ -d /usr/share/union/styles/breeze ] || ls /usr/lib*/qt6/plugins/styles/*union* >/dev/null 2>&1; then
    copia "$C/union/vidro" "$D/union/styles/vidro"; UNION=1
    ok "estilo de apps Union \"vidro\""
else
    aviso "Union (plasma-union) não instalado: os apps ficam com o estilo atual."
fi

# ícones: espelha um tema base para os ícones que o Vidro não redesenha
BASE_ICONES=""
for t in "$D/icons/Tela-red-dark" /usr/share/icons/Tela-red-dark "$D/icons/Tela-dark" /usr/share/icons/Tela-dark /usr/share/icons/breeze-dark; do
    [ -f "$t/index.theme" ] && { BASE_ICONES="$t"; break; }
done
if [ -n "$BASE_ICONES" ]; then
    nome=$(basename "$BASE_ICONES")
    herda="$nome,breeze-dark,hicolor"; [ "$nome" = breeze-dark ] && herda="breeze-dark,hicolor"
    sed -i "s|^Inherits=.*|Inherits=$herda|" "$D/icons/Vidro/index.theme"
    python3 -I "$D/icons/Vidro/fonte/ligar-tela.py" "$D/icons/Vidro" "$BASE_ICONES" >/dev/null
    ok "ícones dos apps vêm de $nome"
fi

# scripts
mkdir -p "$BIN"
for s in vidro-tema vidro-transparencia vidro-cor-titulo; do install -m 755 "$AQUI/bin/$s" "$BIN/$s"; done
mkdir -p "$CFG/systemd/user"
cp "$AQUI/systemd/vidro-cor-titulo.path" "$AQUI/systemd/vidro-cor-titulo.service" "$CFG/systemd/user/"
if command -v magick >/dev/null; then
    systemctl --user daemon-reload
    systemctl --user enable --now vidro-cor-titulo.path >/dev/null 2>&1 || true
fi
ok "comandos vidro-tema, vidro-transparencia, vidro-cor-titulo"

# ---------- tela de bloqueio e logout (pacote de shell) ----------
# Os arquivos QML são da versão 6.8 do Plasma; em outra versão podem não abrir —
# por segurança (é a tela que desbloqueia o PC) só instala no Plasma 6.8.
SHELL_SIS=/usr/share/plasma/shells/org.kde.plasma.desktop
if [[ "$PV" == 6.8* ]] && [ -d "$SHELL_SIS/contents" ]; then
    S="$D/plasma/shells/org.vidro.desktop"
    rm -rf "$S"; mkdir -p "$S/contents"
    cp -a "$C/shell/metadata.json" "$S/"
    cp -a "$C/shell/contents/lockscreen" "$C/shell/contents/logout" "$S/contents/"
    for x in "$SHELL_SIS"/contents/*; do
        n=$(basename "$x"); [ -e "$S/contents/$n" ] || ln -s "$x" "$S/contents/$n"
    done
    mkdir -p "$CFG/systemd/user/plasma-kwin_wayland.service.d" "$D/dbus-1/services"
    printf '[Service]\n# Vidro: tela de bloqueio do pacote org.vidro.desktop\nEnvironment=PLASMA_DEFAULT_SHELL=org.vidro.desktop\n' \
        > "$CFG/systemd/user/plasma-kwin_wayland.service.d/vidro.conf"
    printf '[D-BUS Service]\nName=org.kde.LogoutPrompt\nExec=/usr/bin/env PLASMA_DEFAULT_SHELL=org.vidro.desktop /usr/libexec/ksmserver-logout-greeter\n' \
        > "$D/dbus-1/services/org.kde.LogoutPrompt.service"
    [ -x /usr/libexec/ksmserver-logout-greeter ] || aviso "ksmserver-logout-greeter não está em /usr/libexec: ajuste $D/dbus-1/services/org.kde.LogoutPrompt.service"
    ok "tela de bloqueio e de logout Vidro (bloqueio vale a partir do próximo login)"
else
    aviso "tela de bloqueio/logout Vidro pulada (feita para o Plasma 6.8; o seu é $PV)."
fi

# ---------- ligar ----------
if [ "$LIGAR" = 1 ]; then
    UNION_OK=$UNION "$BIN/vidro-tema" ligar || true
    # padrões do Vidro (só se ainda não houver valor)
    [ -n "$(kreadconfig6 --file kwinrc --group Effect-vidro_opacity --key Level)" ] || "$BIN/vidro-transparencia" 50 >/dev/null
fi

echo
echo "Pronto! Dicas:"
echo "  • Adicione o widget \"Transparência das janelas\" ao painel para ajustar a transparência."
echo "  • vidro-tema desligar  → volta ao Breeze Dark;  vidro-tema ligar → volta ao Vidro."
echo "  • Login (SDDM) Vidro:  sudo bash componentes/sddm/instalar-sddm.sh"
echo "  • NotepadK:            bash componentes/notepadk/instalar-notepadk.sh"
echo "  • Para remover tudo:   ./desinstalar.sh"
