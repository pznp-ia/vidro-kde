// Preview: file list with a selection (accent color) and text (text color)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property color background: "#202326"
    readonly property color accent: U.v(app, "Colors", "accent", "theme") === "custom" ? U.color(U.v(app, "Colors", "accent_color", "#3daee9")) : "#3daee9"
    readonly property real forca: U.v(app, "Colors", "accent", "theme") === "custom" ? Math.max(0.25, U.n(app, "Colors", "strength", 100) / 100) : 1
    readonly property color sel: U.mix(background, accent, forca)
    readonly property bool selClara: (0.299 * sel.r + 0.587 * sel.g + 0.114 * sel.b) > 0.62
    readonly property color fontName: U.v(app, "Colors", "text", "theme") === "custom" ? U.color(U.v(app, "Colors", "text_color", "#fcfcfc")) : "#fcfcfc"
    readonly property color secundaria: U.v(app, "Colors", "text", "theme") === "custom" ? U.mix(fontName, background, U.n(app, "Colors", "secondary", 41) / 100) : "#a1a9b1"
    Backdrop { anchors.fill: parent; app: r.app }
    Rectangle { anchors.fill: parent; color: Qt.alpha(r.background, 0.84) }
    Column {
        anchors.centerIn: parent; width: parent.width * 0.7; spacing: 4
        Repeater {
            model: [["Documentos", "12 itens"], ["Imagens", "348 itens"], ["Projetos", "3 itens"], ["Vídeos", "27 itens"]]
            Rectangle {
                width: parent.width; height: 34; radius: 8
                color: index === 1 ? r.sel : "transparent"
                border.color: index === 2 ? Qt.rgba(r.accent.r, r.accent.g, r.accent.b, 0.9) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; font.pixelSize: 13
                    color: index === 1 ? (r.selClara ? "#141418" : "#fcfcfc") : r.fontName }
                Text { anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter } text: modelData[1]; font.pixelSize: 12
                    color: index === 1 ? (r.selClara ? "#141418" : "#fcfcfc") : r.secundaria }
            }
        }
        Text { text: "selecionado · com foco · normal"; color: r.secundaria; font.pixelSize: 11 }
    }
}
