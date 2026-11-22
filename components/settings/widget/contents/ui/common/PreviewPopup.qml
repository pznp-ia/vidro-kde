// Preview: panel popup / launcher (corners, glass, header lines, shadow)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property bool active: U.b(app, "Popups", "enabled", true)
    readonly property real radius: active ? U.n(app, "Popups", "radius", 14) : 6
    readonly property real op: active ? U.n(app, "Popups", "opacity", 80) / 100 : 0.85
    readonly property real lines: active ? U.n(app, "Popups", "lines", 0) / 100 : 1
    readonly property real cab: active ? U.n(app, "Popups", "header", 0) / 100 : 1
    readonly property real border: active ? U.n(app, "Popups", "border", 10) / 100 : 0.2
    readonly property real shadow: active ? U.n(app, "Popups", "shadow", 55) / 100 : 0.5
    readonly property real size: active ? U.n(app, "Popups", "shadow_size", 18) : 16
    readonly property color glass: (active && U.v(app, "Popups", "background", "theme") === "custom") ? U.color(U.v(app, "Popups", "glass_color", "#1c1e24")) : "#202326"
    Backdrop { anchors.fill: parent; app: r.app }
    Repeater { // sombra em camadas
        model: 6
        Rectangle {
            anchors.centerIn: pop; anchors.verticalCenterOffset: r.size * 0.25
            width: pop.width + (index + 1) * r.size / 3; height: pop.height + (index + 1) * r.size / 3
            radius: r.radius + (index + 1) * r.size / 6
            color: Qt.rgba(0, 0, 0, r.shadow * 0.09 * (6 - index) / 6)
        }
    }
    Rectangle {
        id: pop
        anchors.centerIn: parent; width: parent.width * 0.5; height: parent.height * 0.74
        radius: r.radius; clip: true
        color: Qt.rgba(r.glass.r, r.glass.g, r.glass.b, r.op)
        border.color: Qt.rgba(1, 1, 1, r.border)
        Rectangle { width: parent.width; height: 34; color: Qt.rgba(1, 1, 1, 0.05 * r.cab)
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.25 * r.lines) }
            Rectangle { x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 20; height: 20; radius: 10; color: Qt.rgba(1, 1, 1, 0.08) } }
        Grid { x: 16; y: 48; columns: 4; spacing: 14
            Repeater { model: 8; Rectangle { width: 30; height: 30; radius: 8; color: ["#5b8def", "#e5534b", "#3fb950", "#d29922", "#bc8cff", "#58a6ff", "#f0883e", "#8b949e"][index]; opacity: 0.85 } } }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 30; color: Qt.rgba(1, 1, 1, 0.05 * r.cab)
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.25 * r.lines) } }
    }
}
