// Text field bound to a vidrorc key (saved when editing finishes).
import QtQuick
import QtQuick.Controls as QQC2
QQC2.TextField {
    id: t
    property var app
    property string group
    property string key
    readonly property string current: (app && app.cfg[group] && app.cfg[group][key] !== undefined) ? String(app.cfg[group][key]) : ""
    text: current
    implicitWidth: 220
    onEditingFinished: if (text !== current) app.set(group, key, text)
}
