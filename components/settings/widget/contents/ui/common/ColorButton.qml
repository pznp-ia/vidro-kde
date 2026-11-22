// Color button bound to a #rrggbb key of vidrorc.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
RowLayout {
    id: c
    property var app
    property string group
    property string key
    readonly property string current: (app && app.cfg[group] && app.cfg[group][key]) ? String(app.cfg[group][key]) : "#8ab4f8"
    QQC2.Button {
        implicitWidth: 64
        contentItem: Rectangle { radius: 4; color: c.current; border.color: Qt.rgba(1, 1, 1, 0.25); implicitHeight: 18 }
        onClicked: dlg.open()
    }
    QQC2.Label { text: c.current; opacity: 0.7 }
    ColorDialog {
        id: dlg
        selectedColor: c.current
        onAccepted: c.app.set(c.group, c.key, String(selectedColor).slice(0, 7))
    }
}
