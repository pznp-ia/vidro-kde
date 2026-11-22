// Section: EditorKden (module ~/.local/share/vidro/modules/editorkden.py)
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "EditorKden (Kdenlive)"
    icon: "kdenlive"
    preview: Component { PreviewSimple { app: s.app; accent: (s.app && s.app.cfg.EditorKden && s.app.cfg.EditorKden.accent) ? s.app.cfg.EditorKden.accent : "#0a84ff"; radius: (s.app && s.app.cfg.EditorKden && s.app.cfg.EditorKden.radius !== undefined) ? Number(s.app.cfg.EditorKden.radius) : 10 } }
    description: "Kdenlive com visual minimalista inspirado no macOS, com configuração própria (o Kdenlive normal não muda). Abra pelo menu: EditorKden."
    readonly property bool isOn: !!(app && app.cfg.EditorKden && app.cfg.EditorKden.enabled === "true")
    Toggle { app: s.app; group: "EditorKden"; key: "enabled"; Kirigami.FormData.label: "EditorKden:"; text: checked ? "instalado no menu" : "desligado" }
    ColorButton { app: s.app; group: "EditorKden"; key: "accent"; enabled: s.isOn; Kirigami.FormData.label: "Cor de destaque:" }
    ValueSlider { app: s.app; group: "EditorKden"; key: "darkness"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Claridade do grafite:" }
    ValueSlider { app: s.app; group: "EditorKden"; key: "contrast"; unit: "%"; enabled: s.isOn; Kirigami.FormData.label: "Contraste dos painéis:" }
    ValueSlider { app: s.app; group: "EditorKden"; key: "radius"; from: 0; to: 16; unit: " px"; enabled: s.isOn; Kirigami.FormData.label: "Arredondamento:" }
    ValueSlider { app: s.app; group: "EditorKden"; key: "font_size"; from: 8; to: 14; unit: " pt"; enabled: s.isOn; Kirigami.FormData.label: "Tamanho da letra:" }
    Toggle { app: s.app; group: "EditorKden"; key: "dock_titles"; enabled: s.isOn; Kirigami.FormData.label: "Títulos dos painéis:"; text: checked ? "visíveis" : "escondidos" }
    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Visual" }
    Choice { app: s.app; group: "EditorKden"; key: "style"; enabled: s.isOn; Kirigami.FormData.label: "Abas e botões:"
        options: [ { text: "Pílulas e botões planos", value: "pill" }, { text: "Padrão", value: "default" } ] }
    Toggle { app: s.app; group: "EditorKden"; key: "toolbar_labels"; enabled: s.isOn; Kirigami.FormData.label: "Texto nos botões da barra:"; text: checked ? "mostrar" : "só ícones" }
    Toggle { app: s.app; group: "EditorKden"; key: "menubar"; enabled: s.isOn; Kirigami.FormData.label: "Barra de menus:"; text: checked ? "mostrar" : "esconder (Ctrl+M mostra)" }
    Toggle { app: s.app; group: "EditorKden"; key: "statusbar"; enabled: s.isOn; Kirigami.FormData.label: "Barra de status:"; text: checked ? "mostrar" : "esconder" }
    Choice { app: s.app; group: "EditorKden"; key: "clips"; enabled: s.isOn; Kirigami.FormData.label: "Cor dos clipes:"
        options: [ { text: "Tons suaves", value: "soft" }, { text: "Da cor de destaque", value: "accent" }, { text: "Do Kdenlive", value: "theme" } ] }
    Choice { app: s.app; group: "EditorKden"; key: "waveform"; enabled: s.isOn; Kirigami.FormData.label: "Forma de onda do áudio:"
        options: [ { text: "Cor de destaque", value: "accent" }, { text: "Verde do Kdenlive", value: "default" } ] }
    Choice { app: s.app; group: "EditorKden"; key: "monitor"; enabled: s.isOn; Kirigami.FormData.label: "Fundo do monitor:"
        options: [ { text: "Grafite", value: "graphite" }, { text: "Preto", value: "black" } ] }
    QQC2.Label { Kirigami.FormData.label: ""; text: "Feche o EditorKden antes de mudar: ao fechar, ele grava as próprias configurações por cima."; wrapMode: Text.WordWrap; opacity: 0.6; Layout.maximumWidth: Kirigami.Units.gridUnit * 24 }
    Toggle { app: s.app; group: "EditorKden"; key: "welcome"; enabled: s.isOn; Kirigami.FormData.label: "Tela de boas-vindas:"; text: checked ? "mostrar" : "abrir direto no editor" }
}
