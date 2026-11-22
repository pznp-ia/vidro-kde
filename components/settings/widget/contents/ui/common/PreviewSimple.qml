// Generic preview: light/dark glass window with an accent color
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    property bool light: false
    property color accent: "#3daee9"
    property real glass: 1
    property real radius: 10
    Backdrop { anchors.fill: parent; app: r.app }
    Rectangle {
        anchors.centerIn: parent; width: parent.width * 0.66; height: parent.height * 0.74; radius: r.radius; clip: true
        color: r.light ? "#eef0f4" : "#1f2125"
        Rectangle { width: parent.width; height: 30; color: r.light ? Qt.rgba(0.97, 0.97, 0.98, 0.55 * r.glass) : Qt.rgba(0.15, 0.16, 0.19, 0.6 * r.glass)
            Row { x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 7
                Repeater { model: ["#ff5f57", "#febc2e", "#28c840"]; Rectangle { width: 12; height: 12; radius: 6; color: modelData } } } }
        Column { x: 18; y: 46; spacing: 10
            Rectangle { width: 120; height: 26; radius: r.radius / 2; color: r.accent }
            Repeater { model: 4; Rectangle { width: 200 - index * 25; height: 8; radius: 4; color: r.light ? "#c3c6ce" : Qt.rgba(1, 1, 1, 0.18) } } }
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 } height: 34; radius: r.radius / 2
            color: r.light ? "#dfe2e8" : "#15161a"
            Row { x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                Repeater { model: 12; Rectangle { width: 18; height: 18; radius: 3; color: index === 4 ? r.accent : (r.light ? "#b8bcc5" : "#2c2f36") } } } }
    }
}
