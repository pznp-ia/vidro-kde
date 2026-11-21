// Slider ligado a uma chave do vidrorc. Uso: Deslizante { app: ...; grupo: "Barra"; chave: "largura"; de: 2; ate: 16; unidade: "px" }
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
RowLayout {
    id: d
    property var app
    property string grupo
    property string chave
    property real de: 0
    property real ate: 100
    property real passo: 1
    property string unidade: ""
    readonly property real atual: (app && app.cfg[grupo] && app.cfg[grupo][chave] !== undefined) ? Number(app.cfg[grupo][chave]) : de
    QQC2.Slider {
        id: sl
        Layout.fillWidth: true
        Layout.minimumWidth: 160
        from: d.de; to: d.ate; stepSize: d.passo; snapMode: QQC2.Slider.SnapAlways
        value: d.atual
        onMoved: d.app.definir(d.grupo, d.chave, Math.round(value / d.passo) * d.passo)
    }
    QQC2.Label { text: Math.round(sl.value) + d.unidade; Layout.minimumWidth: 44; opacity: 0.75; horizontalAlignment: Text.AlignRight }
}
