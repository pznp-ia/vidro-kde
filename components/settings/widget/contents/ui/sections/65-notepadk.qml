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
    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Bloco de texto" }
    ValueSlider { app: s.app; group: "NotepadK"; key: "margin"; from: 0; to: 160; unit: " px"; Kirigami.FormData.label: "Margem dos lados:" }
    ValueSlider { app: s.app; group: "NotepadK"; key: "margin_top"; from: 0; to: 100; unit: " px"; Kirigami.FormData.label: "Margem em cima/embaixo:" }
    QQC2.Switch { id: colOn; Kirigami.FormData.label: "Coluna centralizada:"; checked: Number(s.v("column_chars")) > 0
        text: checked ? "sim (texto numa coluna no meio)" : "não (ocupa a largura toda)"
        onToggled: s.app.set("NotepadK", "column_chars", checked ? 80 : 0) }
    ValueSlider { app: s.app; group: "NotepadK"; key: "column_chars"; from: 40; to: 140; step: 2; unit: " letras"; visible: Number(s.v("column_chars")) > 0; Kirigami.FormData.label: "Largura da coluna:" }
    Toggle { app: s.app; group: "NotepadK"; key: "current_line"; Kirigami.FormData.label: "Destacar linha atual:"; text: checked ? "sim, bem de leve" : "não" }
    Toggle { app: s.app; group: "NotepadK"; key: "typewriter"; Kirigami.FormData.label: "Máquina de escrever:"; text: checked ? "a linha do cursor fica perto do meio" : "rolagem normal" }
    Toggle { app: s.app; group: "NotepadK"; key: "word_count"; Kirigami.FormData.label: "Contador de palavras:"; text: checked ? "discreto, no canto" : "esconder" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Janela" }
    ValueSlider { app: s.app; group: "NotepadK"; key: "window_opacity"; from: 30; to: 100; unit: "%"; Kirigami.FormData.label: "Opacidade da janela:" }
    Toggle { app: s.app; group: "NotepadK"; key: "hide_titlebar"; Kirigami.FormData.label: "Barra de título no foco:"; text: checked ? "esconder" : "mostrar" }
    Toggle { app: s.app; group: "NotepadK"; key: "keep_above"; Kirigami.FormData.label: "Sempre no topo (foco):"; text: checked ? "sim" : "não" }
    Toggle { app: s.app; group: "NotepadK"; key: "show_button"; Kirigami.FormData.label: "Botão flutuante:"; text: checked ? "mostrar (Ctrl+Shift+Espaço sempre funciona)" : "esconder (use Ctrl+Shift+Espaço)" }
    ValueSlider { app: s.app; group: "NotepadK"; key: "button_opacity"; from: 5; to: 100; unit: "%"; visible: s.v("show_button") === "true"; Kirigami.FormData.label: "Opacidade do botão:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Animações" }
    Choice { app: s.app; group: "NotepadK"; key: "transition"; Kirigami.FormData.label: "Troca foco ↔ interface:"
        options: [ { text: "Esmaecer", value: "fade" }, { text: "Deslizar", value: "slide" }, { text: "Zoom", value: "zoom" }, { text: "Sem animação", value: "none" } ] }
    Choice { app: s.app; group: "NotepadK"; key: "easing"; enabled: s.v("transition") !== "none"; Kirigami.FormData.label: "Curva:"
        options: [ { text: "Suave", value: "smooth" }, { text: "Rápida no começo", value: "fast" }, { text: "Elástica", value: "bounce" }, { text: "Linear", value: "linear" } ] }
    Toggle { app: s.app; group: "NotepadK"; key: "open_animation"; Kirigami.FormData.label: "Ao abrir:"; text: checked ? "o texto aparece suavemente" : "sem animação" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Modo foco" }
    Toggle { app: s.app; group: "NotepadK"; key: "start_focused"; Kirigami.FormData.label: "Abrir no modo foco:"; text: checked ? "sim" : "com a interface completa" }
    ValueSlider { app: s.app; group: "NotepadK"; key: "fade_ms"; from: 0; to: 1000; step: 20; unit: " ms"; Kirigami.FormData.label: "Duração das animações:" }
    ValueSlider { app: s.app; group: "NotepadK"; key: "strip_height"; from: 16; to: 60; unit: " px"; Kirigami.FormData.label: "Faixa para arrastar a janela:" }
}
