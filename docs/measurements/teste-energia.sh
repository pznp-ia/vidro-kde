#!/bin/bash
# Compara consumo: Vidro x configuração de antes do Vidro. Restaura tudo no fim (trap).
S=$(dirname "$0")
R=$S/energia; mkdir -p $R; SNAP=$R/snapshot; mkdir -p $SNAP
for f in kwinrc kdeglobals plasmarc kcminputrc; do cp -a ~/.config/$f $SNAP/; done
TEMA_PLASMA=$(kreadconfig6 --file plasmarc --group Theme --key name)
reconf() { dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure; }
modo_vidro() {
    for f in kwinrc kdeglobals plasmarc kcminputrc; do cp -a $SNAP/$f ~/.config/$f; done
    reconf; plasma-apply-desktoptheme "$TEMA_PLASMA" >/dev/null 2>&1; sleep 3
}
modo_antes() {
    # como era antes do Vidro: efeitos padrão do KWin, decoração ChromeOS-dark, apps em Breeze, Plasma Breeze
    for k in $(sed -n '/^\[Plugins\]/,/^\[/p' $SNAP/kwinrc | grep -o '^[A-Za-z_]*Enabled'); do
        kwriteconfig6 --file kwinrc --group Plugins --key $k --delete; done
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae.v2
    kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme __aurorae__svg__ChromeOS-dark
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
    reconf; plasma-apply-desktoptheme default >/dev/null 2>&1; sleep 3
}
restaurar() { pkill -x vidro-previa; modo_vidro; echo "configurações restauradas"; }
trap restaurar EXIT
abrir() { for i in 1 2 3; do nohup ~/.local/share/vidro/bin/vidro-previa >/dev/null 2>&1 & sleep 0.4; done; sleep 4; }
fechar() { pkill -x vidro-previa; sleep 2; }
for rodada in 1 2; do
    for modo in vidro antes; do
        modo_$modo; abrir
        python3 -I $S/medir.py $modo $((40)) $R/$modo-$rodada-ocioso.json
        python3 -I $S/medir.py $modo $((40)) $R/$modo-$rodada-ativo.json ativo
        fechar
    done
done
