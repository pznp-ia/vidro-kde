// Exemplo: barra de tarefas (altura, flutuante, posição, alinhamento, vidro, ícones, relógio)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property real alt: Math.max(18, U.n(app, "Painel", "altura", 44) * 0.6)
    readonly property bool flut: U.b(app, "Painel", "flutuante", true)
    readonly property string pos: U.v(app, "Painel", "posicao", "bottom")
    readonly property bool horiz: pos === "bottom" || pos === "top"
    readonly property bool encaixa: U.v(app, "Painel", "largura", "fill") === "fit"
    readonly property string alin: U.v(app, "Painel", "alinhamento", "center")
    readonly property bool vidro: U.b(app, "Painel", "vidro_ativo", false)
    readonly property real raio: vidro ? U.n(app, "Painel", "vidro_raio", 6) : 6
    readonly property real op: vidro ? U.n(app, "Painel", "vidro_opacidade", 42) / 100 : (U.v(app, "Painel", "opacidade", "translucent") === "opaque" ? 0.95 : 0.42)
    readonly property real contorno: vidro ? U.n(app, "Painel", "vidro_contorno", 0) / 100 : 0
    readonly property color corVidro: (vidro && U.v(app, "Painel", "vidro_fundo", "tema") === "cor") ? U.cor(U.v(app, "Painel", "vidro_cor", "#1c1e24")) : "#202326"
    readonly property real esp: 4 + U.n(app, "Painel", "espaco_icones", 1) * 4
    readonly property int seg: Number(U.v(app, "Painel", "segundos", "1"))
    readonly property bool comData: U.b(app, "Painel", "data", true)
    readonly property int horas: Number(U.v(app, "Painel", "horas", "1"))
    readonly property bool negrito: U.b(app, "Painel", "negrito", false)
    readonly property var cores: ["#5b8def", "#e5534b", "#3fb950", "#d29922", "#bc8cff", "#58a6ff"]
    property date agora: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: r.agora = new Date() }
    Fundo { anchors.fill: parent; app: r.app }
    readonly property real m: flut ? 8 : 0
    Rectangle {
        id: barra
        readonly property real comp: r.encaixa ? conteudo.implicitWidth + 20 : (r.horiz ? r.width - 2 * r.m : r.height - 2 * r.m)
        width: r.horiz ? comp : r.alt
        height: r.horiz ? r.alt : comp
        x: r.pos === "left" ? r.m : r.pos === "right" ? r.width - width - r.m
           : r.alin === "left" ? r.m : r.alin === "right" ? r.width - width - r.m : (r.width - width) / 2
        y: r.pos === "top" ? r.m : r.pos === "bottom" ? r.height - height - r.m
           : r.alin === "left" ? r.m : r.alin === "right" ? r.height - height - r.m : (r.height - height) / 2
        radius: r.flut || r.vidro ? r.raio : 0
        color: Qt.rgba(r.corVidro.r, r.corVidro.g, r.corVidro.b, r.op)
        border.color: Qt.rgba(1, 1, 1, r.contorno)
        Flow {
            id: conteudo
            anchors.fill: parent; anchors.margins: 6
            flow: r.horiz ? Flow.LeftToRight : Flow.TopToBottom
            spacing: r.esp
            Rectangle { width: r.alt - 12; height: width; radius: width / 2; color: "white"; opacity: 0.9 }
            Repeater { model: 5; Rectangle { width: r.alt - 12; height: width; radius: 5; color: r.cores[index]; opacity: 0.9 } }
            Text {
                visible: r.horiz
                color: "white"; font.pixelSize: Math.max(9, r.alt * 0.34); font.bold: r.negrito
                text: Qt.formatTime(r.agora, (r.horas === 0 ? "h:mm" : "HH:mm") + (r.seg === 2 ? ":ss" : "") + (r.horas === 0 ? " AP" : ""))
                      + (r.comData ? "  " + Qt.formatDate(r.agora, "dd/MM/yyyy") : "")
            }
        }
    }
}
