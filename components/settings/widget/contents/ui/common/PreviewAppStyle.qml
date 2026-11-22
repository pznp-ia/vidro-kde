// Preview: buttons, text field, check boxes, tabs and a list drawn with the chosen app style
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property real radius: U.n(app, "AppStyle", "radius", 8)
    readonly property string buttons: U.v(app, "AppStyle", "buttons", "glass")
    readonly property string fields: U.v(app, "AppStyle", "fields", "glass")
    readonly property bool circle: U.v(app, "AppStyle", "checks", "rounded") === "circle"
    readonly property string tabs: U.v(app, "AppStyle", "tabs", "segmented")
    readonly property bool pill: U.v(app, "AppStyle", "selection", "pill") === "pill"
    readonly property real pad: ({ compact: 4, normal: 7, comfortable: 11 })[U.v(app, "AppStyle", "density", "normal")] || 7
    readonly property real border: U.n(app, "AppStyle", "button_border", 10) / 100
    readonly property color accent: U.v(app, "AppStyle", "accent_mode", "theme") === "custom" ? U.color(U.v(app, "AppStyle", "accent_color", "#5b9cf5")) : Kirigami.Theme.highlightColor
    function glass(a) { return Qt.rgba(1, 1, 1, a) }
    Rectangle { anchors.fill: parent; color: "#1e2025" }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 16; spacing: 12
        Row {   // tabs
            spacing: r.tabs === "segmented" ? 0 : 6
            Repeater {
                model: ["Arquivos", "Lista", "Outra aba"]
                Rectangle {
                    readonly property bool on: index === 0
                    width: 92; height: 26 + r.pad / 2
                    radius: r.tabs === "pill" ? height / 2 : r.tabs === "segmented" ? (index === 0 || index === 2 ? r.radius : 0) : 0
                    color: r.tabs === "pill" ? (on ? Qt.rgba(r.accent.r, r.accent.g, r.accent.b, 0.22) : "transparent")
                         : r.tabs === "underline" ? "transparent" : (on ? "#2a2d33" : r.glass(0.06))
                    Rectangle { visible: r.tabs === "underline" && parent.on; anchors.bottom: parent.bottom; width: parent.width; height: 2; color: r.accent }
                    Text { anchors.centerIn: parent; text: modelData; color: parent.on ? "white" : Qt.rgba(1, 1, 1, 0.65); font.pixelSize: 12 }
                }
            }
        }
        RowLayout {   // buttons + field
            spacing: 10
            Repeater {
                model: ["Botão", "Padrão"]
                Rectangle {
                    implicitWidth: 86; implicitHeight: 24 + r.pad
                    radius: r.radius
                    color: r.buttons === "filled" ? r.accent : r.buttons === "glass" ? r.glass(0.06) : "transparent"
                    border.width: 1
                    border.color: r.buttons === "outline" ? r.glass(Math.max(r.border, 0.22)) : r.buttons === "glass" ? r.glass(r.border) : "transparent"
                    Text { anchors.centerIn: parent; text: modelData; color: "white"; font.pixelSize: 12 }
                }
            }
            Rectangle {
                implicitWidth: 150; implicitHeight: 24 + r.pad
                radius: r.fields === "flat" ? 0 : r.radius
                color: r.fields === "flat" ? "transparent" : r.glass(r.fields === "filled" ? 0.10 : 0.04)
                border.width: r.fields === "flat" ? 0 : 1; border.color: r.glass(r.border)
                Rectangle { visible: r.fields === "flat"; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: r.glass(0.25) }
                Text { x: 8; anchors.verticalCenter: parent.verticalCenter; text: "Pesquisar…"; color: Qt.rgba(1, 1, 1, 0.45); font.pixelSize: 12 }
            }
        }
        RowLayout {   // checks + radios
            spacing: 14
            Repeater {
                model: [[true, false], [false, false], [true, true], [false, true]]
                Row {
                    spacing: 6
                    Rectangle {
                        width: 16; height: 16; anchors.verticalCenter: parent.verticalCenter
                        radius: modelData[1] || r.circle ? 8 : Math.max(2, r.radius / 2)
                        color: modelData[0] ? r.accent : r.glass(0.06); border.color: modelData[0] ? r.accent : r.glass(0.25)
                        Text { visible: modelData[0] && !modelData[1]; anchors.centerIn: parent; text: "✓"; color: "white"; font.pixelSize: 11 }
                        Rectangle { visible: modelData[0] && modelData[1]; anchors.centerIn: parent; width: 6; height: 6; radius: 3; color: "white" }
                    }
                    Text { text: modelData[1] ? "Rádio" : "Opção"; color: "white"; font.pixelSize: 12 }
                }
            }
        }
        Column {   // list with selection
            Layout.fillWidth: true
            Repeater {
                model: ["Documentos", "Projetos", "Imagens"]
                Rectangle {
                    width: parent.width - (r.pill ? 8 : 0); x: r.pill ? 4 : 0; height: 22
                    radius: r.pill ? Math.max(4, r.radius - 2) : 0
                    color: index === 1 ? Qt.rgba(r.accent.r, r.accent.g, r.accent.b, 0.85) : "transparent"
                    Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData; color: "white"; font.pixelSize: 12 }
                }
            }
        }
    }
}
