// Section: NotepadK (module notepadk.py → NotepadK's own katerc; the normal Kate is unchanged)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "NotepadK"
    icon: "accessories-text-editor"
    preview: Component { PreviewNotepadk { app: s.app } }
    description: "Fonte, cores e espaçamento do bloco de notas, e o modo foco. Vale na próxima vez que o NotepadK abrir (o Kate normal não muda)."
    function v(k) { return (app && app.cfg.NotepadK) ? String(app.cfg.NotepadK[k]) : "" }
    RowLayout {
        Kirigami.FormData.label: "Fonte:"
        QQC2.ComboBox {
            id: fonts
            editable: true
            implicitWidth: Kirigami.Units.gridUnit * 13
            model: ["Noto Sans Mono", "Fira Code", "Adwaita Mono", "Liberation Mono", "Noto Sans", "Noto Serif", "Inter"]
            editText: s.v("font_family")
            onActivated: s.app.set("NotepadK", "font_family", currentText)
            onAccepted: s.app.set("NotepadK", "font_family", editText)
        }
    }
    ValueSlider { app: s.app; group: "NotepadK"; key: "font_size"; from: 7; to: 24; unit: " pt"; Kirigami.FormData.label: "Tamanho:" }
    ValueSlider { app: s.app; group: "NotepadK"; key: "line_height"; from: 1; to: 2.2; step: 0.05; Kirigami.FormData.label: "Espaço entre linhas:" }
    Choice { app: s.app; group: "NotepadK"; key: "color_theme"; Kirigami.FormData.label: "Cores do texto:"
        options: [ { text: "Automático (claro/escuro do sistema)", value: "auto" }, { text: "Breeze escuro", value: "Breeze Dark" },
                   { text: "Breeze claro", value: "Breeze Light" }, { text: "Nord", value: "Nord" }, { text: "Dracula", value: "Dracula" },
                   { text: "Monokai", value: "Monokai" }, { text: "Solarized escuro", value: "Solarized Dark" },
                   { text: "Solarized claro", value: "Solarized Light" }, { text: "GitHub escuro", value: "GitHub Dark" } ] }
    Toggle { app: s.app; group: "NotepadK"; key: "word_wrap"; Kirigami.FormData.label: "Quebrar linhas longas:"; text: checked ? "sim" : "não" }
    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Modo foco" }
    Toggle { app: s.app; group: "NotepadK"; key: "start_focused"; Kirigami.FormData.label: "Abrir no modo foco:"; text: checked ? "sim" : "com a interface completa" }
    ValueSlider { app: s.app; group: "NotepadK"; key: "fade_ms"; from: 0; to: 1000; step: 20; unit: " ms"; Kirigami.FormData.label: "Transição foco ↔ interface:" }
    ValueSlider { app: s.app; group: "NotepadK"; key: "strip_height"; from: 16; to: 60; unit: " px"; Kirigami.FormData.label: "Faixa para arrastar a janela:" }
}
