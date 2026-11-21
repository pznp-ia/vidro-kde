// Botão de cor ligado a uma chave #rrggbb do vidrorc.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
RowLayout {
    id: c
    property var app
    property string grupo
    property string chave
    readonly property string atual: (app && app.cfg[grupo] && app.cfg[grupo][chave]) ? String(app.cfg[grupo][chave]) : "#8ab4f8"
    QQC2.Button {
        implicitWidth: 64
        contentItem: Rectangle { radius: 4; color: c.atual; border.color: Qt.rgba(1, 1, 1, 0.25); implicitHeight: 18 }
        onClicked: dlg.open()
    }
    QQC2.Label { text: c.atual; opacity: 0.7 }
    ColorDialog {
        id: dlg
        selectedColor: c.atual
        onAccepted: c.app.definir(c.grupo, c.chave, String(selectedColor).slice(0, 7))
    }
}
