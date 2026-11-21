// Exemplo: os cursores gerados de verdade (prévia em ~/.cache/vidro/cursor-previa)
import QtQuick
Item {
    id: r
    property var app
    Fundo { anchors.fill: parent; app: r.app }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.15) }
    Grid {
        anchors.centerIn: parent
        columns: 8; spacing: 14
        Repeater {
            model: [["default", "default"], ["pointer", "pointer"], ["text", "text"], ["wait", "wait-01"], ["progress", "progress-04"],
                    ["openhand", "openhand"], ["dnd-move", "dnd-move"], ["crosshair", "crosshair"], ["size_hor", "size_hor"],
                    ["size_fdiag", "size_fdiag"], ["fleur", "fleur"], ["not-allowed", "not-allowed"], ["help", "help"],
                    ["copy", "copy"], ["zoom-in", "zoom-in"], ["pencil", "pencil"]]
            Image {
                width: 52; height: 52; sourceSize: Qt.size(104, 104); cache: false; asynchronous: true
                source: (r.app && r.app.home) ? "file://" + r.app.home + "/.cache/vidro/cursor-previa/cursors_scalable/" + modelData[0] + "/" + modelData[1] + ".svg?v=" + r.app.versao : ""
            }
        }
    }
}
