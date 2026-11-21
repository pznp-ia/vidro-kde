// Exemplo: os ícones de pasta de verdade (relidos do tema depois de cada mudança)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    Rectangle { anchors.fill: parent; color: "#202227" }
    Row {
        anchors.centerIn: parent; spacing: 22
        Repeater {
            model: [["folder", "Pasta"], ["folder-documents", "Documentos"], ["folder-download", "Downloads"], ["folder-pictures", "Imagens"], ["folder-music", "Músicas"]]
            Column {
                spacing: 6
                Image {
                    width: 72; height: 72; sourceSize: Qt.size(144, 144); cache: false; asynchronous: true
                    source: (r.app && r.app.home) ? "file://" + r.app.home + "/.local/share/icons/Vidro/scalable/places/" + modelData[0] + ".svg?v=" + r.app.versao : ""
                }
                Text { text: modelData[1]; color: "#eceef3"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
}
