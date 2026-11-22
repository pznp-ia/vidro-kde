// Section: cursor studio (module cursor.py → ~/.local/share/vidro/cursor/make-cursor.py)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Estúdio do cursor"
    icon: "input-mouse"
    preview: Component { PreviewCursor { app: s.app } }
    description: "Monte o seu cursor: forma da seta, cores, contorno, cantos e sombra. O exemplo mostra o resultado na hora; ligue \"Usar no sistema\" para trocar o cursor de verdade (desligar volta ao que você usava)."
    function v(k) { return (app && app.cfg.Cursor) ? String(app.cfg.Cursor[k]) : "" }
    function preset(m) { for (const k in m) s.app.set("Cursor", k, m[k]); }
    Toggle { app: s.app; group: "Cursor"; key: "enabled"; Kirigami.FormData.label: "Usar no sistema:"; text: checked ? "sim (cursor do Vidro)" : "não (cursor de antes)" }
    Flow {
        Kirigami.FormData.label: "Modelos prontos:"
        width: Kirigami.Units.gridUnit * 26
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        spacing: Kirigami.Units.smallSpacing
        QQC2.Button { text: "Vidro escuro"; onClicked: s.preset({ shape: "moderna", background: "#1d1e23", outline: "#ffffff", accent: "#5b9cf5", border: "1.3", corners: "1", shadow: "45" }) }
        QQC2.Button { text: "Branco clássico"; onClicked: s.preset({ shape: "classica", background: "#ffffff", outline: "#111111", accent: "#3daee9", border: "1", corners: "0.5", shadow: "35" }) }
        QQC2.Button { text: "Mínimo"; onClicked: s.preset({ shape: "minima", background: "#f4f4f6", outline: "#1a1a1e", accent: "#ff6b6b", border: "1.1", corners: "1.6", shadow: "25" }) }
        QQC2.Button { text: "Neon"; onClicked: s.preset({ shape: "triangulo", background: "#0e0f14", outline: "#39e6ff", accent: "#ff3df2", border: "1.6", corners: "1.2", shadow: "60" }) }
        QQC2.Button { text: "Cor de destaque"; onClicked: s.preset({ shape: "moderna", background: (s.app.cfg.Colors && s.app.cfg.Colors.accent_color) ? s.app.cfg.Colors.accent_color : "#3daee9", outline: "#ffffff", accent: "#ffffff", border: "1.3", corners: "1", shadow: "45" }) }
    }
    Choice { app: s.app; group: "Cursor"; key: "shape"; Kirigami.FormData.label: "Forma da seta:"
        options: [ { text: "Moderna (estilo macOS)", value: "modern" }, { text: "Clássica", value: "classic" },
                  { text: "Mínima (sem cauda)", value: "minimal" }, { text: "Triângulo", value: "triangle" } ] }
    ColorButton { app: s.app; group: "Cursor"; key: "fill"; Kirigami.FormData.label: "Cor de dentro:" }
    ColorButton { app: s.app; group: "Cursor"; key: "outline"; Kirigami.FormData.label: "Cor do contorno:" }
    ColorButton { app: s.app; group: "Cursor"; key: "accent"; Kirigami.FormData.label: "Detalhes (espera, selos):" }
    ValueSlider { app: s.app; group: "Cursor"; key: "outline_width"; from: 0; to: 3; step: 0.1; Kirigami.FormData.label: "Contorno:" }
    ValueSlider { app: s.app; group: "Cursor"; key: "roundness"; from: 0; to: 3; step: 0.1; Kirigami.FormData.label: "Cantos arredondados:" }
    ValueSlider { app: s.app; group: "Cursor"; key: "shadow"; unit: "%"; Kirigami.FormData.label: "Sombra:" }
    Choice { app: s.app; group: "Cursor"; key: "size"; Kirigami.FormData.label: "Tamanho no sistema:"
        options: [ { text: "Pequeno (24)", value: "24" }, { text: "Médio (32)", value: "32" }, { text: "Grande (48)", value: "48" }, { text: "Enorme (64)", value: "64" } ] }
    // test area: each square uses one cursor shape (shows the system cursor)
    Flow {
        Kirigami.FormData.label: "Teste (passe o mouse):"
        width: Kirigami.Units.gridUnit * 26
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        spacing: 4
        Repeater {
            model: [[Qt.ArrowCursor, "seta"], [Qt.PointingHandCursor, "mão"], [Qt.IBeamCursor, "texto"], [Qt.WaitCursor, "espera"],
                    [Qt.BusyCursor, "ocupado"], [Qt.OpenHandCursor, "pegar"], [Qt.ClosedHandCursor, "arrastar"], [Qt.CrossCursor, "mira"],
                    [Qt.SizeHorCursor, "↔"], [Qt.SizeVerCursor, "↕"], [Qt.SizeFDiagCursor, "⤡"], [Qt.SizeAllCursor, "mover"],
                    [Qt.ForbiddenCursor, "proibido"], [Qt.WhatsThisCursor, "ajuda"], [Qt.DragCopyCursor, "copiar"]]
            Rectangle {
                width: 74; height: 34; radius: 6
                color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.05)
                QQC2.Label { anchors.centerIn: parent; text: modelData[1]; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: modelData[0] }
            }
        }
    }
}
