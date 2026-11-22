// Slider bound to a vidrorc key. Usage: ValueSlider { app: ...; group: "Scrollbar"; key: "width"; from: 2; to: 16; unit: "px" }
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
RowLayout {
    id: d
    property var app
    property string group
    property string key
    property real from: 0
    property real to: 100
    property real step: 1
    property string unit: ""
    readonly property real current: (app && app.cfg[group] && app.cfg[group][key] !== undefined) ? Number(app.cfg[group][key]) : from
    QQC2.Slider {
        id: sl
        Layout.fillWidth: true
        Layout.minimumWidth: 160
        from: d.from; to: d.to; stepSize: d.step; snapMode: QQC2.Slider.SnapAlways
        value: d.current
        onMoved: d.app.set(d.group, d.key, Math.round(value / d.step) * d.step)
    }
    QQC2.Label { text: (d.step < 1 ? sl.value.toFixed(1) : Math.round(sl.value)) + d.unit; Layout.minimumWidth: 44; opacity: 0.75; horizontalAlignment: Text.AlignRight }
}
