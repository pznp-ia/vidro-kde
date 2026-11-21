// Lista de opções ligada a uma chave do vidrorc. opcoes: [{texto: "...", valor: "..."}]
import QtQuick
import QtQuick.Controls as QQC2
QQC2.ComboBox {
    id: e
    property var app
    property string grupo
    property string chave
    property var opcoes: []
    readonly property string atual: (app && app.cfg[grupo]) ? String(app.cfg[grupo][chave]) : ""
    model: opcoes.map(o => o.texto)
    currentIndex: Math.max(0, opcoes.findIndex(o => o.valor === atual))
    onActivated: (i) => app.definir(grupo, chave, opcoes[i].valor)
}
