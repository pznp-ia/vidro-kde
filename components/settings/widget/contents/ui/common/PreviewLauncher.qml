// Preview: launcher (type, grid/list, compact, sidebar on the right, footer)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property string kind: U.v(app, "Launcher", "type", "kickoff")
    readonly property bool favoritesList: U.v(app, "Launcher", "favorites", "0") === "1"
    readonly property bool compact: U.b(app, "Launcher", "compact", false)
    readonly property bool onRight: U.b(app, "Launcher", "sidebar_right", false)
    readonly property int footer: Number(U.v(app, "Launcher", "footer", "0"))
    readonly property bool captions: U.b(app, "Launcher", "captions", true)
    readonly property real radius: U.b(app, "Popups", "enabled", true) ? U.n(app, "Popups", "radius", 14) : 6
    readonly property real op: U.b(app, "Popups", "enabled", true) ? U.n(app, "Popups", "opacity", 80) / 100 : 0.85
    readonly property var swatches: ["#5b8def", "#e5534b", "#3fb950", "#d29922", "#bc8cff", "#58a6ff", "#f0883e", "#8b949e"]
    Backdrop { anchors.fill: parent; app: r.app }
    // taskbar
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 22; color: Qt.rgba(0.1, 0.11, 0.13, 0.8)
        Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: "white"; opacity: 0.9 } }

    // ---- Kickoff ----
    Rectangle {
        visible: r.kind === "kickoff"
        x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        width: parent.width * 0.62; height: parent.height - 40
        radius: r.radius; color: Qt.rgba(0.12, 0.13, 0.15, r.op); border.color: Qt.rgba(1, 1, 1, 0.1)
        Rectangle { x: 10; y: 8; width: parent.width - 20; height: 18; radius: 9; color: Qt.rgba(1, 1, 1, 0.08) }
        // category sidebar
        Column {
            x: r.onRight ? parent.width - width - 10 : 10; y: 36; spacing: r.compact ? 4 : 8; width: parent.width * 0.3
            Repeater { model: r.compact ? 9 : 6; Rectangle { width: parent.width * (0.6 + (index % 3) * 0.12); height: r.compact ? 6 : 9; radius: 3; color: index === 0 ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.22) } }
        }
        // favoritos
        Item {
            x: r.onRight ? 10 : parent.width * 0.36; y: 36; width: parent.width * 0.6; height: parent.height - 72
            Grid { visible: !r.favoritesList; columns: 3; spacing: 12
                Repeater { model: 6; Rectangle { width: 26; height: 26; radius: 7; color: r.swatches[index]; opacity: 0.85 } } }
            Column { visible: r.favoritesList; spacing: r.compact ? 5 : 9
                Repeater { model: r.compact ? 7 : 5; Row { spacing: 6
                    Rectangle { width: r.compact ? 10 : 14; height: width; radius: 4; color: r.swatches[index] }
                    Rectangle { width: 70 + (index % 3) * 14; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.3); anchors.verticalCenter: parent.verticalCenter } } } }
        }
        // footer
        Row {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.right: parent.right; anchors.rightMargin: 10; spacing: 8
            Repeater { model: r.footer === 3 ? 6 : 3
                Row { spacing: 3
                    Rectangle { width: 10; height: 10; radius: 5; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.7) }
                    Rectangle { visible: r.captions; width: 24; height: 5; radius: 2; color: Qt.rgba(1, 1, 1, 0.35); anchors.verticalCenter: parent.verticalCenter } } }
        }
    }
    // ---- classic menu ----
    Rectangle {
        visible: r.kind === "classic"
        x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        width: parent.width * 0.3; height: parent.height - 40
        radius: r.radius; color: Qt.rgba(0.12, 0.13, 0.15, r.op); border.color: Qt.rgba(1, 1, 1, 0.1)
        Column { x: 12; y: 12; spacing: 9
            Repeater { model: 10; Row { spacing: 6
                Rectangle { width: 10; height: 10; radius: 3; color: r.swatches[index % 8] }
                Rectangle { width: 60 + (index % 4) * 10; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.3); anchors.verticalCenter: parent.verticalCenter } } } }
        Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 8; x: 10; width: parent.width - 20; height: 16; radius: 8; color: Qt.rgba(1, 1, 1, 0.08) }
    }
    // ---- tela cheia ----
    Rectangle {
        visible: r.kind === "fullscreen"
        anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.6)
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 14; width: 160; height: 16; radius: 8; color: Qt.rgba(1, 1, 1, 0.12) }
        Grid { anchors.centerIn: parent; columns: 7; spacing: 16
            Repeater { model: 21; Rectangle { width: 24; height: 24; radius: 7; color: r.swatches[index % 8]; opacity: 0.85 } } }
    }
}
