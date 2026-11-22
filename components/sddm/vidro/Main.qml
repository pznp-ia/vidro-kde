/*
    Vidro — tema de login (SDDM, Qt 6).
    Mesmo visual da tela de bloqueio Vidro: relógio fino, avatar com anel de glass,
    password em pílula translúcida, sessão e energia em botões discretos.
    Só usa QtQuick puro (sem dependências do Plasma) para ser robusto no greeter.
*/
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#101116"

    readonly property color textColor: "#f4f6fa"

    // ---- options (theme.conf / theme.conf.user, written by Vidro Settings) ----
    function opt(k, d) { const v = config[k]; return (v === undefined || v === null || String(v) === "") ? d : String(v); }
    readonly property bool useBlur: opt("useBlur", "true") === "true"
    readonly property real dim: Number(opt("dim", "30")) / 100          // 0 = sem escurecer
    readonly property bool clock12h: opt("clockFormat", "24h") === "12h"
    readonly property bool clockSeconds: opt("clockSeconds", "false") === "true"
    readonly property real clockScale: Number(opt("clockScale", "100")) / 100
    readonly property int clockWeight: ({ "ExtraLight": Font.ExtraLight, "Light": Font.Light, "Normal": Font.Normal, "DemiBold": Font.DemiBold, "Bold": Font.Bold })[opt("clockWeight", "ExtraLight")] || Font.ExtraLight
    readonly property bool showDate: opt("showDate", "true") === "true"
    readonly property bool showClock: opt("showClock", "true") === "true"
    readonly property color accent: opt("accent", "#ffffff")
    readonly property real glass: Number(opt("glass", "8")) / 100              // opacity of the pills
    readonly property bool alignLeft: opt("layout", "centro") === "esquerda"
    readonly property bool showAvatar: opt("showAvatar", "true") === "true"
    readonly property bool squareAvatar: opt("avatarShape", "circulo") === "quadrado"
    readonly property string fontFamily: opt("font", "Noto Sans")
    readonly property real u: Math.max(12, Math.min(width, height) / 60)   // unidade base
    property int currentUser: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int currentSession: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string message: ""

    // ---- current user data (the model only exposes roles through a delegate) ----
    property string userName: ""
    property string displayName: ""
    property string avatar: ""
    Repeater {
        model: userModel
        delegate: Item {
            required property int index
            required property string name
            required property string realName
            required property string icon
            visible: false
            readonly property bool isCurrent: index === root.currentUser
            function publish() {
                if (!isCurrent) return;
                root.userName = name;
                root.displayName = realName.length > 0 ? realName : name;
                root.avatar = icon;
            }
            onIsCurrentChanged: publish()
            Component.onCompleted: publish()
        }
    }
    property var sessionNames: []
    Repeater {
        model: sessionModel
        delegate: Item {
            required property int index
            required property string name
            visible: false
            Component.onCompleted: {
                const l = root.sessionNames.slice(); l[index] = name; root.sessionNames = l;
            }
        }
    }
    function sessionName(i) {
        const n = sessionNames[i] || "";
        if (/ogui|opengamepad/i.test(n)) return "Modo Jogo (OpenGamepadUI)";
        if (/gamescope|steam/i.test(n)) return "Modo Jogo";
        if (/plasma/i.test(n)) return "Área de trabalho";
        return n;
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.message = "Senha incorreta";
            password.text = "";
            password.enabled = true;
            shake.start();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() { root.message = ""; }
    }

    function login() {
        if (!password.enabled) return;
        root.message = "";
        password.enabled = false;
        sddm.login(root.userName, password.text, root.currentSession);
    }

    // ---------------- fundo ----------------
    Image {
        anchors.fill: parent
        source: (root.useBlur && config.backgroundBlur) ? config.backgroundBlur : config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        smooth: true
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.dim * 1.13) }
            GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, root.dim * 0.67) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, Math.min(0.95, root.dim * 1.4)) }
        }
    }

    // System keyboard (plasma-keyboard, opened by KWin). If it does not report its height, assume 42% of the screen.
    readonly property bool keyboardOpen: Qt.inputMethod.visible
    readonly property real keyboardHeight: Qt.inputMethod.keyboardRectangle.height > 0
        ? Qt.inputMethod.keyboardRectangle.height : height * 0.42
    readonly property real lift: keyboardOpen
        ? Math.max(0, block.y + block.height + u * 1.2 - (height - keyboardHeight)) : 0

    Item {
        id: content
        anchors.fill: parent
        opacity: 0
        transform: Translate {
            y: -root.lift
            Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }
        Component.onCompleted: intro.start()
        ParallelAnimation {
            id: intro
            NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
            NumberAnimation { target: block; property: "anchors.verticalCenterOffset"; from: root.u * 1.4; to: root.u * 0.6; duration: 800; easing.type: Easing.OutCubic }
        }

        // ---------------- clock ----------------
        Column {
            id: clock
            anchors.horizontalCenter: root.alignLeft ? undefined : parent.horizontalCenter
            x: root.alignLeft ? root.width * 0.08 : 0
            visible: root.showClock
            opacity: root.keyboardOpen ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
            y: Math.round(root.height * 0.10)
            spacing: 0
            property date now: new Date()
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }
            Text {
                anchors.horizontalCenter: root.alignLeft ? undefined : parent.horizontalCenter
                text: Qt.formatTime(clock.now, (root.clock12h ? "h:mm" : "HH:mm") + (root.clockSeconds ? ":ss" : "") + (root.clock12h ? " AP" : ""))
                color: root.textColor
                font.family: root.fontFamily
                font.pixelSize: root.u * 7.2 * root.clockScale
                font.weight: root.clockWeight
                font.letterSpacing: -2
            }
            Text {
                anchors.horizontalCenter: root.alignLeft ? undefined : parent.horizontalCenter
                visible: root.showDate
                text: {
                    const d = clock.now;
                    const days = ["Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"];
                    const months = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"];
                    return days[d.getDay()] + ", " + d.getDate() + " de " + months[d.getMonth()];
                }
                color: Qt.rgba(0.96, 0.97, 0.98, 0.72)
                font.family: root.fontFamily
                font.pixelSize: root.u * 1.25
                font.letterSpacing: 0.6
            }
        }

        // ---------------- avatar + nome + senha ----------------
        Column {
            id: block
            anchors.horizontalCenter: root.alignLeft ? undefined : parent.horizontalCenter
            x: root.alignLeft ? root.width * 0.08 : 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.u * 0.6
            spacing: 0
            width: Math.min(root.width - root.u * 4, root.u * 22)

            Item {
                id: avatarBox
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.showAvatar
                width: root.u * 6
                height: width
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -6
                    radius: root.squareAvatar ? width * 0.24 : width / 2
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.20)
                }
                Image {
                    id: face
                    anchors.fill: parent
                    source: root.avatar
                    sourceSize: Qt.size(width * 2, height * 2)
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                    layer.enabled: true
                }
                Rectangle { id: mask; anchors.fill: parent; radius: root.squareAvatar ? width * 0.22 : width / 2; visible: false; layer.enabled: true }
                MultiEffect {
                    anchors.fill: parent
                    source: face
                    maskEnabled: true
                    maskSource: mask
                    visible: face.status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    text: root.displayName.length > 0 ? root.displayName.charAt(0).toUpperCase() : "?"
                    color: root.textColor
                    font.pixelSize: parent.width * 0.42
                    font.weight: Font.Light
                }
            }

            Item { width: 1; height: root.showAvatar ? root.u * 1.1 : 0 }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.u
                ArrowButton { textColor: "‹"; visible: userModel.count > 1; onClicked: root.currentUser = (root.currentUser - 1 + userModel.count) % userModel.count }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.displayName
                    color: root.textColor
                    font.family: root.fontFamily
                    font.pixelSize: root.u * 1.6
                    font.weight: Font.Light
                    font.letterSpacing: 0.4
                }
                ArrowButton { textColor: "›"; visible: userModel.count > 1; onClicked: root.currentUser = (root.currentUser + 1) % userModel.count }
            }

            Item { width: 1; height: root.u * 0.6 }

            Text {
                id: notice
                anchors.horizontalCenter: parent.horizontalCenter
                height: root.u * 1.6
                verticalAlignment: Text.AlignVCenter
                text: root.message.length > 0 ? root.message : (keyboard.capsLock ? "Caps Lock ativado" : "")
                color: Qt.rgba(1, 0.86, 0.78, 0.92)
                font.family: root.fontFamily
                font.pixelSize: root.u * 0.85
                opacity: text.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            Row {
                id: passwordRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.u * 0.5
                property real alt: root.u * 2.5
                // spacer: keeps the pill centered
                Item { width: passwordRow.alt; height: 1 }

                TextField {
                    id: password
                    width: root.u * 15
                    height: passwordRow.alt
                    focus: true
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    placeholderText: "Senha"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.45)
                    color: root.textColor
                    selectionColor: Qt.rgba(1, 1, 1, 0.3)
                    font.family: root.fontFamily
                    font.pixelSize: root.u * 1.0
                    leftPadding: root.u * 1.1
                    rightPadding: root.u * 1.1
                    verticalAlignment: TextInput.AlignVCenter
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    background: Rectangle {
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, password.activeFocus ? root.glass + 0.04 : root.glass)
                        border.width: 1
                        border.color: password.activeFocus ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.55) : Qt.rgba(1, 1, 1, 0.16)
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                    onAccepted: root.login()
                    Keys.onEscapePressed: { text = ""; root.message = ""; }
                    SequentialAnimation {
                        id: shake
                        loops: 1
                        NumberAnimation { target: passwordRow; property: "anchors.horizontalCenterOffset"; to: -root.u * 0.6; duration: 60 }
                        NumberAnimation { target: passwordRow; property: "anchors.horizontalCenterOffset"; to: root.u * 0.6; duration: 90 }
                        NumberAnimation { target: passwordRow; property: "anchors.horizontalCenterOffset"; to: -root.u * 0.35; duration: 80 }
                        NumberAnimation { target: passwordRow; property: "anchors.horizontalCenterOffset"; to: 0; duration: 90; easing.type: Easing.OutCubic }
                    }
                }

                GlassButton {
                    width: passwordRow.alt
                    symbol: password.enabled ? "→" : "…"
                    accent: password.text.length > 0
                    onClicked: root.login()
                }
            }
        }

        // ---------------- session (left) ----------------
        Rectangle {
            id: sessionPill
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: root.u * 1.5
            height: root.u * 2.2
            width: sessionLabel.implicitWidth + root.u * 2.4
            radius: height / 2
            color: Qt.rgba(1, 1, 1, sessionArea.containsMouse ? 0.14 : 0.07)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, sessionArea.containsMouse ? 0.26 : 0.13)
            visible: sessionModel.rowCount() > 1
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                id: sessionLabel
                anchors.centerIn: parent
                text: root.sessionName(root.currentSession) + "   ⌄"
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: root.fontFamily
                font.pixelSize: root.u * 0.85
                font.letterSpacing: 0.3
            }
            MouseArea {
                id: sessionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.currentSession = (root.currentSession + 1) % Math.max(1, sessionModel.rowCount())
            }
        }

        GlassButton {
            id: keyboardButton
            anchors.left: sessionPill.visible ? sessionPill.right : parent.left
            anchors.leftMargin: sessionPill.visible ? root.u * 0.6 : root.u * 1.5
            anchors.verticalCenter: sessionPill.visible ? sessionPill.verticalCenter : undefined
            anchors.bottom: sessionPill.visible ? undefined : parent.bottom
            anchors.bottomMargin: root.u * 1.5
            width: root.u * 2.2
            symbol: "⌨"
            hint: "Teclado"
            onClicked: {
                password.forceActiveFocus();
                if (Qt.inputMethod.visible) Qt.inputMethod.hide(); else Qt.inputMethod.show();
            }
        }

        // ---------------- energia (direita) ----------------
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: root.u * 1.5
            spacing: root.u * 0.8
            GlassButton { width: root.u * 2.2; symbol: "☾"; hint: "Suspender"; visible: sddm.canSuspend; onClicked: sddm.suspend() }
            GlassButton { width: root.u * 2.2; symbol: "↻"; hint: "Reiniciar"; visible: sddm.canReboot; onClicked: sddm.reboot() }
            GlassButton { width: root.u * 2.2; symbol: "⏻"; hint: "Desligar"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
        }
    }

    // ---------------- componentes ----------------
    component GlassButton: Rectangle {
        id: bv
        property string symbol: ""
        property string hint: ""
        property bool accent: false
        signal clicked()
        height: width
        radius: width / 2
        color: accent ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, ma.pressed ? 0.5 : (ma.containsMouse ? 0.4 : 0.3))
                        : Qt.rgba(1, 1, 1, ma.pressed ? 0.24 : (ma.containsMouse ? 0.16 : root.glass * 0.9))
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, ma.containsMouse ? 0.30 : 0.15)
        scale: ma.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Text {
            anchors.centerIn: parent
            text: bv.symbol
            color: root.textColor
            font.family: "Noto Sans Symbols 2, Noto Sans Symbols, Noto Sans"
            font.pixelSize: bv.width * 0.40
        }
        Text {
            anchors.top: parent.bottom
            anchors.topMargin: root.u * 0.35
            anchors.horizontalCenter: parent.horizontalCenter
            text: bv.hint
            visible: bv.hint.length > 0
            opacity: ma.containsMouse ? 0.85 : 0
            color: root.textColor
            font.family: root.fontFamily
            font.pixelSize: root.u * 0.7
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bv.clicked() }
    }
    component ArrowButton: Text {
        id: bs
        property string textColor: ""
        signal clicked()
        text: textColor
        color: Qt.rgba(1, 1, 1, 0.6)
        font.pixelSize: root.u * 1.6
        MouseArea { anchors.fill: parent; anchors.margins: -root.u * 0.5; onClicked: bs.clicked() }
    }
}
