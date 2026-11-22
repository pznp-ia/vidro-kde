// Preview: titlebar with the buttons (side, order, style, size, spacing, inactive)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property string styleName: U.v(app, "Buttons", "style", "traffic")
    readonly property bool onRight: U.v(app, "Buttons", "side", "left") === "right"
    readonly property bool windows: U.v(app, "Buttons", "order", "macos") === "windows"
    readonly property bool menu: U.b(app, "Buttons", "menu", false)
    readonly property real radius: U.n(app, "Buttons", "size", 6.5) * 1.5
    readonly property real gap: U.n(app, "Buttons", "spacing", 2) * 1.5 + 6
    readonly property bool inactiveColor: U.v(app, "Buttons", "inactive", "gray") === "color"
    readonly property string single: U.v(app, "Buttons", "color_mode", "traffic") === "single" ? U.v(app, "Buttons", "single_color", "#8ab4f8") : ""
    readonly property var order: windows ? ["min", "max", "close"] : ["close", "min", "max"]
    readonly property bool custom: U.v(app, "Buttons", "color_mode", "traffic") === "custom"
    readonly property var swatches: ({ close: custom ? U.v(app, "Buttons", "close_color", "#ff5f57") : "#ff5f57",
                                       min: custom ? U.v(app, "Buttons", "minimize_color", "#febc2e") : "#febc2e",
                                       max: custom ? U.v(app, "Buttons", "maximize_color", "#28c840") : "#28c840" })
    Backdrop { anchors.fill: parent; app: r.app }
    component WindowButton: Item {
        id: b
        property string kind
        property bool isActive: true
        property bool hover: false
        width: r.radius * 2 + 4; height: width
        readonly property color color: r.single !== "" ? r.single : r.swatches[kind]
        readonly property bool gray: !isActive && !r.inactiveColor
        readonly property bool simbolo: hover || r.styleName === "symbols" || r.styleName === "graphite" || r.styleName === "icons"
        Rectangle {
            anchors.centerIn: parent; width: r.radius * 2; height: width
            radius: r.styleName === "square" ? width * 0.19 : width / 2
            visible: r.styleName !== "icons" || b.hover
            color: r.styleName === "outline" && !b.hover ? "transparent"
                 : r.styleName === "icons" ? (b.kind === "close" ? b.color : Qt.rgba(1, 1, 1, 0.14))
                 : (r.styleName === "graphite" && !b.hover) ? Qt.rgba(1, 1, 1, b.gray ? 0.12 : 0.28)
                 : b.gray ? Qt.rgba(1, 1, 1, 0.16) : b.color
            border.width: r.styleName === "outline" && !b.hover ? 2 : 0.6
            border.color: r.styleName === "outline" ? (b.gray ? Qt.rgba(1, 1, 1, 0.45) : b.color) : Qt.rgba(0, 0, 0, 0.3)
        }
        Text {
            anchors.centerIn: parent
            visible: b.simbolo && !(b.gray && r.styleName === "traffic")
            text: b.kind === "close" ? "✕" : b.kind === "min" ? "–" : (r.styleName === "icons" ? "□" : "⤢")
            font.pixelSize: r.radius * 1.2; font.bold: true
            color: (r.styleName === "graphite" && !b.hover) || r.styleName === "icons" ? (b.hover && b.kind === "close" ? "white" : Qt.rgba(1, 1, 1, b.gray ? 0.4 : 0.85)) : Qt.rgba(0, 0, 0, 0.6)
        }
    }
    component MockWindow: Rectangle {
        id: j
        property bool isActive: true
        property string title
        width: r.width * 0.42; height: r.height * 0.62
        radius: 10; color: Qt.rgba(0.13, 0.14, 0.16, 0.92); border.color: Qt.rgba(1, 1, 1, 0.08)
        Rectangle { width: parent.width; height: 34; radius: 10; color: Qt.rgba(1, 1, 1, j.isActive ? 0.06 : 0.03)
            Text { anchors.centerIn: parent; text: j.title; color: Qt.rgba(1, 1, 1, j.isActive ? 0.85 : 0.4); font.pixelSize: 12 }
            Row { spacing: r.gap; anchors.verticalCenter: parent.verticalCenter
                x: r.onRight ? parent.width - width - 12 : 12
                Repeater { model: r.order; WindowButton { kind: modelData; isActive: j.isActive; hover: j.isActive && index === (r.windows ? 2 : 0) && r.styleName !== "traffic" } } }
            Text { visible: r.menu; text: "☰"; color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter
                x: r.onRight ? 12 : parent.width - width - 12 }
        }
        Column { x: 16; y: 50; spacing: 8; Repeater { model: 4; Rectangle { width: j.width * (0.7 - index * 0.1); height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.15) } } }
    }
    MockWindow { x: r.width * 0.06; y: r.height * 0.14; isActive: false; title: "Janela inativa" }
    MockWindow { x: r.width * 0.5; y: r.height * 0.22; isActive: true; title: "Janela ativa" }
}
