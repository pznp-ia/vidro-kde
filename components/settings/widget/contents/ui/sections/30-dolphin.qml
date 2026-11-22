// Section: Dolphin (module ~/.local/share/vidro/modules/dolphin.py)
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Pastas (Dolphin)"
    icon: "system-file-manager"
    preview: Component { PreviewDolphin { app: s.app } }
    description: "Sem linhas de separação e com a área de arquivos na cor da interface. Reabra o Dolphin para ver. O fundo das listas vem do esquema de cores, então também vale para as listas dos outros apps do KDE."
    readonly property bool isOn: !!(app && app.cfg.Dolphin && app.cfg.Dolphin.enabled === "true")
    readonly property bool background: !!(app && app.cfg.Dolphin && app.cfg.Dolphin.unify === "true")
    Toggle { app: s.app; group: "Dolphin"; key: "enabled"; Kirigami.FormData.label: "Dolphin fluido:"; text: checked ? "ligado" : "desligado (igual aos outros apps)" }
    ValueSlider { app: s.app; group: "Dolphin"; key: "separators"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Linhas de separação:" }
    ValueSlider { app: s.app; group: "Dolphin"; key: "spacing"; from: 0; to: 16; unit: " px"; enabled: s.isOn; Kirigami.FormData.label: "Respiro entre as partes:" }
    Toggle { app: s.app; group: "Dolphin"; key: "unify"; enabled: s.isOn; Kirigami.FormData.label: "Fundo dos arquivos:"; text: checked ? "na cor da interface" : "escuro original" }
    Choice {
        app: s.app; group: "Dolphin"; key: "background"; enabled: s.isOn
        Kirigami.FormData.label: "Cor do fundo:"
        options: [ { text: "Cor da interface", value: "interface" }, { text: "Cor personalizada", value: "custom" } ]
    }
    ColorButton { app: s.app; group: "Dolphin"; key: "background_color"; visible: !!(s.app && s.app.cfg.Dolphin && s.app.cfg.Dolphin.background === "custom"); enabled: s.isOn; Kirigami.FormData.label: "Cor:" }
    ValueSlider { app: s.app; group: "Dolphin"; key: "darken"; unit: "%"; enabled: s.isOn && s.background; Kirigami.FormData.label: "Cor escolhida ↔ mais escuro:" }
}
