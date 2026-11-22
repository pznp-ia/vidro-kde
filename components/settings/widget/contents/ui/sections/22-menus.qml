// Section: app right-click menus (module menus.py); their animation is in 14-animations.qml
import QtQuick
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Menus (clique direito)"
    icon: "application-menu"
    preview: Component { PreviewMenu { app: s.app } }
    description: "Aparência dos menus de clique direito dos apps do KDE. A animação de abrir e fechar fica na aba Animações."
    readonly property bool isOn: !!(app && app.cfg.Menus && app.cfg.Menus.enabled === "true")
    readonly property var cfgMenus: (app && app.cfg.Menus) ? app.cfg.Menus : ({})
    readonly property bool anim: !!(app && app.cfg.Menus && app.cfg.Menus.animation === "true")
    Toggle { app: s.app; group: "Menus"; key: "enabled"; Kirigami.FormData.label: "Menus do Vidro:"; text: checked ? "ligados" : "desligados (padrão)" }
    ValueSlider { app: s.app; group: "Menus"; key: "radius"; from: 0; to: 24; unit: " px"; enabled: s.isOn; Kirigami.FormData.label: "Cantos:" }
    Choice {
        app: s.app; group: "Menus"; key: "background"; enabled: s.isOn
        Kirigami.FormData.label: "Cor do fundo:"
        options: [ { text: "Do tema", value: "theme" }, { text: "Cor personalizada", value: "custom" } ]
    }
    ColorButton { app: s.app; group: "Menus"; key: "background_color"; visible: s.cfgMenus.background === "custom"; enabled: s.isOn; Kirigami.FormData.label: "Cor:" }
    ValueSlider { app: s.app; group: "Menus"; key: "opacity"; from: 40; to: 100; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Opacidade do fundo:" }
    ValueSlider { app: s.app; group: "Menus"; key: "padding"; from: 0; to: 14; unit: " px"; enabled: s.isOn; Kirigami.FormData.label: "Respiro:" }
    ValueSlider { app: s.app; group: "Menus"; key: "separators"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Linhas separadoras:" }
    ValueSlider { app: s.app; group: "Menus"; key: "border"; from: 0; to: 60; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Contorno:" }
    Choice {
        app: s.app; group: "Menus"; key: "highlight"; enabled: s.isOn
        Kirigami.FormData.label: "Item sob o mouse:"
        options: [ { text: "Vidro (neutro)", value: "glass" }, { text: "Cor de destaque", value: "accent" }, { text: "Cor personalizada", value: "custom" } ]
    }
    ColorButton { app: s.app; group: "Menus"; key: "highlight_color"; visible: s.cfgMenus.highlight === "custom"; enabled: s.isOn; Kirigami.FormData.label: "Cor do realce:" }
    ValueSlider { app: s.app; group: "Menus"; key: "intensity"; from: 0; to: 60; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Força do realce:" }
}
