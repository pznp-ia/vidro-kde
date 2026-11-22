// Preview: window with titlebar (automatic or chosen color) and transparency
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property real t: U.n(app, "Windows", "opacity", 0) / 100
    readonly property color bar: U.v(app, "Windows", "titlebar", "theme") === "custom" ? U.color(U.v(app, "Windows", "titlebar_color", "#262830")) : "#262830"
    readonly property bool light: (0.299 * bar.r + 0.587 * bar.g + 0.114 * bar.b) > 0.6
    Backdrop { anchors.fill: parent; app: r.app }
    Rectangle {
        anchors.centerIn: parent; width: parent.width * 0.62; height: parent.height * 0.72; radius: 12
        color: "transparent"; clip: true
        opacity: 1 - 0.25 * r.t
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Rectangle { id: tb; width: parent.width; height: 30; radius: 12; color: Qt.rgba(r.bar.r, r.bar.g, r.bar.b, 0.62)
            Behavior on color { ColorAnimation { duration: 180 } }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 12; color: parent.color }
            Row { x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 7
                Repeater { model: ["#ff5f57", "#febc2e", "#28c840"]; Rectangle { width: 12; height: 12; radius: 6; color: modelData } } }
            Text { anchors.centerIn: parent; text: "Janela"; color: r.light ? "#1c1c20" : "#ebebf0"; font.pixelSize: 12 }
        }
        Rectangle { anchors.top: tb.bottom; width: parent.width; anchors.bottom: parent.bottom; color: "#202227"
            Column { x: 16; y: 14; spacing: 8
                Repeater { model: 4; Rectangle { width: 120 + index * 30; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.18) } } } }
    }
}
