/*
    Vidro — substitui o WallpaperFader do Breeze.
    Em vez de animar o raio do desfoque (pesado, engasga), desfoca uma vez só e
    faz um crossfade de opacidade entre o papel de parede nítido e o desfocado.
    O conteúdo (cartão, rodapé, relógio) entra/sai com curvas suaves.
*/
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Item {
    id: fader
    property Item clock
    property Item mainStack
    property Item footer
    property Item source
    property bool alwaysShowClock: false
    property bool blurOn: true

    readonly property int duracao: Kirigami.Units.veryLongDuration * 1.6   // ~400-500 ms
    property real fator: 0          // 0 = idle, 1 = card open

    state: "on"

    MultiEffect {
        id: desfocado
        anchors.fill: parent
        source: fader.source
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        saturation: 0.15
        brightness: -0.10
        opacity: fader.blurOn ? fader.fator : 0
        visible: opacity > 0.001
    }

    states: [
        State {
            name: "on"
            PropertyChanges { target: fader; fator: 1 }
            PropertyChanges { target: fader.mainStack; opacity: 1; scale: 1 }
            PropertyChanges { target: fader.footer; opacity: 1 }
            PropertyChanges { target: fader.clock; opacity: 1 }
        },
        State {
            name: "off"
            PropertyChanges { target: fader; fator: 0 }
            PropertyChanges { target: fader.mainStack; opacity: 0; scale: 0.985 }
            PropertyChanges { target: fader.footer; opacity: 0 }
            PropertyChanges { target: fader.clock; opacity: fader.alwaysShowClock ? 1 : 0 }
        }
    ]
    transitions: [
        Transition {
            from: "off"; to: "on"
            ParallelAnimation {
                NumberAnimation { target: fader; property: "fator"; duration: fader.duracao * 1.2; easing.type: Easing.OutCubic }
                NumberAnimation { targets: [fader.mainStack, fader.footer]; property: "opacity"; duration: fader.duracao; easing.type: Easing.OutCubic }
                NumberAnimation { target: fader.mainStack; property: "scale"; duration: fader.duracao * 1.2; easing.type: Easing.OutCubic }
                NumberAnimation { target: fader.clock; property: "opacity"; duration: fader.duracao; easing.type: Easing.OutCubic }
            }
        },
        Transition {
            from: "on"; to: "off"
            ParallelAnimation {
                NumberAnimation { target: fader; property: "fator"; duration: fader.duracao * 1.4; easing.type: Easing.InOutCubic }
                NumberAnimation { targets: [fader.mainStack, fader.footer]; property: "opacity"; duration: fader.duracao * 0.8; easing.type: Easing.InOutCubic }
                NumberAnimation { target: fader.mainStack; property: "scale"; duration: fader.duracao; easing.type: Easing.InOutCubic }
                NumberAnimation { target: fader.clock; property: "opacity"; duration: fader.duracao; easing.type: Easing.InOutCubic }
            }
        }
    ]
}
