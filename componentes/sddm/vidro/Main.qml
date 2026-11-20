/*
    Vidro — tema de login (SDDM, Qt 6).
    Mesmo visual da tela de bloqueio Vidro: relógio fino, avatar com anel de vidro,
    senha em pílula translúcida, sessão e energia em botões discretos.
    Só usa QtQuick puro (sem dependências do Plasma) para ser robusto no greeter.
*/
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: raiz
    width: 1920
    height: 1080
    color: "#101116"

    readonly property color texto: "#f4f6fa"
    readonly property real u: Math.max(12, Math.min(width, height) / 60)   // unidade base
    property int usuarioAtual: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessaoAtual: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string mensagem: ""

    // ---- dados do usuário atual (o modelo só expõe roles via delegate) ----
    property string nomeUsuario: ""
    property string nomeExibido: ""
    property string avatar: ""
    Repeater {
        model: userModel
        delegate: Item {
            required property int index
            required property string name
            required property string realName
            required property string icon
            visible: false
            readonly property bool atual: index === raiz.usuarioAtual
            function publicar() {
                if (!atual) return;
                raiz.nomeUsuario = name;
                raiz.nomeExibido = realName.length > 0 ? realName : name;
                raiz.avatar = icon;
            }
            onAtualChanged: publicar()
            Component.onCompleted: publicar()
        }
    }
    property var nomesSessoes: []
    Repeater {
        model: sessionModel
        delegate: Item {
            required property int index
            required property string name
            visible: false
            Component.onCompleted: {
                const l = raiz.nomesSessoes.slice(); l[index] = name; raiz.nomesSessoes = l;
            }
        }
    }
    function nomeSessao(i) {
        const n = nomesSessoes[i] || "";
        if (/ogui|opengamepad/i.test(n)) return "Modo Jogo (OpenGamepadUI)";
        if (/gamescope|steam/i.test(n)) return "Modo Jogo";
        if (/plasma/i.test(n)) return "Área de trabalho";
        return n;
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            raiz.mensagem = "Senha incorreta";
            senha.text = "";
            senha.enabled = true;
            tremer.start();
            senha.forceActiveFocus();
        }
        function onLoginSucceeded() { raiz.mensagem = ""; }
    }

    function entrar() {
        if (!senha.enabled) return;
        raiz.mensagem = "";
        senha.enabled = false;
        sddm.login(raiz.nomeUsuario, senha.text, raiz.sessaoAtual);
    }

    // ---------------- fundo ----------------
    Image {
        anchors.fill: parent
        source: config.backgroundBlur ? config.backgroundBlur : config.background
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        smooth: true
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.34) }
            GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.20) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.42) }
        }
    }

    // Teclado do sistema (plasma-keyboard, aberto pelo KWin). Se ele não informar a altura, supõe 42% da tela.
    readonly property bool tecladoAberto: Qt.inputMethod.visible
    readonly property real alturaTeclado: Qt.inputMethod.keyboardRectangle.height > 0
        ? Qt.inputMethod.keyboardRectangle.height : height * 0.42
    readonly property real subida: tecladoAberto
        ? Math.max(0, bloco.y + bloco.height + u * 1.2 - (height - alturaTeclado)) : 0

    Item {
        id: conteudo
        anchors.fill: parent
        opacity: 0
        transform: Translate {
            y: -raiz.subida
            Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }
        Component.onCompleted: entrada.start()
        ParallelAnimation {
            id: entrada
            NumberAnimation { target: conteudo; property: "opacity"; from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
            NumberAnimation { target: bloco; property: "anchors.verticalCenterOffset"; from: raiz.u * 1.4; to: raiz.u * 0.6; duration: 800; easing.type: Easing.OutCubic }
        }

        // ---------------- relógio ----------------
        Column {
            id: relogio
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: raiz.tecladoAberto ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
            y: Math.round(raiz.height * 0.10)
            spacing: 0
            property date agora: new Date()
            Timer { interval: 1000; running: true; repeat: true; onTriggered: relogio.agora = new Date() }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(relogio.agora, "HH:mm")
                color: raiz.texto
                font.family: "Noto Sans"
                font.pixelSize: raiz.u * 7.2
                font.weight: Font.ExtraLight
                font.letterSpacing: -2
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    const d = relogio.agora;
                    const dias = ["Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"];
                    const meses = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"];
                    return dias[d.getDay()] + ", " + d.getDate() + " de " + meses[d.getMonth()];
                }
                color: Qt.rgba(0.96, 0.97, 0.98, 0.72)
                font.family: "Noto Sans"
                font.pixelSize: raiz.u * 1.25
                font.letterSpacing: 0.6
            }
        }

        // ---------------- avatar + nome + senha ----------------
        Column {
            id: bloco
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: raiz.u * 0.6
            spacing: 0
            width: Math.min(raiz.width - raiz.u * 4, raiz.u * 22)

            Item {
                id: caixaAvatar
                anchors.horizontalCenter: parent.horizontalCenter
                width: raiz.u * 6
                height: width
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -6
                    radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.20)
                }
                Image {
                    id: face
                    anchors.fill: parent
                    source: raiz.avatar
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
                Text {
                    anchors.centerIn: parent
                    visible: face.status !== Image.Ready
                    text: raiz.nomeExibido.length > 0 ? raiz.nomeExibido.charAt(0).toUpperCase() : "?"
                    color: raiz.texto
                    font.pixelSize: parent.width * 0.42
                    font.weight: Font.Light
                }
            }

            Item { width: 1; height: raiz.u * 1.1 }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: raiz.u
                BotaoSeta { texto: "‹"; visible: userModel.count > 1; onClicked: raiz.usuarioAtual = (raiz.usuarioAtual - 1 + userModel.count) % userModel.count }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: raiz.nomeExibido
                    color: raiz.texto
                    font.family: "Noto Sans"
                    font.pixelSize: raiz.u * 1.6
                    font.weight: Font.Light
                    font.letterSpacing: 0.4
                }
                BotaoSeta { texto: "›"; visible: userModel.count > 1; onClicked: raiz.usuarioAtual = (raiz.usuarioAtual + 1) % userModel.count }
            }

            Item { width: 1; height: raiz.u * 0.6 }

            Text {
                id: aviso
                anchors.horizontalCenter: parent.horizontalCenter
                height: raiz.u * 1.6
                verticalAlignment: Text.AlignVCenter
                text: raiz.mensagem.length > 0 ? raiz.mensagem : (keyboard.capsLock ? "Caps Lock ativado" : "")
                color: Qt.rgba(1, 0.86, 0.78, 0.92)
                font.family: "Noto Sans"
                font.pixelSize: raiz.u * 0.85
                opacity: text.length > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }

            Row {
                id: linhaSenha
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: raiz.u * 0.5
                property real alt: raiz.u * 2.5
                // espaçador: mantém a pílula centralizada
                Item { width: linhaSenha.alt; height: 1 }

                TextField {
                    id: senha
                    width: raiz.u * 15
                    height: linhaSenha.alt
                    focus: true
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    placeholderText: "Senha"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.45)
                    color: raiz.texto
                    selectionColor: Qt.rgba(1, 1, 1, 0.3)
                    font.family: "Noto Sans"
                    font.pixelSize: raiz.u * 1.0
                    leftPadding: raiz.u * 1.1
                    rightPadding: raiz.u * 1.1
                    verticalAlignment: TextInput.AlignVCenter
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    background: Rectangle {
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, senha.activeFocus ? 0.12 : 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, senha.activeFocus ? 0.34 : 0.16)
                        Behavior on color { ColorAnimation { duration: 250 } }
                    }
                    onAccepted: raiz.entrar()
                    Keys.onEscapePressed: { text = ""; raiz.mensagem = ""; }
                    SequentialAnimation {
                        id: tremer
                        loops: 1
                        NumberAnimation { target: linhaSenha; property: "anchors.horizontalCenterOffset"; to: -raiz.u * 0.6; duration: 60 }
                        NumberAnimation { target: linhaSenha; property: "anchors.horizontalCenterOffset"; to: raiz.u * 0.6; duration: 90 }
                        NumberAnimation { target: linhaSenha; property: "anchors.horizontalCenterOffset"; to: -raiz.u * 0.35; duration: 80 }
                        NumberAnimation { target: linhaSenha; property: "anchors.horizontalCenterOffset"; to: 0; duration: 90; easing.type: Easing.OutCubic }
                    }
                }

                BotaoVidro {
                    width: linhaSenha.alt
                    simbolo: senha.enabled ? "→" : "…"
                    destaque: senha.text.length > 0
                    onClicked: raiz.entrar()
                }
            }
        }

        // ---------------- sessão (esquerda) ----------------
        Rectangle {
            id: pilulaSessao
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: raiz.u * 1.5
            height: raiz.u * 2.2
            width: rotuloSessao.implicitWidth + raiz.u * 2.4
            radius: height / 2
            color: Qt.rgba(1, 1, 1, maSessao.containsMouse ? 0.14 : 0.07)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, maSessao.containsMouse ? 0.26 : 0.13)
            visible: sessionModel.rowCount() > 1
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                id: rotuloSessao
                anchors.centerIn: parent
                text: raiz.nomeSessao(raiz.sessaoAtual) + "   ⌄"
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: "Noto Sans"
                font.pixelSize: raiz.u * 0.85
                font.letterSpacing: 0.3
            }
            MouseArea {
                id: maSessao
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: raiz.sessaoAtual = (raiz.sessaoAtual + 1) % Math.max(1, sessionModel.rowCount())
            }
        }

        BotaoVidro {
            id: botaoTeclado
            anchors.left: pilulaSessao.visible ? pilulaSessao.right : parent.left
            anchors.leftMargin: pilulaSessao.visible ? raiz.u * 0.6 : raiz.u * 1.5
            anchors.verticalCenter: pilulaSessao.visible ? pilulaSessao.verticalCenter : undefined
            anchors.bottom: pilulaSessao.visible ? undefined : parent.bottom
            anchors.bottomMargin: raiz.u * 1.5
            width: raiz.u * 2.2
            simbolo: "⌨"
            dica: "Teclado"
            onClicked: {
                senha.forceActiveFocus();
                if (Qt.inputMethod.visible) Qt.inputMethod.hide(); else Qt.inputMethod.show();
            }
        }

        // ---------------- energia (direita) ----------------
        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: raiz.u * 1.5
            spacing: raiz.u * 0.8
            BotaoVidro { width: raiz.u * 2.2; simbolo: "☾"; dica: "Suspender"; visible: sddm.canSuspend; onClicked: sddm.suspend() }
            BotaoVidro { width: raiz.u * 2.2; simbolo: "↻"; dica: "Reiniciar"; visible: sddm.canReboot; onClicked: sddm.reboot() }
            BotaoVidro { width: raiz.u * 2.2; simbolo: "⏻"; dica: "Desligar"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
        }
    }

    // ---------------- componentes ----------------
    component BotaoVidro: Rectangle {
        id: bv
        property string simbolo: ""
        property string dica: ""
        property bool destaque: false
        signal clicked()
        height: width
        radius: width / 2
        color: Qt.rgba(1, 1, 1, ma.pressed ? 0.24 : (ma.containsMouse ? 0.16 : (destaque ? 0.13 : 0.07)))
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, ma.containsMouse ? 0.30 : 0.15)
        scale: ma.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Text {
            anchors.centerIn: parent
            text: bv.simbolo
            color: raiz.texto
            font.family: "Noto Sans Symbols 2, Noto Sans Symbols, Noto Sans"
            font.pixelSize: bv.width * 0.40
        }
        Text {
            anchors.top: parent.bottom
            anchors.topMargin: raiz.u * 0.35
            anchors.horizontalCenter: parent.horizontalCenter
            text: bv.dica
            visible: bv.dica.length > 0
            opacity: ma.containsMouse ? 0.85 : 0
            color: raiz.texto
            font.family: "Noto Sans"
            font.pixelSize: raiz.u * 0.7
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bv.clicked() }
    }
    component BotaoSeta: Text {
        id: bs
        property string texto: ""
        signal clicked()
        text: texto
        color: Qt.rgba(1, 1, 1, 0.6)
        font.pixelSize: raiz.u * 1.6
        MouseArea { anchors.fill: parent; anchors.margins: -raiz.u * 0.5; onClicked: bs.clicked() }
    }
}
