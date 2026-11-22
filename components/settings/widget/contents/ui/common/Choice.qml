// Option list bound to a vidrorc key. options: [{text: "...", value: "..."}]
import QtQuick
import QtQuick.Controls as QQC2
QQC2.ComboBox {
    id: e
    property var app
    property string group
    property string key
    property var options: []
    readonly property string current: (app && app.cfg[group]) ? String(app.cfg[group][key]) : ""
    model: options.map(o => o.text)
    currentIndex: Math.max(0, options.findIndex(o => o.value === current))
    onActivated: (i) => app.set(group, key, options[i].value)
}
