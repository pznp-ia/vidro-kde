// Section: folder colors (module icons.py) — changes immediately in every app
import QtQuick
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Pastas (cores dos ícones)"
    icon: "folder"
    preview: Component { PreviewFolders { app: s.app } }
    description: "Cor das pastas grandes no Dolphin, no menu e nos diálogos. Muda na hora."
    readonly property bool isOn: !!(app && app.cfg.Icons && app.cfg.Icons.enabled === "true")
    readonly property string mode: (app && app.cfg.Icons) ? app.cfg.Icons.folder_mode : "graphite"
    Toggle { app: s.app; group: "Icons"; key: "enabled"; Kirigami.FormData.label: "Cores do Vidro:"; text: checked ? "ligadas" : "desligadas (pastas escuras originais)" }
    Choice {
        app: s.app; group: "Icons"; key: "folder_mode"; enabled: s.isOn
        Kirigami.FormData.label: "Estilo:"
        options: [ { text: "Grafite claro", value: "graphite" }, { text: "Escuro", value: "dark" },
                  { text: "Cor de destaque", value: "accent" }, { text: "Cor personalizada", value: "custom" } ]
    }
    ColorButton { app: s.app; group: "Icons"; key: "folder_color"; visible: s.mode === "custom"; enabled: s.isOn; Kirigami.FormData.label: "Cor:" }
    ValueSlider { app: s.app; group: "Icons"; key: "brightness"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Brilho:" }
    ValueSlider { app: s.app; group: "Icons"; key: "relief"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Relevo:" }
    ValueSlider { app: s.app; group: "Icons"; key: "saturation"; unit: "%"; enabled: s.isOn && (s.mode === "accent" || s.mode === "custom"); Kirigami.FormData.label: "Saturação:" }
}
