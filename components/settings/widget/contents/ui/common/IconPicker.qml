// Row of icon buttons bound to a vidrorc key (plus a field for any icon name).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
ColumnLayout {
    id: p
    property var app
    property string group
    property string key
    property var icons: []
    readonly property string current: (app && app.cfg[group] && app.cfg[group][key] !== undefined) ? String(app.cfg[group][key]) : ""
    Flow {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        spacing: 4
        Repeater {
            model: p.icons
            QQC2.ToolButton {
                icon.name: modelData; icon.width: Kirigami.Units.iconSizes.medium; icon.height: Kirigami.Units.iconSizes.medium
                checkable: true; checked: p.current === modelData
                QQC2.ToolTip.text: modelData; QQC2.ToolTip.visible: hovered
                onClicked: p.app.set(p.group, p.key, modelData)
            }
        }
    }
    QQC2.TextField {
        text: p.current; placeholderText: "nome de um ícone"; implicitWidth: Kirigami.Units.gridUnit * 14
        onEditingFinished: if (text !== p.current && text.trim() !== "") p.app.set(p.group, p.key, text.trim())
    }
}
