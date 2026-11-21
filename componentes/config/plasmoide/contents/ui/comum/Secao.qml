// Uma seção (aba) das Configurações do Vidro: exemplo ao vivo no topo + controles.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
ColumnLayout {
    id: s
    property var app
    property string titulo
    property string descricao
    property string icone: "preferences-desktop-theme"
    property Component previa: null          // exemplo desenhado que reage aos valores na hora
    default property alias conteudo: form.data
    spacing: Kirigami.Units.largeSpacing
    Kirigami.Heading { text: s.titulo; level: 2; Layout.leftMargin: Kirigami.Units.largeSpacing; Layout.topMargin: Kirigami.Units.largeSpacing }
    QQC2.Label {
        visible: s.descricao !== ""; text: s.descricao; wrapMode: Text.WordWrap; opacity: 0.65
        Layout.fillWidth: true; Layout.leftMargin: Kirigami.Units.largeSpacing; Layout.rightMargin: Kirigami.Units.largeSpacing
    }
    Rectangle {
        visible: s.previa !== null
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.largeSpacing; Layout.rightMargin: Kirigami.Units.largeSpacing
        Layout.preferredHeight: Kirigami.Units.gridUnit * 13
        radius: 12
        clip: true
        color: Qt.rgba(0, 0, 0, 0.25)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        Loader { anchors.fill: parent; anchors.margins: 1; sourceComponent: s.previa }
        QQC2.Label { text: "exemplo"; opacity: 0.45; font.pointSize: Kirigami.Theme.smallFont.pointSize; anchors { right: parent.right; bottom: parent.bottom; margins: 8 } }
    }
    Kirigami.FormLayout { id: form; Layout.fillWidth: true }
}
