/*
    Vidro — botão de ação redondo de vidro com legenda discreta.
*/
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.AbstractButton {
    id: botao

    property real tamanho: Kirigami.Units.gridUnit * 2.6
    property bool legenda: true

    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    implicitWidth: Math.max(tamanho, rotulo.implicitWidth)
    implicitHeight: tamanho + (legenda ? rotulo.implicitHeight + Kirigami.Units.smallSpacing * 2 : 0)

    Kirigami.MnemonicData.enabled: botao.enabled && botao.visible
    Kirigami.MnemonicData.controlType: Kirigami.MnemonicData.SecondaryControl
    Kirigami.MnemonicData.label: botao.text

    Accessible.name: rotulo.text
    Keys.onEnterPressed: clicked()
    Keys.onReturnPressed: clicked()

    background: Item {}
    contentItem: Item {
        Rectangle {
            id: circulo
            anchors.horizontalCenter: parent.horizontalCenter
            width: botao.tamanho
            height: width
            radius: width / 2
            color: Qt.rgba(1, 1, 1, botao.down ? 0.22 : (botao.hovered || botao.activeFocus ? 0.15 : 0.07))
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, botao.activeFocus ? 0.45 : (botao.hovered ? 0.26 : 0.13))
            scale: botao.down ? 0.94 : 1
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
            Behavior on scale { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Math.round(botao.tamanho * 0.42)
                height: width
                source: botao.icon.name
                color: "#f4f6fa"
                isMask: true
            }
        }
        Text {
            id: rotulo
            visible: botao.legenda
            anchors.top: circulo.bottom
            anchors.topMargin: Kirigami.Units.smallSpacing * 1.5
            anchors.horizontalCenter: parent.horizontalCenter
            text: botao.text.replace(/&(?!&)/g, "")
            color: Qt.rgba(0.96, 0.97, 0.98, botao.hovered || botao.activeFocus ? 0.95 : 0.62)
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.letterSpacing: 0.3
            Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
        }
    }
}
