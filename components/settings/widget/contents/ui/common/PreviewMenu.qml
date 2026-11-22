// Preview: right-click menu (corners, background, lines, item highlight)
import QtQuick
import org.kde.kirigami as Kirigami
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property bool active: U.b(app, "Menus", "enabled", true)
    readonly property real radius: active ? U.n(app, "Menus", "radius", 12) : 8
    readonly property real gap: active ? U.n(app, "Menus", "padding", 6) : 4
    readonly property real op: active ? U.n(app, "Menus", "opacity", 92) / 100 : 1
    readonly property real sep: active ? U.n(app, "Menus", "separators", 0) / 100 : 0.6
    readonly property real border: active ? U.n(app, "Menus", "border", 14) / 100 : 0.2
    readonly property real forca: active ? U.n(app, "Menus", "intensity", 14) / 100 : 0.3
    readonly property color background: (active && U.v(app, "Menus", "background", "theme") === "custom") ? U.color(U.v(app, "Menus", "background_color", "#1c1e24")) : "#202326"
    readonly property color highlight: {
        const m = U.v(app, "Menus", "highlight", "glass")
        if (!active) { const c = Kirigami.Theme.highlightColor; return Qt.rgba(c.r, c.g, c.b, 0.5) }
        if (m === "accent") { const c = Kirigami.Theme.highlightColor; return Qt.rgba(c.r, c.g, c.b, Math.min(1, forca * 2.2)) }
        if (m === "custom") return U.color(U.v(app, "Menus", "highlight_color", "#8ab4f8"), Math.min(1, forca * 2.2))
        return Qt.rgba(1, 1, 1, forca)
    }
    Backdrop { anchors.fill: parent; app: r.app }
    Rectangle {
        id: menu
        anchors.centerIn: parent; width: 220; height: col.height + 2 * r.gap
        radius: r.radius
        color: Qt.rgba(r.background.r, r.background.g, r.background.b, r.op)
        border.color: Qt.rgba(1, 1, 1, r.border); border.width: 1
        Behavior on radius { NumberAnimation { duration: 120 } }
        Column {
            id: col; x: r.gap; y: r.gap; width: parent.width - 2 * r.gap
            Repeater {
                model: ["Abrir", "Copiar", "Colar", "-", "Renomear…", "-", "Mover para a lixeira"]
                Item {
                    width: col.width; height: modelData === "-" ? 9 : 30
                    Rectangle { visible: modelData === "-"; anchors.centerIn: parent; width: parent.width - 8; height: 1; color: Qt.rgba(1, 1, 1, r.sep * 0.5) }
                    Rectangle { visible: index === 1; anchors.fill: parent; radius: Math.max(2, r.radius - r.gap); color: r.highlight }
                    Text { visible: modelData !== "-"; text: modelData; x: 12; anchors.verticalCenter: parent.verticalCenter; color: "#eceef3"; font.pixelSize: 13 }
                }
            }
        }
    }
}
