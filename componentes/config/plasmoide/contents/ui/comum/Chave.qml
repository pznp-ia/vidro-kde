// Interruptor ligado a uma chave true/false do vidrorc.
import QtQuick
import QtQuick.Controls as QQC2
QQC2.Switch {
    id: c
    property var app
    property string grupo
    property string chave
    checked: !!(app && app.cfg[grupo] && String(app.cfg[grupo][chave]).toLowerCase() === "true")
    onToggled: app.definir(grupo, chave, checked ? "true" : "false")
}
