// Section: light version (experimental) — module ~/.local/share/vidro/modules/light.py
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Versão clara (teste)"
    icon: "weather-clear"
    preview: Component { PreviewSimple { app: s.app; light: !!(s.app && s.app.cfg.Light && s.app.cfg.Light.enabled === "true"); glass: (s.app && s.app.cfg.Light && s.app.cfg.Light.glass !== undefined) ? Number(s.app.cfg.Light.glass) / 100 : 1 } }
    description: "Cores claras com as mesmas transparências. Ícones pequenos da lateral ainda são feitos para o escuro."
    readonly property bool isOn: !!(app && app.cfg.Light && app.cfg.Light.enabled === "true")
    Toggle { app: s.app; group: "Light"; key: "enabled"; Kirigami.FormData.label: "Vidro claro:"; text: checked ? "ligado" : "desligado (escuro)" }
    ValueSlider { app: s.app; group: "Light"; key: "glass"; from: 20; to: 160; step: 5; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Opacidade da barra de título:" }
}
