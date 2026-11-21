// Exemplo: menu iniciar (tipo, grade/lista, compacto, lateral à direita, rodapé)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property string tipo: U.v(app, "Lancador", "tipo", "kickoff")
    readonly property bool favLista: U.v(app, "Lancador", "favoritos", "0") === "1"
    readonly property bool compacto: U.b(app, "Lancador", "compacto", false)
    readonly property bool direita: U.b(app, "Lancador", "lateral_direita", false)
    readonly property int rodape: Number(U.v(app, "Lancador", "rodape", "0"))
    readonly property bool legendas: U.b(app, "Lancador", "legendas", true)
    readonly property real raio: U.b(app, "MenuIniciar", "ativo", true) ? U.n(app, "MenuIniciar", "raio", 14) : 6
    readonly property real op: U.b(app, "MenuIniciar", "ativo", true) ? U.n(app, "MenuIniciar", "opacidade", 80) / 100 : 0.85
    readonly property var cores: ["#5b8def", "#e5534b", "#3fb950", "#d29922", "#bc8cff", "#58a6ff", "#f0883e", "#8b949e"]
    Fundo { anchors.fill: parent; app: r.app }
    // barra de tarefas
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 22; color: Qt.rgba(0.1, 0.11, 0.13, 0.8)
        Rectangle { x: 8; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: "white"; opacity: 0.9 } }

    // ---- Kickoff ----
    Rectangle {
        visible: r.tipo === "kickoff"
        x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        width: parent.width * 0.62; height: parent.height - 40
        radius: r.raio; color: Qt.rgba(0.12, 0.13, 0.15, r.op); border.color: Qt.rgba(1, 1, 1, 0.1)
        Rectangle { x: 10; y: 8; width: parent.width - 20; height: 18; radius: 9; color: Qt.rgba(1, 1, 1, 0.08) }
        // lateral de categorias
        Column {
            x: r.direita ? parent.width - width - 10 : 10; y: 36; spacing: r.compacto ? 4 : 8; width: parent.width * 0.3
            Repeater { model: r.compacto ? 9 : 6; Rectangle { width: parent.width * (0.6 + (index % 3) * 0.12); height: r.compacto ? 6 : 9; radius: 3; color: index === 0 ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(1, 1, 1, 0.22) } }
        }
        // favoritos
        Item {
            x: r.direita ? 10 : parent.width * 0.36; y: 36; width: parent.width * 0.6; height: parent.height - 72
            Grid { visible: !r.favLista; columns: 3; spacing: 12
                Repeater { model: 6; Rectangle { width: 26; height: 26; radius: 7; color: r.cores[index]; opacity: 0.85 } } }
            Column { visible: r.favLista; spacing: r.compacto ? 5 : 9
                Repeater { model: r.compacto ? 7 : 5; Row { spacing: 6
                    Rectangle { width: r.compacto ? 10 : 14; height: width; radius: 4; color: r.cores[index] }
                    Rectangle { width: 70 + (index % 3) * 14; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.3); anchors.verticalCenter: parent.verticalCenter } } } }
        }
        // rodapé
        Row {
            anchors.bottom: parent.bottom; anchors.bottomMargin: 8; anchors.right: parent.right; anchors.rightMargin: 10; spacing: 8
            Repeater { model: r.rodape === 3 ? 6 : 3
                Row { spacing: 3
                    Rectangle { width: 10; height: 10; radius: 5; color: "transparent"; border.color: Qt.rgba(1, 1, 1, 0.7) }
                    Rectangle { visible: r.legendas; width: 24; height: 5; radius: 2; color: Qt.rgba(1, 1, 1, 0.35); anchors.verticalCenter: parent.verticalCenter } } }
        }
    }
    // ---- menu clássico ----
    Rectangle {
        visible: r.tipo === "classico"
        x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 28
        width: parent.width * 0.3; height: parent.height - 40
        radius: r.raio; color: Qt.rgba(0.12, 0.13, 0.15, r.op); border.color: Qt.rgba(1, 1, 1, 0.1)
        Column { x: 12; y: 12; spacing: 9
            Repeater { model: 10; Row { spacing: 6
                Rectangle { width: 10; height: 10; radius: 3; color: r.cores[index % 8] }
                Rectangle { width: 60 + (index % 4) * 10; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.3); anchors.verticalCenter: parent.verticalCenter } } } }
        Rectangle { anchors.bottom: parent.bottom; anchors.bottomMargin: 8; x: 10; width: parent.width - 20; height: 16; radius: 8; color: Qt.rgba(1, 1, 1, 0.08) }
    }
    // ---- tela cheia ----
    Rectangle {
        visible: r.tipo === "telacheia"
        anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.6)
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 14; width: 160; height: 16; radius: 8; color: Qt.rgba(1, 1, 1, 0.12) }
        Grid { anchors.centerIn: parent; columns: 7; spacing: 16
            Repeater { model: 21; Rectangle { width: 24; height: 24; radius: 7; color: r.cores[index % 8]; opacity: 0.85 } } }
    }
}
