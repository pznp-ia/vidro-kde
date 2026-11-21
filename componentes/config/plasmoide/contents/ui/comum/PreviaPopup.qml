// Exemplo: pop-up do painel / menu iniciar (cantos, vidro, linhas do cabeçalho, sombra)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property bool ativo: U.b(app, "MenuIniciar", "ativo", true)
    readonly property real raio: ativo ? U.n(app, "MenuIniciar", "raio", 14) : 6
    readonly property real op: ativo ? U.n(app, "MenuIniciar", "opacidade", 80) / 100 : 0.85
    readonly property real linhas: ativo ? U.n(app, "MenuIniciar", "linhas", 0) / 100 : 1
    readonly property real cab: ativo ? U.n(app, "MenuIniciar", "cabecalho", 0) / 100 : 1
    readonly property real borda: ativo ? U.n(app, "MenuIniciar", "borda", 10) / 100 : 0.2
    readonly property real sombra: ativo ? U.n(app, "MenuIniciar", "sombra", 55) / 100 : 0.5
    readonly property real tam: ativo ? U.n(app, "MenuIniciar", "tamanho", 18) : 16
    readonly property color vidro: (ativo && U.v(app, "MenuIniciar", "fundo", "tema") === "cor") ? U.cor(U.v(app, "MenuIniciar", "cor_vidro", "#1c1e24")) : "#202326"
    Fundo { anchors.fill: parent; app: r.app }
    Repeater { // sombra em camadas
        model: 6
        Rectangle {
            anchors.centerIn: pop; anchors.verticalCenterOffset: r.tam * 0.25
            width: pop.width + (index + 1) * r.tam / 3; height: pop.height + (index + 1) * r.tam / 3
            radius: r.raio + (index + 1) * r.tam / 6
            color: Qt.rgba(0, 0, 0, r.sombra * 0.09 * (6 - index) / 6)
        }
    }
    Rectangle {
        id: pop
        anchors.centerIn: parent; width: parent.width * 0.5; height: parent.height * 0.74
        radius: r.raio; clip: true
        color: Qt.rgba(r.vidro.r, r.vidro.g, r.vidro.b, r.op)
        border.color: Qt.rgba(1, 1, 1, r.borda)
        Rectangle { width: parent.width; height: 34; color: Qt.rgba(1, 1, 1, 0.05 * r.cab)
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.25 * r.linhas) }
            Rectangle { x: 10; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 20; height: 20; radius: 10; color: Qt.rgba(1, 1, 1, 0.08) } }
        Grid { x: 16; y: 48; columns: 4; spacing: 14
            Repeater { model: 8; Rectangle { width: 30; height: 30; radius: 8; color: ["#5b8def", "#e5534b", "#3fb950", "#d29922", "#bc8cff", "#58a6ff", "#f0883e", "#8b949e"][index]; opacity: 0.85 } } }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 30; color: Qt.rgba(1, 1, 1, 0.05 * r.cab)
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.25 * r.linhas) } }
    }
}
