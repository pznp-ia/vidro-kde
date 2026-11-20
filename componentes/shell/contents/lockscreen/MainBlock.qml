/*
    Vidro — bloco central da tela de bloqueio.
    Mesma API do MainBlock original do Plasma (senha, PAM, digital, smartcard),
    visual minimalista: avatar redondo, nome e campo de senha em pílula de vidro.
*/
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Effects

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker

import org.kde.breeze.components

FocusScope {
    id: sessionManager

    // ---- API usada por LockScreenUi.qml ----
    property alias passwordInputVisible: passwordLayout.visible
    readonly property alias mainPasswordBox: passwordBox
    property bool lockScreenUiVisible: false
    property alias showPassword: passwordBox.showPassword
    property alias notificationMessage: notificationsLabel.text
    property alias actionItems: actionItemsLayout.children
    property alias actionItemsVisible: actionItemsLayout.visible
    property var userListModel
    property bool showUserList: true
    property alias userList: userBlock
    property Item authenticationTypeItem: null
    default property alias _children: extraLayout.children

    // ponto que precisa ficar visível acima do teclado virtual
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + Kirigami.Units.smallSpacing

    signal passwordResult(string password)
    signal userSelected()

    function playHighlightAnimation() { bounceAnimation.start(); }

    function startLogin() {
        const password = passwordBox.text
        loginButton.forceActiveFocus();
        passwordResult(password);
    }

    readonly property var usuario: (userListModel && userListModel.count > 0) ? userListModel.get(0) : null

    ColumnLayout {
        id: coluna
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 19)
        anchors.horizontalCenter: parent.horizontalCenter
        // centro um pouco abaixo do meio, deixando o relógio respirar em cima
        y: Math.round(parent.height * 0.52 - userBlock.height)
        spacing: 0

        // ---------- avatar + nome ----------
        Item {
            id: userBlock
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Kirigami.Units.gridUnit * 5.2
            implicitHeight: implicitWidth
            visible: sessionManager.showUserList
            property int currentIndex: 0
            function incrementCurrentIndex() {}
            function decrementCurrentIndex() {}

            // anel de vidro
            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.20)
            }
            Image {
                id: face
                anchors.fill: parent
                source: sessionManager.usuario ? sessionManager.usuario.icon : ""
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectCrop
                visible: false
                layer.enabled: true
            }
            Rectangle {
                id: mascara
                anchors.fill: parent
                radius: width / 2
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                source: face
                maskEnabled: true
                maskSource: mascara
                visible: face.status === Image.Ready
            }
            Kirigami.Icon {
                anchors.fill: parent
                anchors.margins: parent.width * 0.18
                source: "user-identity"
                color: "#f4f6fa"
                isMask: true
                visible: face.status !== Image.Ready
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.gridUnit * 0.9
            visible: sessionManager.showUserList
            text: sessionManager.usuario ? (sessionManager.usuario.realName || sessionManager.usuario.name) : ""
            color: "#f4f6fa"
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
            font.weight: Font.Light
            font.letterSpacing: 0.4
            textFormat: Text.PlainText
        }

        // ---------- mensagens (caps lock, falha, PAM) ----------
        Text {
            id: notificationsLabel
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            Layout.preferredHeight: Math.max(implicitHeight, Kirigami.Units.gridUnit * 1.2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            color: Qt.rgba(1, 0.86, 0.78, 0.92)
            font.pointSize: Kirigami.Theme.smallFont.pointSize + 1
            opacity: text.length > 0 ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Kirigami.Units.longDuration } }

            SequentialAnimation {
                id: bounceAnimation
                NumberAnimation { target: notificationsLabel; property: "scale"; from: 1; to: 1.08; duration: Kirigami.Units.longDuration; easing.type: Easing.OutQuad }
                NumberAnimation { target: notificationsLabel; property: "scale"; from: 1.08; to: 1; duration: Kirigami.Units.longDuration; easing.type: Easing.InQuad }
            }
        }

        // tipo de autenticação (senha / digital), só aparece se houver mais de um
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.smallSpacing
            visible: sessionManager.authenticationTypeItem !== null
            children: [sessionManager.authenticationTypeItem]
        }

        // ---------- senha ----------
        RowLayout {
            id: passwordLayout
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing * 2

            // espaçador do mesmo tamanho do botão → pílula fica centralizada
            Item { Layout.preferredWidth: loginButton.Layout.preferredWidth; visible: passwordLayout.width > Kirigami.Units.gridUnit * 14 }

            PlasmaExtras.PasswordField {
                id: passwordBox
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.3
                font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
                leftPadding: Kirigami.Units.gridUnit
                color: "#f4f6fa"
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.45)
                selectionColor: Qt.rgba(1, 1, 1, 0.30)
                selectedTextColor: "#ffffff"
                text: PasswordSync.password
                placeholderText: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:placeholder in text field", "Password")
                focus: true
                cursorVisible: visible

                background: Rectangle {
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, passwordBox.activeFocus ? 0.12 : 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, passwordBox.activeFocus ? 0.34 : 0.16)
                    Behavior on color { ColorAnimation { duration: Kirigami.Units.longDuration } }
                    Behavior on border.color { ColorAnimation { duration: Kirigami.Units.longDuration } }
                }

                onAccepted: {
                    if (sessionManager.lockScreenUiVisible) {
                        sessionManager.startLogin();
                    }
                }

                Connections {
                    target: root
                    function onClearPassword() {
                        passwordBox.forceActiveFocus()
                        passwordBox.text = "";
                        passwordBox.text = Qt.binding(() => PasswordSync.password);
                    }
                    function onNotificationRepeated() {
                        sessionManager.playHighlightAnimation();
                    }
                }
            }
            Binding {
                target: PasswordSync
                property: "password"
                value: passwordBox.text
            }

            QQC2.AbstractButton {
                id: loginButton
                Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button accessible only", "Unlock")
                Layout.preferredWidth: passwordBox.Layout.preferredHeight
                Layout.preferredHeight: passwordBox.Layout.preferredHeight
                hoverEnabled: true
                onClicked: sessionManager.startLogin()
                Keys.onEnterPressed: clicked()
                Keys.onReturnPressed: clicked()

                background: Rectangle {
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, loginButton.down ? 0.26 : (loginButton.hovered || loginButton.activeFocus ? 0.18 : (passwordBox.text.length > 0 ? 0.14 : 0.08)))
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, loginButton.activeFocus ? 0.45 : 0.18)
                    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
                }
                contentItem: Item {
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        source: LayoutMirroring.enabled ? "go-previous" : "go-next"
                        color: "#f4f6fa"
                        isMask: true
                    }
                }
            }
        }

        component FailableLabel : Text {
            id: _failableLabel
            required property int kind
            required property string label

            visible: authenticator.authenticatorTypes & kind
            text: label
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pointSize: Kirigami.Theme.smallFont.pointSize

            RejectPasswordAnimation {
                id: _rejectAnimation
                target: _failableLabel
                onFinished: _timer.restart()
            }
            Connections {
                target: authenticator
                function onNoninteractiveError(kind, authenticator) {
                    if (kind & _failableLabel.kind) {
                        _failableLabel.text = Qt.binding(() => authenticator.errorMessage)
                        _rejectAnimation.start()
                    }
                }
            }
            Timer {
                id: _timer
                interval: Kirigami.Units.humanMoment
                onTriggered: _failableLabel.text = Qt.binding(() => _failableLabel.label)
            }
        }

        FailableLabel {
            kind: ScreenLocker.Authenticator.Fingerprint
            label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your fingerprint on the reader)")
        }
        FailableLabel {
            kind: ScreenLocker.Authenticator.Smartcard
            label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:usagetip", "(or scan your smartcard)")
        }

        // conteúdo extra (controles de mídia)
        ColumnLayout {
            id: extraLayout
            Layout.fillWidth: true
        }

        // ---------- ações (suspender, trocar usuário...) ----------
        Row {
            id: actionItemsLayout
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Kirigami.Units.gridUnit * 2.2
            spacing: Kirigami.Units.gridUnit * 1.6
        }
    }
}
