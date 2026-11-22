// Section: cursor studio (module cursor.py → ~/.local/share/vidro/cursor/make-cursor.py)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
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
        QQC2.Button { text: "Vidro escuro"; onClicked: s.preset({ shape: "modern", fill: "#1d1e23", outline: "#ffffff", accent: "#5b9cf5", outline_width: "1.3", roundness: "1", shadow: "45" }) }
        QQC2.Button { text: "Branco clássico"; onClicked: s.preset({ shape: "classic", fill: "#ffffff", outline: "#111111", accent: "#3daee9", outline_width: "1", roundness: "0.5", shadow: "35" }) }
        QQC2.Button { text: "Mínimo"; onClicked: s.preset({ shape: "minimal", fill: "#f4f4f6", outline: "#1a1a1e", accent: "#ff6b6b", outline_width: "1.1", roundness: "1.6", shadow: "25" }) }
        QQC2.Button { text: "Neon"; onClicked: s.preset({ shape: "triangle", fill: "#0e0f14", outline: "#39e6ff", accent: "#ff3df2", outline_width: "1.6", roundness: "1.2", shadow: "60" }) }
        QQC2.Button { text: "Cor de destaque"; onClicked: s.preset({ shape: "modern", fill: (s.app.cfg.Colors && s.app.cfg.Colors.accent_color) ? s.app.cfg.Colors.accent_color : "#3daee9", outline: "#ffffff", accent: "#ffffff", outline_width: "1.3", roundness: "1", shadow: "45" }) }
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
    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Importar desenhos (SVG, .ico, .cur)" }
    QQC2.Label { Kirigami.FormData.label: ""; text: "Troque qualquer cursor por um desenho seu: SVG ou cursores do Windows (.ico/.cur). Com \"Cores do estúdio\" o editor trabalha em cima dele — cor de dentro, contorno, cantos e sombra acima passam a valer no desenho. A seta importada também vale para copiar, ajuda, ocupado etc. Arquivos .cur trazem o próprio ponto de clique."
        wrapMode: Text.WordWrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 26; opacity: 0.7 }
    component SvgSlot: RowLayout {
        id: slot
        property string name
        readonly property string file: s.v("svg_" + name)
        spacing: Kirigami.Units.smallSpacing
        QQC2.Button { text: slot.file ? "Trocar…" : "Escolher…"; icon.name: "document-open"; onClicked: dlg.open() }
        QQC2.Label { text: slot.file ? slot.file.split("/").pop() : "desenho do Vidro"; opacity: slot.file ? 0.9 : 0.55; elide: Text.ElideMiddle; Layout.maximumWidth: Kirigami.Units.gridUnit * 8 }
        QQC2.ComboBox {
            visible: slot.file !== ""
            model: [ { t: "Cores do estúdio", v: "editor" }, { t: "Cores originais", v: "original" } ]
            textRole: "t"; valueRole: "v"
            currentIndex: s.v("mode_" + slot.name) === "original" ? 1 : 0
            onActivated: s.app.set("Cursor", "mode_" + slot.name, currentValue)
        }
        QQC2.ComboBox {
            visible: slot.file !== ""
            model: [ { t: "Ponto: automático", v: "auto" }, { t: "Ponto: canto sup. esquerdo", v: "topleft" }, { t: "Ponto: topo", v: "top" }, { t: "Ponto: centro", v: "center" } ]
            textRole: "t"; valueRole: "v"
            currentIndex: Math.max(0, ["auto", "topleft", "top", "center"].indexOf(s.v("hot_" + slot.name)))
            onActivated: s.app.set("Cursor", "hot_" + slot.name, currentValue)
            QQC2.ToolTip.text: "Onde fica a \"ponta\" que clica"; QQC2.ToolTip.visible: hovered
        }
        QQC2.ToolButton { visible: slot.file !== ""; icon.name: "edit-clear"; QQC2.ToolTip.text: "Voltar ao desenho do Vidro"; QQC2.ToolTip.visible: hovered
            onClicked: s.app.set("Cursor", "svg_" + slot.name, "") }
        FileDialog {
            id: dlg
            title: "Escolha um desenho (SVG) ou cursor do Windows (.ico/.cur)"
            nameFilters: ["Desenhos e cursores (*.svg *.ico *.cur *.png)", "SVG (*.svg)", "Cursores do Windows (*.ico *.cur)"]
            onAccepted: s.app.set("Cursor", "svg_" + slot.name, decodeURIComponent(String(selectedFile).replace(/^file:\/\//, "")))
        }
    }
    SvgSlot { name: "arrow"; Kirigami.FormData.label: "Seta:" }
    SvgSlot { name: "hand"; Kirigami.FormData.label: "Mão (links):" }
    SvgSlot { name: "text"; Kirigami.FormData.label: "Texto:" }
    SvgSlot { name: "wait"; Kirigami.FormData.label: "Espera:" }
    SvgSlot { name: "forbidden"; Kirigami.FormData.label: "Proibido:" }
    SvgSlot { name: "move"; Kirigami.FormData.label: "Mover:" }
    SvgSlot { name: "crosshair"; Kirigami.FormData.label: "Mira:" }

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
