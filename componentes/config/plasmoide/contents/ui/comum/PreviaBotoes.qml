// Exemplo: barra de título com os botões (lado, ordem, estilo, tamanho, espaço, inativos)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property string estilo: U.v(app, "Botoes", "estilo", "semaforo")
    readonly property bool direita: U.v(app, "Botoes", "posicao", "esquerda") === "direita"
    readonly property bool windows: U.v(app, "Botoes", "ordem", "macos") === "windows"
    readonly property bool menu: U.b(app, "Botoes", "menu", false)
    readonly property real raio: U.n(app, "Botoes", "tamanho", 6.5) * 1.5
    readonly property real esp: U.n(app, "Botoes", "espaco", 2) * 1.5 + 6
    readonly property bool inatCor: U.v(app, "Botoes", "inativos", "cinza") === "cor"
    readonly property string unica: U.v(app, "Botoes", "cor", "semaforo") === "unica" ? U.v(app, "Botoes", "cor_unica", "#8ab4f8") : ""
    readonly property var ordem: windows ? ["min", "max", "fechar"] : ["fechar", "min", "max"]
    readonly property var cores: ({ fechar: "#ff5f57", min: "#febc2e", max: "#28c840" })
    Fundo { anchors.fill: parent; app: r.app }
    component Botao: Item {
        id: b
        property string tipo
        property bool ativa: true
        property bool hover: false
        width: r.raio * 2 + 4; height: width
        readonly property color cor: r.unica !== "" ? r.unica : r.cores[tipo]
        readonly property bool cinza: !ativa && !r.inatCor
        readonly property bool simbolo: hover || r.estilo === "simbolos" || r.estilo === "grafite" || r.estilo === "icones"
        Rectangle {
            anchors.centerIn: parent; width: r.raio * 2; height: width
            radius: r.estilo === "quadrado" ? width * 0.19 : width / 2
            visible: r.estilo !== "icones" || b.hover
            color: r.estilo === "contorno" && !b.hover ? "transparent"
                 : r.estilo === "icones" ? (b.tipo === "fechar" ? b.cor : Qt.rgba(1, 1, 1, 0.14))
                 : (r.estilo === "grafite" && !b.hover) ? Qt.rgba(1, 1, 1, b.cinza ? 0.12 : 0.28)
                 : b.cinza ? Qt.rgba(1, 1, 1, 0.16) : b.cor
            border.width: r.estilo === "contorno" && !b.hover ? 2 : 0.6
            border.color: r.estilo === "contorno" ? (b.cinza ? Qt.rgba(1, 1, 1, 0.45) : b.cor) : Qt.rgba(0, 0, 0, 0.3)
        }
        Text {
            anchors.centerIn: parent
            visible: b.simbolo && !(b.cinza && r.estilo === "semaforo")
            text: b.tipo === "fechar" ? "✕" : b.tipo === "min" ? "–" : (r.estilo === "icones" ? "□" : "⤢")
            font.pixelSize: r.raio * 1.2; font.bold: true
            color: (r.estilo === "grafite" && !b.hover) || r.estilo === "icones" ? (b.hover && b.tipo === "fechar" ? "white" : Qt.rgba(1, 1, 1, b.cinza ? 0.4 : 0.85)) : Qt.rgba(0, 0, 0, 0.6)
        }
    }
    component Janela: Rectangle {
        id: j
        property bool ativa: true
        property string titulo
        width: r.width * 0.42; height: r.height * 0.62
        radius: 10; color: Qt.rgba(0.13, 0.14, 0.16, 0.92); border.color: Qt.rgba(1, 1, 1, 0.08)
        Rectangle { width: parent.width; height: 34; radius: 10; color: Qt.rgba(1, 1, 1, j.ativa ? 0.06 : 0.03)
            Text { anchors.centerIn: parent; text: j.titulo; color: Qt.rgba(1, 1, 1, j.ativa ? 0.85 : 0.4); font.pixelSize: 12 }
            Row { spacing: r.esp; anchors.verticalCenter: parent.verticalCenter
                x: r.direita ? parent.width - width - 12 : 12
                Repeater { model: r.ordem; Botao { tipo: modelData; ativa: j.ativa; hover: j.ativa && index === (r.windows ? 2 : 0) && r.estilo !== "semaforo" } } }
            Text { visible: r.menu; text: "☰"; color: Qt.rgba(1, 1, 1, 0.7); font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter
                x: r.direita ? 12 : parent.width - width - 12 }
        }
        Column { x: 16; y: 50; spacing: 8; Repeater { model: 4; Rectangle { width: j.width * (0.7 - index * 0.1); height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.15) } } }
    }
    Janela { x: r.width * 0.06; y: r.height * 0.14; ativa: false; titulo: "Janela inativa" }
    Janela { x: r.width * 0.5; y: r.height * 0.22; ativa: true; titulo: "Janela ativa" }
}
