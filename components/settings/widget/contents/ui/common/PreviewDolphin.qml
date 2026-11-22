// Preview: Dolphin (sidebar, separator lines, file area background)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property bool active: U.b(app, "Dolphin", "enabled", true)
    readonly property real lines: active ? U.n(app, "Dolphin", "separators", 0) / 100 : 1
    readonly property real gap: active ? U.n(app, "Dolphin", "spacing", 6) : 1
    readonly property color win: "#202326"
    readonly property color base: (active && U.v(app, "Dolphin", "background", "interface") === "custom") ? U.color(U.v(app, "Dolphin", "background_color", "#25282d")) : win
    readonly property color area: (active && (U.b(app, "Dolphin", "unify", true) || U.v(app, "Dolphin", "background", "interface") === "custom"))
        ? U.mix(base, "#141518", U.n(app, "Dolphin", "darken", 0) / 100) : "#141518"
    Rectangle { anchors.fill: parent; color: r.win }
    Rectangle { width: parent.width; height: 34; color: r.win
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.18 * r.lines) }
        Rectangle { x: parent.width * 0.3; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.5; height: 20; radius: 6; color: Qt.rgba(0, 0, 0, 0.25) } }
    Column { x: 10; y: 46; spacing: 9
        Repeater { model: ["Início", "Documentos", "Downloads", "Imagens", "Lixeira"]
            Rectangle { width: 120; height: 22; radius: 6; color: index === 0 ? "#3daee9" : "transparent"
                Text { x: 8; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: "#eceef3"; font.pixelSize: 12 } } } }
    Rectangle { x: 140; y: 34; width: 1; height: parent.height - 34; color: Qt.rgba(1, 1, 1, 0.18 * r.lines) }
    Rectangle {
        x: 141 + r.gap; y: 34 + r.gap; width: parent.width - 141 - 2 * r.gap; height: parent.height - 34 - 2 * r.gap
        radius: r.gap > 2 ? 8 : 0; color: r.area
        Behavior on color { ColorAnimation { duration: 150 } }
        Grid { x: 16; y: 14; columns: 4; spacing: 18
            Repeater { model: 8; Column { spacing: 4
                Image { width: 40; height: 40; sourceSize: Qt.size(80, 80); cache: false
                    source: (r.app && r.app.home) ? "file://" + r.app.home + "/.local/share/icons/Vidro/scalable/places/folder.svg?v=" + r.app.version : "" }
                Rectangle { width: 40; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.3) } } } }
    }
}
