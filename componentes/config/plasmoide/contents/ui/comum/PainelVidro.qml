// Configurações do Vidro: abas na lateral (uma por arquivo em ../secoes/*.qml) e conteúdo à direita.
// A seção recebe "app" (este painel): app.cfg[Grupo][chave], app.definir(Grupo, chave, valor), app.rodar(cmd),
// app.home (pasta pessoal), app.versao (muda depois de cada aplicação — para recarregar imagens).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: app
    property var cfg: ({})
    property var secoes: []
    property bool pronto: false
    property var pendentes: ({})
    property string home: ""
    property int versao: 0
    property bool mostrarTitulo: true   // compatibilidade
    readonly property string pastaSecoes: Qt.resolvedUrl("../secoes").toString().replace("file://", "")

    function rodar(cmd) { exec.connectSource(cmd) }
    function texto(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function definir(g, k, v) {
        const novo = Object.assign({}, cfg);
        novo[g] = Object.assign({}, cfg[g] || {});
        novo[g][k] = String(v);
        cfg = novo;
        pendentes[g + "\u0001" + k] = String(v);
        gravar.restart();
    }
    function recarregar() { exec.connectSource(cmdJson); exec.connectSource(cmdSecoes); exec.connectSource(cmdHome); }
    readonly property string cmdJson: "$HOME/.local/bin/vidro-config json"
    readonly property string cmdSecoes: "ls " + texto(pastaSecoes) + " #secoes"
    readonly property string cmdHome: "echo $HOME #home"
    property int seq: 0
    property int atual: 0

    Timer {
        id: gravar; interval: 250
        onTriggered: {
            for (const chave in app.pendentes) {
                const p = chave.split("\u0001");
                app.seq += 1;
                app.rodar("$HOME/.local/bin/vidro-config set " + app.texto(p[0]) + " " + app.texto(p[1]) + " " + app.texto(app.pendentes[chave]) + " --aplicar #aplicar" + app.seq);
            }
            app.pendentes = ({});
        }
    }
    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            if (source === app.cmdJson) {
                try { app.cfg = JSON.parse(data["stdout"]); } catch (e) { app.cfg = ({}); }
                app.pronto = true;
            } else if (source === app.cmdSecoes) {
                app.secoes = data["stdout"].split("\n").filter(s => s.endsWith(".qml"));
            } else if (source === app.cmdHome) {
                app.home = data["stdout"].trim();
            } else if (source.indexOf("#aplicar") >= 0) {
                app.versao += 1;
            }
            disconnectSource(source);
        }
    }
    Component.onCompleted: recarregar()

    RowLayout {
        anchors.fill: parent
        spacing: 0
        // ---- abas ----
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: 2
                Kirigami.Heading { text: "Vidro"; level: 2; Layout.margins: Kirigami.Units.largeSpacing }
                Repeater {
                    model: secoesRep.count
                    delegate: QQC2.ItemDelegate {
                        Layout.fillWidth: true
                        readonly property var sec: secoesRep.itemAt(index) ? secoesRep.itemAt(index).item : null
                        text: sec ? sec.titulo : ""
                        icon.name: sec ? sec.icone : ""
                        highlighted: app.atual === index
                        visible: !!sec
                        onClicked: app.atual = index
                    }
                }
                Item { Layout.fillHeight: true }
                QQC2.Button {
                    Layout.fillWidth: true
                    text: "Recarregar Plasma"
                    icon.name: "view-refresh"
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "Reinicia o painel/área de trabalho e recarrega o KWin para aplicar tudo (a tela pisca por 2 segundos)."
                    onClicked: app.rodar("(dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure; systemctl --user restart plasma-plasmashell.service) >/dev/null 2>&1 & #recarregar" + Date.now())
                }
                QQC2.Label {
                    text: "Barra, menus e Dolphin: apps já abertos mudam ao reabrir."
                    wrapMode: Text.WordWrap; opacity: 0.55; font: Kirigami.Theme.smallFont
                    Layout.fillWidth: true; Layout.margins: Kirigami.Units.smallSpacing
                }
            }
        }
        Kirigami.Separator { Layout.fillHeight: true; opacity: 0.3 }
        // ---- conteúdo ----
        QQC2.ScrollView {
            id: rolagem
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ColumnLayout {
                width: rolagem.availableWidth
                Repeater {
                    id: secoesRep
                    model: app.pronto ? app.secoes : []
                    delegate: Loader {
                        Layout.fillWidth: true
                        visible: app.atual === index
                        source: Qt.resolvedUrl("../secoes/" + modelData)
                        onLoaded: item.app = app
                    }
                }
                Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
            }
        }
    }
}
