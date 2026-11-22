// Preview: text area with the scrollbar (normal and under the mouse)
import QtQuick
import org.kde.kirigami as Kirigami
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property bool active: U.b(app, "Scrollbar", "enabled", true)
    readonly property string mode: U.v(app, "Scrollbar", "mode", "glass")
    readonly property real w: active ? U.n(app, "Scrollbar", "width", 6) : 10
    readonly property real op: active ? U.n(app, "Scrollbar", "opacity", 45) / 100 : 0.5
    readonly property real hi: active ? U.n(app, "Scrollbar", "highlight", 80) / 100 : 0.9
    readonly property real radius: active ? w / 2 * U.n(app, "Scrollbar", "roundness", 100) / 100 : 3
    readonly property bool trilho: U.b(app, "Scrollbar", "track", false)
    readonly property bool sobre: active && U.b(app, "Scrollbar", "overlay", true)
    function corAlca(a) {
        if (!active) return Qt.rgba(0.55, 0.57, 0.62, 1)
        if (mode === "thin-neon") { const c = Kirigami.Theme.highlightColor; return Qt.rgba(c.r, c.g, c.b, a) }
        if (mode === "color") return U.color(U.v(app, "Scrollbar", "color", "#8ab4f8"), a)
        return Qt.rgba(0.92, 0.93, 0.96, a * 0.55)
    }
    Rectangle { anchors.fill: parent; color: "#1b1c20" }
    Repeater {
        model: 2
        Item {
            x: 14 + index * (r.width / 2); y: 14; width: r.width / 2 - 28; height: r.height - 28
            Rectangle { anchors.fill: parent; color: "#232529"; radius: 8 }
            Column { x: 12; y: 12; spacing: 9; width: parent.width - (r.sobre ? 12 : r.w + 18)
                Repeater { model: 9; Rectangle { width: parent.width * (0.55 + 0.4 * ((index * 37) % 10) / 10); height: 7; radius: 3.5; color: Qt.rgba(1, 1, 1, 0.16) } } }
            Rectangle { // trilho / faixa
                visible: !r.sobre || r.trilho
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom; margins: 3 }
                width: r.w + 6; radius: 6
                color: r.trilho ? Qt.rgba(1, 1, 1, 0.05) : "#26282d"
            }
            Rectangle { // handle
                anchors.right: parent.right; anchors.rightMargin: 6
                y: index === 0 ? 14 : 60; width: r.w; height: parent.height * 0.32; radius: r.radius
                color: r.corAlca(index === 0 ? r.op : Math.max(r.op, r.hi))
                Behavior on width { NumberAnimation { duration: 120 } }
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            Text { anchors { bottom: parent.bottom; left: parent.left; margins: 8 } text: index === 0 ? "parada" : "sob o mouse"; color: Qt.rgba(1, 1, 1, 0.45); font.pixelSize: 11 }
        }
    }
}
