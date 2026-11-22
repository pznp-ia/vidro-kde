// Section: accent color (selection) and text color (module colors.py) — change immediately
import QtQuick
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Cores: destaque e fonte"
    icon: "color-management"
    preview: Component { PreviewColors { app: s.app } }
    description: "Cor de destaque = seleção (ex.: pasta selecionada no Dolphin), foco e realces. Cor da fonte = texto dos apps. Mudam na hora (vale para o esquema escuro Vidro)."
    readonly property var c: (app && app.cfg.Colors) ? app.cfg.Colors : ({})
    Choice {
        app: s.app; group: "Colors"; key: "accent"
        Kirigami.FormData.label: "Cor de destaque:"
        options: [ { text: "Do tema (azul)", value: "theme" }, { text: "Cor personalizada", value: "custom" } ]
    }
    ColorButton { app: s.app; group: "Colors"; key: "accent_color"; visible: s.c.accent === "custom"; Kirigami.FormData.label: "Cor:" }
    ValueSlider { app: s.app; group: "Colors"; key: "strength"; unit: "%"; enabled: s.c.accent === "custom"; Kirigami.FormData.label: "Força na seleção:" }
    Choice {
        app: s.app; group: "Colors"; key: "text"
        Kirigami.FormData.label: "Cor da fonte:"
        options: [ { text: "Do tema (branco)", value: "theme" }, { text: "Cor personalizada", value: "custom" } ]
    }
    ColorButton { app: s.app; group: "Colors"; key: "text_color"; visible: s.c.text === "custom"; Kirigami.FormData.label: "Cor:" }
    ValueSlider { app: s.app; group: "Colors"; key: "secondary"; from: 0; to: 80; unit: "%"; enabled: s.c.text === "custom"; Kirigami.FormData.label: "Texto secundário mais apagado:" }
}
