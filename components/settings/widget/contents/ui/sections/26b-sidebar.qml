// Section: small sidebar icons (Dolphin, dialogs) — module icons.py
import QtQuick
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Ícones da lateral (Dolphin)"
    icon: "sidebar-show"
    preview: Component { PreviewSidebar { app: s.app } }
    description: "Os ícones pequenos de Início, Downloads, Lixeira etc. na lateral do Dolphin e dos diálogos de abrir/salvar. Reabra o Dolphin para ver o tamanho novo."
    function v(k) { return (app && app.cfg.Icons) ? String(app.cfg.Icons[k]) : "" }
    Choice { app: s.app; group: "Icons"; key: "sidebar_style"; Kirigami.FormData.label: "Estilo:"
        options: [ { text: "Linha", value: "line" }, { text: "Preenchido (ícone num quadrado)", value: "filled" }, { text: "Colorido (uma cor por local)", value: "colored" } ] }
    ColorButton { app: s.app; group: "Icons"; key: "sidebar_color"; visible: s.v("sidebar_style") !== "colored"; Kirigami.FormData.label: "Cor:" }
    ValueSlider { app: s.app; group: "Icons"; key: "sidebar_stroke"; from: 0.8; to: 2.2; step: 0.1; unit: ""; Kirigami.FormData.label: "Espessura do traço:" }
    Choice { app: s.app; group: "Icons"; key: "sidebar_size"; Kirigami.FormData.label: "Tamanho no Dolphin:"
        options: [ { text: "Automático", value: "auto" }, { text: "Pequeno (16 px)", value: "16" }, { text: "Médio (22 px)", value: "22" }, { text: "Grande (32 px)", value: "32" } ] }
}
