// Preview: NotepadK page in focus mode over the wallpaper — font, size, spacing, margins,
// centered column, current line, word counter, window opacity; click it to see the transition.
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property string theme: U.v(app, "NotepadK", "color_theme", "auto")
    readonly property bool light: /light|day|latte|github light|solarized light/i.test(theme)
    readonly property color bg: light ? "#fafafa" : "#1e1f24"
    readonly property color fg: light ? "#232629" : "#dcdde0"
    readonly property real fontPx: U.n(app, "NotepadK", "font_size", 11) * 1.35
    readonly property real scaleX: page.width / 900          // preview is smaller than a real window
    readonly property int cols: U.n(app, "NotepadK", "column_chars", 0)
    readonly property string sample: "Notas de hoje\n\nNo modo foco a janela vira só a folha: sem barras, sem menus. Ctrl+Shift+Espaço mostra a interface com uma transição suave.\n\n— lista de ideias\n— revisar o texto"
    property bool full: false

    Backdrop { anchors.fill: parent; app: r.app }
    Rectangle {
        id: page
        anchors.centerIn: parent; width: parent.width * 0.72; height: parent.height * 0.86; radius: 10
        color: r.bg; border.color: Qt.rgba(1, 1, 1, 0.08)
        opacity: U.n(r.app, "NotepadK", "window_opacity", 100) / 100
        clip: true

        // titlebar + toolbar of the full interface
        Rectangle {
            id: chrome
            width: parent.width; height: 34; color: Qt.darker(r.bg, r.light ? 1.06 : 1.25)
            opacity: r.full ? 1 : (U.b(r.app, "NotepadK", "hide_titlebar", true) ? 0 : 1)
            Row { anchors.verticalCenter: parent.verticalCenter; x: 12; spacing: 14
                Repeater { model: ["Arquivo", "Editar", "Exibir", "Ferramentas"]; Text { text: modelData; color: r.fg; opacity: r.full ? 0.75 : 0; font.pixelSize: 11 } } }
            Text { anchors.centerIn: parent; text: "notas.txt — NotepadK"; color: r.fg; opacity: r.full ? 0 : 0.55; font.pixelSize: 11 }
        }

        Text {
            id: body
            readonly property real side: Math.max(U.n(r.app, "NotepadK", "margin", 24) * r.scaleX + 8,
                r.cols > 0 ? (page.width - r.cols * r.fontPx * 0.6 * r.scaleX) / 2 : 0)
            x: side
            y: (chrome.opacity > 0 ? chrome.height : U.n(r.app, "NotepadK", "strip_height", 30) * r.scaleX) + U.n(r.app, "NotepadK", "margin_top", 8) * r.scaleX + 6
            width: page.width - side * 2
            height: page.height - y - 10
            wrapMode: U.b(r.app, "NotepadK", "word_wrap", true) ? Text.WordWrap : Text.NoWrap
            clip: true
            color: r.fg
            font.family: U.v(r.app, "NotepadK", "font_family", "Noto Sans Mono")
            font.pixelSize: r.fontPx
            lineHeight: U.n(r.app, "NotepadK", "line_height", 1.2)
            text: r.sample
            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
        Rectangle {   // current line
            visible: U.b(r.app, "NotepadK", "current_line", false)
            x: 0; width: page.width; z: -1
            y: body.y + body.font.pixelSize * body.lineHeight * 1.25 * 2
            height: body.font.pixelSize * body.lineHeight * 1.25
            color: r.fg; opacity: 0.05
        }
        Text {
            visible: U.b(r.app, "NotepadK", "word_count", false) && !r.full
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 10
            text: r.sample.trim().split(/\s+/).length + " palavras"
            color: r.fg; opacity: 0.45; font.pixelSize: 10
        }
        Rectangle {   // floating button
            visible: U.b(r.app, "NotepadK", "show_button", true)
            anchors.right: parent.right; anchors.rightMargin: 14; y: r.full ? 40 : 4
            width: 22; height: 22; radius: 5; color: Qt.rgba(0.5, 0.5, 0.5, 0.25)
            opacity: r.full ? 0.6 : U.n(r.app, "NotepadK", "button_opacity", 35) / 100
            Text { anchors.centerIn: parent; text: r.full ? "⤡" : "⤢"; color: r.fg; font.pixelSize: 12 }
        }
    }

    // click = show the transition with the chosen style
    Item {
        id: ghost
        x: page.x; y: page.y; width: page.width; height: page.height; opacity: 0
        Image { id: ghostImg; anchors.fill: parent; cache: false }
    }
    ParallelAnimation {
        id: trans
        readonly property int ms: U.n(r.app, "NotepadK", "fade_ms", 320)
        readonly property string style: U.v(r.app, "NotepadK", "transition", "fade")
        readonly property int curve: ({ smooth: Easing.InOutCubic, fast: Easing.OutExpo, bounce: Easing.OutBack, linear: Easing.Linear })[U.v(r.app, "NotepadK", "easing", "smooth")] || Easing.InOutCubic
        NumberAnimation { target: ghost; property: "opacity"; from: 1; to: 0; duration: trans.ms; easing.type: trans.curve }
        NumberAnimation { target: ghost; property: "y"; from: page.y; to: trans.style === "slide" ? page.y + (r.full ? 1 : -1) * page.height / 10 : page.y; duration: trans.ms; easing.type: trans.curve }
        NumberAnimation { target: ghost; property: "scale"; from: 1; to: trans.style === "zoom" ? (r.full ? 1.04 : 0.96) : 1; duration: trans.ms; easing.type: trans.curve }
    }
    MouseArea {
        anchors.fill: page
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (U.v(r.app, "NotepadK", "transition", "fade") === "none" || trans.ms <= 0) { r.full = !r.full; return; }
            page.grabToImage(function (res) {
                ghostImg.source = res.url;
                ghost.opacity = 1;
                r.full = !r.full;
                trans.restart();
            });
        }
    }
    Text { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 2
        text: "clique na folha para ver a transição"; color: "white"; opacity: 0.6; font.pixelSize: 10; style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.4) }
}
