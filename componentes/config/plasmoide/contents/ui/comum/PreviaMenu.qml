// Exemplo: menu de clique direito (cantos, fundo, linhas, realce do item)
import QtQuick
import org.kde.kirigami as Kirigami
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property bool ativo: U.b(app, "Menus", "ativo", true)
    readonly property real raio: ativo ? U.n(app, "Menus", "raio", 12) : 8
    readonly property real esp: ativo ? U.n(app, "Menus", "espaco", 6) : 4
    readonly property real op: ativo ? U.n(app, "Menus", "opacidade", 92) / 100 : 1
    readonly property real sep: ativo ? U.n(app, "Menus", "separadores", 0) / 100 : 0.6
    readonly property real borda: ativo ? U.n(app, "Menus", "borda", 14) / 100 : 0.2
    readonly property real forca: ativo ? U.n(app, "Menus", "intensidade", 14) / 100 : 0.3
    readonly property color fundo: (ativo && U.v(app, "Menus", "fundo", "tema") === "cor") ? U.cor(U.v(app, "Menus", "cor_fundo", "#1c1e24")) : "#202326"
    readonly property color realce: {
        const m = U.v(app, "Menus", "realce", "vidro")
        if (!ativo) { const c = Kirigami.Theme.highlightColor; return Qt.rgba(c.r, c.g, c.b, 0.5) }
        if (m === "destaque") { const c = Kirigami.Theme.highlightColor; return Qt.rgba(c.r, c.g, c.b, Math.min(1, forca * 2.2)) }
        if (m === "cor") return U.cor(U.v(app, "Menus", "cor_realce", "#8ab4f8"), Math.min(1, forca * 2.2))
        return Qt.rgba(1, 1, 1, forca)
    }
    Fundo { anchors.fill: parent; app: r.app }
    Rectangle {
        id: menu
        anchors.centerIn: parent; width: 220; height: col.height + 2 * r.esp
        radius: r.raio
        color: Qt.rgba(r.fundo.r, r.fundo.g, r.fundo.b, r.op)
        border.color: Qt.rgba(1, 1, 1, r.borda); border.width: 1
        Behavior on radius { NumberAnimation { duration: 120 } }
        Column {
            id: col; x: r.esp; y: r.esp; width: parent.width - 2 * r.esp
            Repeater {
                model: ["Abrir", "Copiar", "Colar", "-", "Renomear…", "-", "Mover para a lixeira"]
                Item {
                    width: col.width; height: modelData === "-" ? 9 : 30
                    Rectangle { visible: modelData === "-"; anchors.centerIn: parent; width: parent.width - 8; height: 1; color: Qt.rgba(1, 1, 1, r.sep * 0.5) }
                    Rectangle { visible: index === 1; anchors.fill: parent; radius: Math.max(2, r.raio - r.esp); color: r.realce }
                    Text { visible: modelData !== "-"; text: modelData; x: 12; anchors.verticalCenter: parent.verticalCenter; color: "#eceef3"; font.pixelSize: 13 }
                }
            }
        }
    }
}
