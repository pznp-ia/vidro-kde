// Preview: the real folder icons (re-read from the theme after every change)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    Backdrop { anchors.fill: parent; app: r.app }
    Rectangle { anchors.fill: parent; anchors.margins: 8; radius: 10; color: Qt.alpha("#202227", 0.86); border.color: Qt.rgba(1, 1, 1, 0.10) }
    Row {
        anchors.centerIn: parent; spacing: 22
        Repeater {
            model: [["folder", "Pasta"], ["folder-documents", "Documentos"], ["folder-download", "Downloads"], ["folder-pictures", "Imagens"], ["folder-music", "Músicas"]]
            Column {
                spacing: 6
                Image {
                    width: 72; height: 72; sourceSize: Qt.size(144, 144); cache: false; asynchronous: true
                    source: (r.app && r.app.home) ? "file://" + r.app.home + "/.local/share/icons/Vidro/scalable/places/" + modelData[0] + ".svg?v=" + r.app.version : ""
                }
                Text { text: modelData[1]; color: "#eceef3"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
}
