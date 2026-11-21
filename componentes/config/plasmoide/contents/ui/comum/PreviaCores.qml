// Exemplo: lista de arquivos com seleção (cor de destaque) e texto (cor da fonte)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property color fundo: "#202326"
    readonly property color destaque: U.v(app, "Cores", "destaque", "tema") === "cor" ? U.cor(U.v(app, "Cores", "cor_destaque", "#3daee9")) : "#3daee9"
    readonly property real forca: U.v(app, "Cores", "destaque", "tema") === "cor" ? Math.max(0.25, U.n(app, "Cores", "forca", 100) / 100) : 1
    readonly property color sel: U.mix(fundo, destaque, forca)
    readonly property bool selClara: (0.299 * sel.r + 0.587 * sel.g + 0.114 * sel.b) > 0.62
    readonly property color fonte: U.v(app, "Cores", "fonte", "tema") === "cor" ? U.cor(U.v(app, "Cores", "cor_fonte", "#fcfcfc")) : "#fcfcfc"
    readonly property color secundaria: U.v(app, "Cores", "fonte", "tema") === "cor" ? U.mix(fonte, fundo, U.n(app, "Cores", "secundario", 41) / 100) : "#a1a9b1"
    Rectangle { anchors.fill: parent; color: r.fundo }
    Column {
        anchors.centerIn: parent; width: parent.width * 0.7; spacing: 4
        Repeater {
            model: [["Documentos", "12 itens"], ["Imagens", "348 itens"], ["Projetos", "3 itens"], ["Vídeos", "27 itens"]]
            Rectangle {
                width: parent.width; height: 34; radius: 8
                color: index === 1 ? r.sel : "transparent"
                border.color: index === 2 ? Qt.rgba(r.destaque.r, r.destaque.g, r.destaque.b, 0.9) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text { x: 14; anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; font.pixelSize: 13
                    color: index === 1 ? (r.selClara ? "#141418" : "#fcfcfc") : r.fonte }
                Text { anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter } text: modelData[1]; font.pixelSize: 12
                    color: index === 1 ? (r.selClara ? "#141418" : "#fcfcfc") : r.secundaria }
            }
        }
        Text { text: "selecionado · com foco · normal"; color: r.secundaria; font.pixelSize: 11 }
    }
}
