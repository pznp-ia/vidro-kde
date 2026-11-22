// Preview: NotepadK page in focus mode with the chosen font, size and line spacing
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property string theme: U.v(app, "NotepadK", "color_theme", "auto")
    readonly property bool light: /light|day|latte|github light|solarized light/i.test(theme)
    Backdrop { anchors.fill: parent; app: r.app }
    Rectangle {
        anchors.centerIn: parent; width: parent.width * 0.62; height: parent.height * 0.86; radius: 10
        color: r.light ? "#fafafa" : "#1e1f24"; border.color: Qt.rgba(1, 1, 1, 0.08)
        Text {
            anchors.fill: parent; anchors.margins: 20; anchors.topMargin: 14 + U.n(r.app, "NotepadK", "strip_height", 30) / 3
            wrapMode: U.b(r.app, "NotepadK", "word_wrap", true) ? Text.WordWrap : Text.NoWrap
            clip: true
            color: r.light ? "#232629" : "#dcdde0"
            font.family: U.v(r.app, "NotepadK", "font_family", "Noto Sans Mono")
            font.pixelSize: U.n(r.app, "NotepadK", "font_size", 11) * 1.35
            lineHeight: U.n(r.app, "NotepadK", "line_height", 1.2)
            text: "Notas de hoje\n\nNo modo foco a janela vira só a folha: sem barras, sem menus. Ctrl+Shift+Espaço mostra a interface com uma transição suave.\n\n— lista de ideias\n— revisar o texto"
        }
    }
}
