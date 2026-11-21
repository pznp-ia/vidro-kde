// Campo de texto ligado a uma chave do vidrorc (grava ao terminar de digitar).
import QtQuick
import QtQuick.Controls as QQC2
QQC2.TextField {
    id: t
    property var app
    property string grupo
    property string chave
    readonly property string atual: (app && app.cfg[grupo] && app.cfg[grupo][chave] !== undefined) ? String(app.cfg[grupo][chave]) : ""
    text: atual
    implicitWidth: 220
    onEditingFinished: if (text !== atual) app.definir(grupo, chave, text)
}
