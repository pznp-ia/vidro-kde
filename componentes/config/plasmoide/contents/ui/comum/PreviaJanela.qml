// Exemplo: janela com barra de título (cor automática ou escolhida) e transparência
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property real t: U.n(app, "Janelas", "transparencia", 0) / 100
    readonly property color barra: U.v(app, "Janelas", "barra", "tema") === "cor" ? U.cor(U.v(app, "Janelas", "cor_barra", "#262830")) : "#262830"
    readonly property bool clara: (0.299 * barra.r + 0.587 * barra.g + 0.114 * barra.b) > 0.6
    Fundo { anchors.fill: parent; app: r.app }
    Rectangle {
        anchors.centerIn: parent; width: parent.width * 0.62; height: parent.height * 0.72; radius: 12
        color: "transparent"; clip: true
        opacity: 1 - 0.25 * r.t
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Rectangle { id: tb; width: parent.width; height: 30; radius: 12; color: Qt.rgba(r.barra.r, r.barra.g, r.barra.b, 0.62)
            Behavior on color { ColorAnimation { duration: 180 } }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 12; color: parent.color }
            Row { x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 7
                Repeater { model: ["#ff5f57", "#febc2e", "#28c840"]; Rectangle { width: 12; height: 12; radius: 6; color: modelData } } }
            Text { anchors.centerIn: parent; text: "Janela"; color: r.clara ? "#1c1c20" : "#ebebf0"; font.pixelSize: 12 }
        }
        Rectangle { anchors.top: tb.bottom; width: parent.width; anchors.bottom: parent.bottom; color: "#202227"
            Column { x: 16; y: 14; spacing: 8
                Repeater { model: 4; Rectangle { width: 120 + index * 30; height: 8; radius: 4; color: Qt.rgba(1, 1, 1, 0.18) } } } }
    }
}
