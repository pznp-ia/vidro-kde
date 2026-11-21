// Exemplo genérico: janela clara/escura de vidro com uma cor de destaque
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    property bool clara: false
    property color destaque: "#3daee9"
    property real vidro: 1
    property real raio: 10
    Fundo { anchors.fill: parent; app: r.app }
    Rectangle {
        anchors.centerIn: parent; width: parent.width * 0.66; height: parent.height * 0.74; radius: r.raio; clip: true
        color: r.clara ? "#eef0f4" : "#1f2125"
        Rectangle { width: parent.width; height: 30; color: r.clara ? Qt.rgba(0.97, 0.97, 0.98, 0.55 * r.vidro) : Qt.rgba(0.15, 0.16, 0.19, 0.6 * r.vidro)
            Row { x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 7
                Repeater { model: ["#ff5f57", "#febc2e", "#28c840"]; Rectangle { width: 12; height: 12; radius: 6; color: modelData } } } }
        Column { x: 18; y: 46; spacing: 10
            Rectangle { width: 120; height: 26; radius: r.raio / 2; color: r.destaque }
            Repeater { model: 4; Rectangle { width: 200 - index * 25; height: 8; radius: 4; color: r.clara ? "#c3c6ce" : Qt.rgba(1, 1, 1, 0.18) } } }
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 } height: 34; radius: r.raio / 2
            color: r.clara ? "#dfe2e8" : "#15161a"
            Row { x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                Repeater { model: 12; Rectangle { width: 18; height: 18; radius: 3; color: index === 4 ? r.destaque : (r.clara ? "#b8bcc5" : "#2c2f36") } } } }
    }
}
