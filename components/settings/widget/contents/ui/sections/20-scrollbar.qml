// Section: app scrollbars (module ~/.local/share/vidro/modules/scrollbar.py)
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Barra de rolagem"
    icon: "view-list-text"
    preview: Component { PreviewScrollbar { app: s.app } }
    description: "Vale para os apps do KDE (estilo de apps Vidro / Union). \"Sobreposta\" põe a barra por cima do conteúdo, transparente de verdade, como no macOS — ligar/desligar vale a partir do próximo login; os outros ajustes valem em janelas novas."
    readonly property bool isOn: !!(app && app.cfg.Scrollbar && app.cfg.Scrollbar.enabled === "true")
    readonly property string mode: (app && app.cfg.Scrollbar) ? app.cfg.Scrollbar.mode : "glass"
    Toggle { app: s.app; group: "Scrollbar"; key: "enabled"; Kirigami.FormData.label: "Barra do Vidro:"; text: checked ? "ligada" : "desligada (barra padrão)" }
    Choice {
        app: s.app; group: "Scrollbar"; key: "mode"; enabled: s.isOn
        Kirigami.FormData.label: "Estilo:"
        options: [ { text: "Vidro", value: "glass" }, { text: "Neon fino", value: "thin-neon" }, { text: "Cor personalizada", value: "color" } ]
    }
    ColorButton { app: s.app; group: "Scrollbar"; key: "color"; visible: s.mode === "color"; enabled: s.isOn; Kirigami.FormData.label: "Cor:" }
    ValueSlider { app: s.app; group: "Scrollbar"; key: "width"; from: 2; to: 16; unit: " px"; enabled: s.isOn; Kirigami.FormData.label: "Espessura:" }
    ValueSlider { app: s.app; group: "Scrollbar"; key: "opacity"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Opacidade:" }
    ValueSlider { app: s.app; group: "Scrollbar"; key: "highlight"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Ao passar o mouse:" }
    ValueSlider { app: s.app; group: "Scrollbar"; key: "roundness"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Arredondamento:" }
    Toggle { app: s.app; group: "Scrollbar"; key: "track"; enabled: s.isOn; Kirigami.FormData.label: "Trilho:"; text: checked ? "visível" : "invisível" }
    readonly property bool sobre: !!(app && app.cfg.Scrollbar && app.cfg.Scrollbar.overlay === "true")
    readonly property bool some: !!(app && app.cfg.Scrollbar && app.cfg.Scrollbar.autohide === "true")
    Toggle { app: s.app; group: "Scrollbar"; key: "overlay"; enabled: s.isOn; Kirigami.FormData.label: "Por cima do conteúdo:"; text: checked ? "sim (transparente de verdade)" : "não (faixa própria)" }
    Toggle { app: s.app; group: "Scrollbar"; key: "autohide"; enabled: s.isOn && s.sobre; Kirigami.FormData.label: "Some quando parada:"; text: checked ? "sim" : "não" }
    ValueSlider { app: s.app; group: "Scrollbar"; key: "delay"; from: 300; to: 5000; step: 100; unit: " ms"; enabled: s.isOn && s.sobre && s.some; Kirigami.FormData.label: "Tempo até sumir:" }
    ValueSlider { app: s.app; group: "Scrollbar"; key: "min_opacity"; from: 0; to: 100; unit: "%"; enabled: s.isOn && s.sobre && s.some; Kirigami.FormData.label: "Visível quando parada:" }
}
