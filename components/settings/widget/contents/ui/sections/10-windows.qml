// Section: window transparency (effect vidro_opacity, command vidro-opacity)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Janelas"
    icon: "window"
    preview: Component { PreviewWindow { app: s.app } }
    description: "Transparência (0 = opacas; 100 = ativa 75%, inativas 60%) e cor da barra de título. Mudam na hora."
    RowLayout {
        Kirigami.FormData.label: "Transparência:"
        QQC2.Slider {
            id: sl; Layout.fillWidth: true; Layout.minimumWidth: 160
            from: 0; to: 100; stepSize: 5; snapMode: QQC2.Slider.SnapAlways
            value: (s.app && s.app.cfg.Windows && s.app.cfg.Windows.opacity !== undefined) ? Number(s.app.cfg.Windows.opacity) : 50
            onMoved: apply.restart()
            Timer { id: apply; interval: 120; onTriggered: s.app.run("$HOME/.local/bin/vidro-opacity " + Math.round(sl.value)) }
        }
        QQC2.Label { text: Math.round(sl.value) + "%"; Layout.minimumWidth: 44; opacity: 0.75; horizontalAlignment: Text.AlignRight }
    }
    Choice {
        app: s.app; group: "Windows"; key: "titlebar"
        Kirigami.FormData.label: "Cor da barra de título:"
        options: [ { text: "Automática (pelo papel de parede)", value: "theme" }, { text: "Cor personalizada", value: "custom" } ]
    }
    ColorButton { app: s.app; group: "Windows"; key: "titlebar_color"; visible: !!(s.app && s.app.cfg.Windows && s.app.cfg.Windows.titlebar === "custom"); Kirigami.FormData.label: "Cor:" }
}
