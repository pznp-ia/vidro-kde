// Preview: the real file icons (re-read from the theme after every change)
import QtQuick
Item {
    id: r
    property var app
    Rectangle { anchors.fill: parent; color: "#202227" }
    Row {
        anchors.centerIn: parent; spacing: 18
        Repeater {
            model: [["application-pdf", "relatório.pdf"], ["image-png", "foto.png"], ["application-zip", "backup.zip"],
                    ["text-plain", "notas.txt"], ["audio-mpeg", "música.mp3"], ["application-vnd.oasis.opendocument.spreadsheet", "contas.ods"], ["text-x-python", "script.py"]]
            Column {
                spacing: 6
                Image {
                    width: 64; height: 64; sourceSize: Qt.size(128, 128); cache: false; asynchronous: true
                    source: (r.app && r.app.home) ? "file://" + r.app.home + "/.local/share/icons/Vidro/scalable/mimetypes/" + modelData[0] + ".svg?v=" + r.app.version : ""
                }
                Text { text: modelData[1]; color: "#eceef3"; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }
}
