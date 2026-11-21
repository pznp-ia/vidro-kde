// Exemplo: tela de login (fundo, escurecer, relógio, avatar, pílula de senha, posição)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property real esc: U.n(app, "Login", "escurecer", 30) / 100
    readonly property bool esquerda: U.v(app, "Login", "posicao", "centro") === "esquerda"
    readonly property bool h12: U.v(app, "Login", "relogio", "24h") === "12h"
    readonly property bool seg: U.b(app, "Login", "segundos", false)
    readonly property real tam: U.n(app, "Login", "tamanho", 100) / 100
    readonly property string peso: U.v(app, "Login", "peso", "ExtraLight")
    readonly property bool comData: U.b(app, "Login", "data", true)
    readonly property bool relogio: U.b(app, "Login", "mostrar_relogio", true)
    readonly property color destaque: U.cor(U.v(app, "Login", "destaque", "#ffffff"))
    readonly property real vidro: U.n(app, "Login", "vidro", 8) / 100
    readonly property bool avatar: U.b(app, "Login", "avatar", true)
    readonly property bool quadrado: U.v(app, "Login", "forma_avatar", "circulo") === "quadrado"
    readonly property string fonte: U.v(app, "Login", "fonte", "Noto Sans")
    property date agora: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: r.agora = new Date() }
    Image {   // o fundo de verdade, já montado pelo módulo
        anchors.fill: parent; fillMode: Image.PreserveAspectCrop; cache: false; asynchronous: true
        source: (r.app && r.app.home) ? "file://" + r.app.home + "/.local/share/vidro/login/tema/" + (U.b(r.app, "Login", "desfoque", true) ? "fundo-desfocado.jpg" : "fundo.jpg") + "?v=" + r.app.versao : ""
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, r.esc) }
    readonly property real u: height / 26
    Column {
        visible: r.relogio
        x: r.esquerda ? r.width * 0.08 : (r.width - width) / 2; y: r.height * 0.08
        Text { anchors.horizontalCenter: r.esquerda ? undefined : parent.horizontalCenter
            text: Qt.formatTime(r.agora, (r.h12 ? "h:mm" : "HH:mm") + (r.seg ? ":ss" : "") + (r.h12 ? " AP" : ""))
            color: "#f4f6fa"; font.family: r.fonte; font.pixelSize: r.u * 4.2 * r.tam
            font.weight: ({ "ExtraLight": Font.ExtraLight, "Light": Font.Light, "Normal": Font.Normal, "DemiBold": Font.DemiBold, "Bold": Font.Bold })[r.peso] || Font.ExtraLight }
        Text { visible: r.comData; anchors.horizontalCenter: r.esquerda ? undefined : parent.horizontalCenter
            text: ["Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"][r.agora.getDay()] + ", " + r.agora.getDate() + " de " + ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"][r.agora.getMonth()]; color: Qt.rgba(1, 1, 1, 0.72); font.family: r.fonte; font.pixelSize: r.u * 0.8 }
    }
    Column {
        x: r.esquerda ? r.width * 0.08 : (r.width - width) / 2; y: r.height * 0.45
        spacing: r.u * 0.5
        Rectangle { visible: r.avatar; anchors.horizontalCenter: parent.horizontalCenter; width: r.u * 3.4; height: width
            radius: r.quadrado ? width * 0.24 : width / 2; color: Qt.rgba(1, 1, 1, 0.16); border.color: Qt.rgba(1, 1, 1, 0.3)
            Text { anchors.centerIn: parent; text: "U"; color: "white"; font.pixelSize: parent.width * 0.45; font.weight: Font.Light } }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Usuário"; color: "#f4f6fa"; font.family: r.fonte; font.pixelSize: r.u * 0.9 }
        Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: r.u * 0.3
            Rectangle { width: r.u * 8; height: r.u * 1.4; radius: height / 2; color: Qt.rgba(1, 1, 1, r.vidro + 0.04)
                border.color: Qt.rgba(r.destaque.r, r.destaque.g, r.destaque.b, 0.55)
                Text { x: r.u * 0.6; anchors.verticalCenter: parent.verticalCenter; text: "Senha"; color: Qt.rgba(1, 1, 1, 0.45); font.pixelSize: r.u * 0.6 } }
            Rectangle { width: r.u * 1.4; height: width; radius: width / 2; color: Qt.rgba(r.destaque.r, r.destaque.g, r.destaque.b, 0.3)
                Text { anchors.centerIn: parent; text: "→"; color: "white"; font.pixelSize: r.u * 0.6 } } }
    }
}
