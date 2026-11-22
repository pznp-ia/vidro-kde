// Section: taskbar show/hide animation studio (module panelanim.py → KWin effect vidro_panel)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Barra: aparecer e sumir"
    icon: "view-hidden"
    description: "Animação da barra de tarefas quando ela se esconde sozinha. Só aparece com \"Esconder a barra\" ligado (abaixo ou em Barra de tarefas). Muda na hora."
    preview: Component { PreviewPanelAnim { app: s.app } }
    function v(k) { return (app && app.cfg.PanelAnimation) ? String(app.cfg.PanelAnimation[k]) : "" }
    readonly property var styles: [ { text: "Deslizar da borda", value: "slide" }, { text: "Esmaecer", value: "fade" },
        { text: "Deslizar + esmaecer", value: "slidefade" }, { text: "Encolher/crescer", value: "scale" },
        { text: "Subir crescendo (tudo junto)", value: "rise" }, { text: "Nenhuma", value: "none" } ]

    Toggle { app: s.app; group: "PanelAnimation"; key: "enabled"; Kirigami.FormData.label: "Animação:"; text: checked ? "ligada" : "desligada (some de uma vez)" }
    Choice { app: s.app; group: "Panel"; key: "hiding"; Kirigami.FormData.label: "Esconder a barra:"
        options: [ { text: "Nunca", value: "none" }, { text: "Sempre (aparece ao encostar o mouse)", value: "autohide" },
                   { text: "Quando uma janela encostar", value: "dodgewindows" }, { text: "Janelas podem cobrir", value: "windowsgobelow" } ] }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Aparecer" }
    Choice { app: s.app; group: "PanelAnimation"; key: "show_style"; enabled: s.v("enabled") === "true"; Kirigami.FormData.label: "Estilo:"; options: s.styles }
    ValueSlider { app: s.app; group: "PanelAnimation"; key: "show_ms"; from: 50; to: 1000; step: 10; unit: " ms"; enabled: s.v("enabled") === "true"; Kirigami.FormData.label: "Duração:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Sumir" }
    Choice { app: s.app; group: "PanelAnimation"; key: "hide_style"; enabled: s.v("enabled") === "true"; Kirigami.FormData.label: "Estilo:"; options: s.styles }
    ValueSlider { app: s.app; group: "PanelAnimation"; key: "hide_ms"; from: 50; to: 1000; step: 10; unit: " ms"; enabled: s.v("enabled") === "true"; Kirigami.FormData.label: "Duração:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Movimento" }
    Choice { app: s.app; group: "PanelAnimation"; key: "curve"; enabled: s.v("enabled") === "true"; Kirigami.FormData.label: "Curva:"
        options: [ { text: "Suave", value: "smooth" }, { text: "Ágil", value: "snappy" }, { text: "Mola", value: "spring" }, { text: "Linear", value: "linear" } ] }
    ValueSlider { app: s.app; group: "PanelAnimation"; key: "distance"; from: 10; to: 150; step: 5; unit: "%"; enabled: s.v("enabled") === "true"; Kirigami.FormData.label: "Distância do deslize:" }
    ValueSlider { app: s.app; group: "PanelAnimation"; key: "scale"; from: 50; to: 100; unit: "%"; enabled: s.v("enabled") === "true"; Kirigami.FormData.label: "Tamanho inicial (encolher):" }
}
