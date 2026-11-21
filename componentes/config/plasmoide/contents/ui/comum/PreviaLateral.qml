// Exemplo: lateral do Dolphin com os ícones pequenos de verdade
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property string tam: U.v(app, "Icones", "lado_tamanho", "auto")
    readonly property real px: tam === "auto" ? 22 : Number(tam)
    Fundo { anchors.fill: parent; app: r.app }
    Rectangle {
        anchors.centerIn: parent; width: parent.width * 0.62; height: parent.height * 0.84; radius: 10
        color: Qt.rgba(0.12, 0.13, 0.15, 0.94); border.color: Qt.rgba(1, 1, 1, 0.08)
        Rectangle { id: lat; width: parent.width * 0.38; height: parent.height; radius: 10; color: Qt.rgba(1, 1, 1, 0.03)
            Column {
                x: 12; y: 12; spacing: Math.max(2, r.px * 0.25)
                Text { text: "Locais"; color: Qt.rgba(1, 1, 1, 0.45); font.pixelSize: 11 }
                Repeater {
                    model: [["user-home", "Início"], ["user-desktop", "Área de trabalho"], ["folder-documents", "Documentos"], ["folder-download", "Downloads"],
                            ["folder-music", "Música"], ["folder-pictures", "Imagens"], ["folder-videos", "Vídeos"], ["user-trash", "Lixeira"]]
                    Row {
                        spacing: 8
                        Image {
                            width: r.px; height: r.px; sourceSize: Qt.size(r.px * 2, r.px * 2); cache: false; asynchronous: true
                            source: (r.app && r.app.home) ? "file://" + r.app.home + "/.local/share/icons/Vidro/22/places/" + modelData[0] + ".svg?v=" + r.app.versao : ""
                        }
                        Text { text: modelData[1]; color: "#eceef3"; font.pixelSize: Math.max(11, r.px * 0.55); anchors.verticalCenter: parent.verticalCenter }
                    }
                }
            }
        }
        Grid { x: lat.width + 20; y: 20; columns: 3; spacing: 16
            Repeater { model: 6; Rectangle { width: 40; height: 32; radius: 6; color: Qt.rgba(1, 1, 1, 0.08) } } }
    }
}
