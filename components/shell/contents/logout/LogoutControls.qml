/*
    SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigami as Kirigami
import QtQuick.Effects

import org.kde.breeze.components

import org.kde.plasma.private.sessions

Item {
    id: controls
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    anchors.fill: parent

    readonly property Item hostRoot: parent
    readonly property bool showAllOptions: sdtype === ShutdownType.ShutdownTypeDefault

    opacity: 0
    onHostRootChanged: fadeIn.restart()

    NumberAnimation {
        id: fadeIn
        target: controls
        property: "opacity"
        from: 0
        to: 1
        duration: Kirigami.Units.longDuration
        easing.type: Easing.InOutQuad
    }

    KCoreAddons.KUser {
        id: kuser
    }

    // For showing an "other users are logged in" hint
    SessionsModel {
        id: otherSessionsModel

        // In case the default values ever change
        includeUnusedSessions: false
        includeOwnSession: false
    }

    SessionManagement { id: sessaoVidro }

    // round avatar with a glass ring + name
    Column {
        id: cabecalho
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        anchors.bottomMargin: Kirigami.Units.gridUnit * 0.5
        spacing: Kirigami.Units.gridUnit * 0.9

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Kirigami.Units.gridUnit * 5.2
            height: width
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
                source: kuser.faceIconUrl
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectCrop
                visible: false
                layer.enabled: true
            }
            Rectangle { id: mascara; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
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
            anchors.horizontalCenter: parent.horizontalCenter
            text: kuser.fullName || kuser.loginName
            color: "#f4f6fa"
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
            font.weight: Font.Light
            font.letterSpacing: 0.4
            textFormat: Text.PlainText
        }
    }
    ColumnLayout {
        id: column

        anchors {
            top: parent.verticalCenter
            topMargin: Kirigami.Units.gridUnit * 2
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Kirigami.Units.largeSpacing

        height: Math.max(implicitHeight, Kirigami.Units.gridUnit * 10)
        width: Math.max(implicitWidth, Kirigami.Units.gridUnit * 16)

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.alignment: Qt.AlignHCenter
            //opacity, as visible would re-layout
            opacity: controls.hostRoot.countingDown ? 1 : 0
            Behavior on opacity {
                PropertyAnimation {
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
            text: {
                switch (sdtype) {
                    case ShutdownType.ShutdownTypeReboot:
                        return softwareUpdatePending ? i18ndp("plasma_shell_org.kde.plasma.desktop", "Installing software updates and restarting in 1 second", "Installing software updates and restarting in %1 seconds", controls.hostRoot.remainingTime)
                        : i18ndp("plasma_shell_org.kde.plasma.desktop", "Restarting in 1 second", "Restarting in %1 seconds", controls.hostRoot.remainingTime);
                    case ShutdownType.ShutdownTypeNone:
                        return i18ndp("plasma_shell_org.kde.plasma.desktop", "Logging out in 1 second", "Logging out in %1 seconds", controls.hostRoot.remainingTime);
                    case ShutdownType.ShutdownTypeHalt:
                    default:
                        return softwareUpdatePending ? i18ndp("plasma_shell_org.kde.plasma.desktop", "Installing software updates and shutting down in 1 second", "Installing software updates and shutting down in %1 seconds", controls.hostRoot.remainingTime)
                        : i18ndp("plasma_shell_org.kde.plasma.desktop", "Shutting down in 1 second", "Shutting down in %1 seconds", controls.hostRoot.remainingTime);
                }
            }
            textFormat: Text.PlainText
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: false
            color: Qt.rgba(1, 1, 1, 0.66)
            text: i18ndp("plasma_shell_org.kde.plasma.desktop",
                         "One other user is currently logged in. If the computer is shut down or restarted, that user may lose work.",
                         "%1 other users are currently logged in. If the computer is shut down or restarted, those users may lose work.",
                         otherSessionsModel.count)
            textFormat: Text.PlainText
            visible: otherSessionsModel.count > 0 && (sdtype !== ShutdownType.ShutdownTypeNone || controls.showAllOptions)
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: false
            color: Qt.rgba(1, 1, 1, 0.66)
            text: {
                if (isUefi) {
                    return i18nd("plasma_shell_org.kde.plasma.desktop", "When restarted, the computer will enter UEFI firmware settings.");
                } else {
                    return i18nd("plasma_shell_org.kde.plasma.desktop", "When restarted, the computer will enter the firmware setup screen.");
                }
            }
            textFormat: Text.PlainText
            visible: rebootToFirmwareSetup
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: false
            color: Qt.rgba(1, 1, 1, 0.66)
            text: i18nd("plasma_shell_org.kde.plasma.desktop", "When restarted, the computer will enter the boot loader menu.")
            textFormat: Text.PlainText
            visible: rebootToBootLoaderMenu
        }

        PlasmaComponents.Label {
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
            Layout.maximumWidth: Math.max(Kirigami.Units.gridUnit * 16, logoutButtonsRow.implicitWidth)
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: false
            color: Qt.rgba(1, 1, 1, 0.66)
            text: i18ndc("plasma_shell_org.kde.plasma.desktop", "%1 is a boot loader entry", "When restarted, the computer will switch to %1.", rebootToBootLoaderEntry)
            textFormat: Text.PlainText
            visible: rebootToBootLoaderEntry != ""
        }

        GridLayout {
            id: logoutButtonsRow

            readonly property int spacing: Kirigami.Units.gridUnit * 1.4
            rowSpacing: spacing
            columnSpacing: spacing

            Layout.topMargin: Kirigami.Units.gridUnit * 2 - column.spacing
            Layout.alignment: Qt.AlignHCenter

            readonly property int buttonCount: visibleChildren.length
            readonly property int singleRowWidth: (children[0].implicitWidth * buttonCount) + (spacing * (buttonCount - 1))
            columns: singleRowWidth < controls.width ? buttonCount : Math.ceil(buttonCount / 2)

            LogoutButton {
                id: suspendButton
                objectName: "suspendButton"
                icon.name: "system-suspend"
                text: controls.showAllOptions ? i18ndc("plasma_shell_org.kde.plasma.desktop", "Suspend to RAM", "Slee&p")
                                          : i18ndc("plasma_shell_org.kde.plasma.desktop", "Suspend to RAM", "Slee&p Now")
                onClicked: controls.hostRoot.sleepRequested()
                KeyNavigation.left: cancelButton
                KeyNavigation.right: hibernateButton.visible ? hibernateButton : (rebootButton.visible ? rebootButton : (shutdownButton.visible ? shutdownButton : (logoutButton.visible ? logoutButton : cancelButton)))
                visible: spdMethods.SuspendState && controls.showAllOptions
            }
            LogoutButton {
                id: hibernateButton
                objectName: "hibernateButton"
                icon.name: "system-suspend-hibernate"
                text: controls.showAllOptions ? i18nd("plasma_shell_org.kde.plasma.desktop", "&Hibernate")
                                          : i18nd("plasma_shell_org.kde.plasma.desktop", "&Hibernate Now")
                onClicked: controls.hostRoot.hibernateRequested()
                KeyNavigation.left: suspendButton.visible ? suspendButton : cancelButton
                KeyNavigation.right: rebootButton.visible ? rebootButton : (shutdownButton.visible ? shutdownButton : (logoutButton.visible ? logoutButton : cancelButton))
                visible: spdMethods.HibernateState && controls.showAllOptions
            }
            LogoutButton {
                id: rebootButton
                objectName: "rebootButton"
                icon.name: softwareUpdatePending ? "system-reboot-update" : "system-reboot"
                text: {
                    if (softwareUpdatePending) {
                        return i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button Keep short", "Install Updates and Restart")
                    } else {
                        return controls.showAllOptions ? i18nd("plasma_shell_org.kde.plasma.desktop", "&Restart")
                                                   : i18nd("plasma_shell_org.kde.plasma.desktop", "&Restart Now")
                    }
                }
                onClicked: {
                    if (softwareUpdatePending) {
                        controls.hostRoot.rebootUpdateRequested();
                    } else {
                        controls.hostRoot.rebootRequested();
                    }
                }
                KeyNavigation.left: hibernateButton.visible ? hibernateButton : (suspendButton.visible ? suspendButton : cancelButton)
                KeyNavigation.right: rebootWithoutUpdatesButton.visible ? rebootWithoutUpdatesButton : (shutdownButton.visible ? shutdownButton : (logoutButton.visible ? logoutButton : cancelButton))
                focus: sdtype === ShutdownType.ShutdownTypeReboot
                visible: maysd && (sdtype === ShutdownType.ShutdownTypeReboot || controls.showAllOptions)
            }
            LogoutButton {
                id: rebootWithoutUpdatesButton
                objectName: "rebootWithoutUpdatesButton"
                icon.name: "system-reboot"
                text: controls.showAllOptions ? i18nd("plasma_shell_org.kde.plasma.desktop", "&Restart")
                                          : i18nd("plasma_shell_org.kde.plasma.desktop", "&Restart Now")
                onClicked: {
                    controls.hostRoot.rebootRequested();
                }
                KeyNavigation.left: rebootButton
                KeyNavigation.right: shutdownButton.visible ? shutdownButton : (logoutButton.visible ? logoutButton : cancelButton)
                visible: maysd && softwareUpdatePending && (sdtype === ShutdownType.ShutdownTypeReboot || controls.showAllOptions)
            }
            LogoutButton {
                id: shutdownButton
                objectName: "shutdownButton"
                icon.name: softwareUpdatePending ? "system-shutdown-update" : "system-shutdown"
                text: {
                    if (softwareUpdatePending) {
                        return i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button Keep short", "Install Updates and Shut Down")
                    } else {
                        return controls.showAllOptions ? i18nd("plasma_shell_org.kde.plasma.desktop", "&Shut Down")
                                                   : i18nd("plasma_shell_org.kde.plasma.desktop", "&Shut Down Now")
                    }
                }
                onClicked: {
                    if (softwareUpdatePending) {
                        controls.hostRoot.haltUpdateRequested();
                    } else {
                        controls.hostRoot.haltRequested();
                    }
                }
                KeyNavigation.left: rebootWithoutUpdatesButton.visible ? rebootWithoutUpdatesButton : (rebootButton.visible ? rebootButton : (hibernateButton.visible ? hibernateButton : (suspendButton.visible ? suspendButton : cancelButton)))
                KeyNavigation.right: shutdownWithoutUpdatesButton.visible ? shutdownWithoutUpdatesButton : (logoutButton.visible ? logoutButton : cancelButton)
                focus: sdtype === ShutdownType.ShutdownTypeHalt || controls.showAllOptions
                visible: maysd && (sdtype === ShutdownType.ShutdownTypeHalt || controls.showAllOptions)
            }
            LogoutButton {
                id: shutdownWithoutUpdatesButton
                objectName: "shutdownWithoutUpdatesButton"
                icon.name: "system-shutdown"
                text: controls.showAllOptions ? i18nd("plasma_shell_org.kde.plasma.desktop", "&Shut Down")
                                          : i18nd("plasma_shell_org.kde.plasma.desktop", "&Shut Down Now")
                onClicked: {
                    controls.hostRoot.haltRequested();
                }
                KeyNavigation.left: shutdownButton
                KeyNavigation.right: logoutButton.visible ? logoutButton : cancelButton
                focus: sdtype === ShutdownType.ShutdownTypeHalt || controls.showAllOptions
                visible: maysd && softwareUpdatePending && (sdtype === ShutdownType.ShutdownTypeHalt || controls.showAllOptions)
            }
            LogoutButton {
                id: logoutButton
                objectName: "logoutButton"
                icon.name: "system-log-out"
                text: controls.showAllOptions ? i18nd("plasma_shell_org.kde.plasma.desktop", "&Log Out")
                                          : i18nd("plasma_shell_org.kde.plasma.desktop", "&Log Out Now")
                onClicked: controls.hostRoot.logoutRequested()
                KeyNavigation.left: shutdownWithoutUpdatesButton.visible ? shutdownWithoutUpdatesButton : (shutdownButton.visible ? shutdownButton : (rebootWithoutUpdatesButton.visible ? rebootWithoutUpdatesButton : (rebootButton.visible ? rebootButton : (hibernateButton.visible ? hibernateButton : (suspendButton.visible ? suspendButton : cancelButton)))))
                KeyNavigation.right: cancelButton
                focus: sdtype === ShutdownType.ShutdownTypeNone
                visible: canLogout && (sdtype === ShutdownType.ShutdownTypeNone || controls.showAllOptions)
            }
            LogoutButton {
                id: lockButton
                objectName: "lockButton"
                icon.name: "system-lock-screen"
                text: "&Bloquear"
                visible: controls.showAllOptions && sessaoVidro.canLock
                onClicked: controls.hostRoot.lockScreenRequested()
            }
            LogoutButton {
                id: switchUserButton
                objectName: "switchUserButton"
                icon.name: "system-switch-user"
                text: "&Trocar usuário"
                visible: controls.showAllOptions && sessaoVidro.canSwitchUser
                onClicked: {
                    controls.hostRoot.cancelRequested();
                    sessaoVidro.switchUser();
                }
            }
            LogoutButton {
                id: cancelButton
                objectName: "cancelButton"
                icon.name: "dialog-cancel"
                text: i18nd("plasma_shell_org.kde.plasma.desktop", "&Cancel")
                onClicked: controls.hostRoot.cancelRequested()
                KeyNavigation.left: logoutButton.visible ? logoutButton : (shutdownWithoutUpdatesButton.visible ? shutdownWithoutUpdatesButton : (shutdownButton.visible ? shutdownButton : (rebootWithoutUpdatesButton.visible ? rebootWithoutUpdatesButton : (rebootButton.visible ? rebootButton : (hibernateButton.visible ? hibernateButton : suspendButton)))))
                KeyNavigation.right: suspendButton.visible ? suspendButton : (hibernateButton.visible ? hibernateButton : rebootButton)
            }
        }
    }
}
