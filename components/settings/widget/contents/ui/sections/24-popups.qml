// Section: launcher and Plasma popups (module popups.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Menu iniciar e pop-ups do painel"
    icon: "start-here-kde"
    preview: Component { PreviewPopup { app: s.app } }
    description: "Fundo de vidro, cantos e sombra do menu iniciar, relógio, bandeja e outros pop-ups do Plasma. Ao mudar, o Plasma recarrega o estilo (pisca rápido)."
    readonly property bool isOn: !!(app && app.cfg.Popups && app.cfg.Popups.enabled === "true")
    Toggle { app: s.app; group: "Popups"; key: "enabled"; Kirigami.FormData.label: "Pop-ups do Vidro:"; text: checked ? "ligados" : "desligados (como eram)" }
    ValueSlider { app: s.app; group: "Popups"; key: "radius"; from: 2; to: 30; unit: " px"; enabled: s.isOn; Kirigami.FormData.label: "Cantos:" }
    Choice {
        app: s.app; group: "Popups"; key: "background"; enabled: s.isOn
        Kirigami.FormData.label: "Cor do vidro:"
        options: [ { text: "Do tema", value: "theme" }, { text: "Cor personalizada", value: "custom" } ]
    }
    ColorButton { app: s.app; group: "Popups"; key: "glass_color"; visible: !!(s.app && s.app.cfg.Popups && s.app.cfg.Popups.background === "custom"); enabled: s.isOn; Kirigami.FormData.label: "Cor:" }
    ValueSlider { app: s.app; group: "Popups"; key: "opacity"; from: 30; to: 100; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Opacidade do fundo:" }
    ValueSlider { app: s.app; group: "Popups"; key: "lines"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Linhas do cabeçalho/rodapé:" }
    ValueSlider { app: s.app; group: "Popups"; key: "header"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Fundo do cabeçalho/rodapé:" }
    ValueSlider { app: s.app; group: "Popups"; key: "border"; from: 0; to: 60; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Contorno:" }
    ValueSlider { app: s.app; group: "Popups"; key: "shadow"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Sombra:" }
    ValueSlider { app: s.app; group: "Popups"; key: "shadow_size"; from: 4; to: 40; unit: " px"; enabled: s.isOn; Kirigami.FormData.label: "Tamanho da sombra:" }
}
