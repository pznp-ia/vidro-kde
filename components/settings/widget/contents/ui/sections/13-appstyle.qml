// Section: app style studio (module appstyle.py → Union style "vidro", css/module-appstyle.css)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Estilo dos aplicativos"
    icon: "preferences-desktop-theme-applications"
    preview: Component { PreviewAppStyle { app: s.app } }
    description: "Botões, campos de texto, caixas de seleção, abas e listas de todos os apps do KDE. Os apps já abertos mudam quando são reabertos; \"Abrir prévia real\" mostra uma janela nova com o estilo de agora."
    function v(k) { return (app && app.cfg.AppStyle) ? String(app.cfg.AppStyle[k]) : "" }
    readonly property bool isOn: v("enabled") === "true"
    RowLayout {
        Kirigami.FormData.label: ""
        QQC2.Button { text: "Abrir prévia real"; icon.name: "view-preview"; onClicked: s.app.run("$HOME/.local/share/vidro/bin/vidro-preview >/dev/null 2>&1 & #preview" + Date.now()) }
    }
    Toggle { app: s.app; group: "AppStyle"; key: "enabled"; Kirigami.FormData.label: "Estilo do estúdio:"; text: checked ? "ligado" : "desligado (padrão do Vidro)" }
    ValueSlider { app: s.app; group: "AppStyle"; key: "radius"; from: 0; to: 18; unit: " px"; enabled: s.isOn; Kirigami.FormData.label: "Cantos:" }
    Choice { app: s.app; group: "AppStyle"; key: "density"; enabled: s.isOn; Kirigami.FormData.label: "Espaçamento:"
        options: [ { text: "Compacto", value: "compact" }, { text: "Normal", value: "normal" }, { text: "Confortável", value: "comfortable" } ] }
    Choice { app: s.app; group: "AppStyle"; key: "buttons"; enabled: s.isOn; Kirigami.FormData.label: "Botões:"
        options: [ { text: "Vidro", value: "glass" }, { text: "Planos (fundo só ao passar o mouse)", value: "flat" },
                   { text: "Contorno", value: "outline" }, { text: "Preenchidos com o destaque", value: "filled" } ] }
    ValueSlider { app: s.app; group: "AppStyle"; key: "button_border"; from: 0; to: 60; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Borda dos botões:" }
    Choice { app: s.app; group: "AppStyle"; key: "fields"; enabled: s.isOn; Kirigami.FormData.label: "Campos de texto:"
        options: [ { text: "Vidro", value: "glass" }, { text: "Preenchidos", value: "filled" }, { text: "Só um sublinhado", value: "flat" } ] }
    Choice { app: s.app; group: "AppStyle"; key: "checks"; enabled: s.isOn; Kirigami.FormData.label: "Caixas de seleção:"
        options: [ { text: "Quadradas arredondadas", value: "rounded" }, { text: "Redondas", value: "circle" } ] }
    Choice { app: s.app; group: "AppStyle"; key: "check_color"; enabled: s.isOn; Kirigami.FormData.label: "Marcadas:"
        options: [ { text: "Na cor de destaque", value: "accent" }, { text: "Vidro", value: "glass" } ] }
    Choice { app: s.app; group: "AppStyle"; key: "tabs"; enabled: s.isOn; Kirigami.FormData.label: "Abas:"
        options: [ { text: "Segmentadas", value: "segmented" }, { text: "Pílulas", value: "pill" }, { text: "Sublinhadas", value: "underline" } ] }
    Choice { app: s.app; group: "AppStyle"; key: "selection"; enabled: s.isOn; Kirigami.FormData.label: "Seleção nas listas:"
        options: [ { text: "Pílula (arredondada)", value: "pill" }, { text: "De ponta a ponta", value: "full" } ] }
    Choice { app: s.app; group: "AppStyle"; key: "focus"; enabled: s.isOn; Kirigami.FormData.label: "Foco do teclado:"
        options: [ { text: "Anel", value: "ring" }, { text: "Brilho", value: "glow" }, { text: "Nenhum", value: "none" } ] }
    Choice { app: s.app; group: "AppStyle"; key: "accent_mode"; enabled: s.isOn; Kirigami.FormData.label: "Cor dos destaques:"
        options: [ { text: "Do tema", value: "theme" }, { text: "Personalizada", value: "custom" } ] }
    ColorButton { app: s.app; group: "AppStyle"; key: "accent_color"; visible: s.v("accent_mode") === "custom"; enabled: s.isOn; Kirigami.FormData.label: "Cor:" }
}
