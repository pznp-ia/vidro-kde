// Switch bound to a true/false vidrorc key.
import QtQuick
import QtQuick.Controls as QQC2
QQC2.Switch {
    id: c
    property var app
    property string group
    property string key
    checked: !!(app && app.cfg[group] && String(app.cfg[group][key]).toLowerCase() === "true")
    onToggled: app.set(group, key, checked ? "true" : "false")
}
