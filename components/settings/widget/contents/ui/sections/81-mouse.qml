// Section: mouse and touchpad (module mouse.py → KWin input devices + kcminputrc, kdeglobals, KWin effects)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Mouse"
    icon: "preferences-desktop-mouse"
    preview: Component { PreviewCursor { app: s.app } }
    description: "Velocidade, rolagem, botões e ajudas para achar o cursor. Vale na hora para todos os mouses conectados (e fica salvo)."
    function v(k) { return (app && app.cfg.Mouse) ? String(app.cfg.Mouse[k]) : "" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Movimento" }
    ValueSlider { app: s.app; group: "Mouse"; key: "speed"; from: -100; to: 100; step: 5; Kirigami.FormData.label: "Velocidade:" }
    Choice { app: s.app; group: "Mouse"; key: "profile"; Kirigami.FormData.label: "Aceleração:"
        options: [ { text: "Constante (melhor para jogos)", value: "flat" }, { text: "Adaptativa (mais rápido quando move rápido)", value: "adaptive" } ] }
    Toggle { app: s.app; group: "Mouse"; key: "left_handed"; Kirigami.FormData.label: "Canhoto:"; text: checked ? "botões trocados" : "não" }
    Toggle { app: s.app; group: "Mouse"; key: "middle_emulation"; Kirigami.FormData.label: "Clique do meio:"; text: checked ? "esquerdo + direito juntos" : "só a rodinha" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Rolagem e cliques" }
    ValueSlider { app: s.app; group: "Mouse"; key: "scroll_speed"; from: 20; to: 300; step: 10; unit: "%"; Kirigami.FormData.label: "Velocidade da rodinha:" }
    ValueSlider { app: s.app; group: "Mouse"; key: "wheel_lines"; from: 1; to: 12; unit: " linhas"; Kirigami.FormData.label: "Linhas por passo:" }
    Toggle { app: s.app; group: "Mouse"; key: "natural_scroll"; Kirigami.FormData.label: "Rolagem natural:"; text: checked ? "sim (como no celular)" : "não" }
    ValueSlider { app: s.app; group: "Mouse"; key: "double_click_ms"; from: 150; to: 900; step: 10; unit: " ms"; Kirigami.FormData.label: "Tempo do clique duplo:" }
    Rectangle {
        Kirigami.FormData.label: "Teste o clique duplo:"
        implicitWidth: Kirigami.Units.gridUnit * 10; implicitHeight: Kirigami.Units.gridUnit * 2; radius: 6
        property bool hit: false
        color: hit ? Qt.rgba(0.24, 0.73, 0.31, 0.35) : Qt.rgba(1, 1, 1, 0.06)
        QQC2.Label { anchors.centerIn: parent; text: parent.hit ? "clique duplo!" : "clique duas vezes aqui" }
        Timer { id: hitOff; interval: 900; onTriggered: parent.hit = false }
        MouseArea { anchors.fill: parent; onDoubleClicked: { parent.hit = true; hitOff.restart(); } }
    }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Touchpad" }
    Toggle { app: s.app; group: "Mouse"; key: "touchpad_tap"; Kirigami.FormData.label: "Tocar para clicar:"; text: checked ? "sim" : "não" }
    Toggle { app: s.app; group: "Mouse"; key: "touchpad_natural"; Kirigami.FormData.label: "Rolagem natural:"; text: checked ? "sim" : "não" }
    ValueSlider { app: s.app; group: "Mouse"; key: "touchpad_speed"; from: -100; to: 100; step: 5; Kirigami.FormData.label: "Velocidade:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Achar o cursor" }
    Toggle { app: s.app; group: "Mouse"; key: "shake_find"; Kirigami.FormData.label: "Sacudir para achar:"; text: checked ? "o cursor cresce ao sacudir o mouse" : "desligado" }
    Toggle { app: s.app; group: "Mouse"; key: "click_highlight"; Kirigami.FormData.label: "Mostrar cliques:"; text: checked ? "círculos onde você clica" : "não" }
    Toggle { app: s.app; group: "Mouse"; key: "hide_idle"; Kirigami.FormData.label: "Esconder parado:"; text: checked ? "sim" : "não" }
    ValueSlider { app: s.app; group: "Mouse"; key: "hide_seconds"; from: 1; to: 30; unit: " s"; visible: s.v("hide_idle") === "true"; Kirigami.FormData.label: "Esconder depois de:" }
    Toggle { app: s.app; group: "Mouse"; key: "hide_typing"; Kirigami.FormData.label: "Esconder ao digitar:"; text: checked ? "sim" : "não" }
}
