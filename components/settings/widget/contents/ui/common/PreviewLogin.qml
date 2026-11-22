// Preview: login screen (background, dim, clock, avatar, password pill, layout)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property real dim: U.n(app, "Login", "dim", 30) / 100
    readonly property bool leftSide: U.v(app, "Login", "layout", "center") === "left"
    readonly property bool twelveHour: U.v(app, "Login", "clock_format", "24h") === "12h"
    readonly property bool seconds: U.b(app, "Login", "clock_seconds", false)
    readonly property real size: U.n(app, "Login", "clock_size", 100) / 100
    readonly property string weight: U.v(app, "Login", "clock_weight", "ExtraLight")
    readonly property bool showDate: U.b(app, "Login", "show_date", true)
    readonly property bool clock: U.b(app, "Login", "show_clock", true)
    readonly property color accent: U.color(U.v(app, "Login", "accent", "#ffffff"))
    readonly property real glass: U.n(app, "Login", "glass", 8) / 100
    readonly property bool avatar: U.b(app, "Login", "avatar", true)
    readonly property bool square: U.v(app, "Login", "avatar_shape", "circle") === "square"
    readonly property string fontName: U.v(app, "Login", "font", "Noto Sans")
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: r.now = new Date() }
    Image {   // the real background, already built by the module
        anchors.fill: parent; fillMode: Image.PreserveAspectCrop; cache: false; asynchronous: true
        source: (r.app && r.app.home) ? "file://" + r.app.home + "/.local/share/vidro/login/theme/" + (U.b(r.app, "Login", "blur", true) ? "background-blur.jpg" : "background.jpg") + "?v=" + r.app.version : ""
    }
    Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, r.dim) }
    readonly property real u: height / 26
    Column {
        visible: r.clock
        x: r.leftSide ? r.width * 0.08 : (r.width - width) / 2; y: r.height * 0.08
        Text { anchors.horizontalCenter: r.leftSide ? undefined : parent.horizontalCenter
            text: Qt.formatTime(r.now, (r.twelveHour ? "h:mm" : "HH:mm") + (r.seconds ? ":ss" : "") + (r.twelveHour ? " AP" : ""))
            color: "#f4f6fa"; font.family: r.fontName; font.pixelSize: r.u * 4.2 * r.size
            font.weight: ({ "ExtraLight": Font.ExtraLight, "Light": Font.Light, "Normal": Font.Normal, "DemiBold": Font.DemiBold, "Bold": Font.Bold })[r.weight] || Font.ExtraLight }
        Text { visible: r.showDate; anchors.horizontalCenter: r.leftSide ? undefined : parent.horizontalCenter
            text: ["Domingo", "Segunda-feira", "Terça-feira", "Quarta-feira", "Quinta-feira", "Sexta-feira", "Sábado"][r.now.getDay()] + ", " + r.now.getDate() + " de " + ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"][r.now.getMonth()]; color: Qt.rgba(1, 1, 1, 0.72); font.family: r.fontName; font.pixelSize: r.u * 0.8 }
    }
    Column {
        x: r.leftSide ? r.width * 0.08 : (r.width - width) / 2; y: r.height * 0.45
        spacing: r.u * 0.5
        Rectangle { visible: r.avatar; anchors.horizontalCenter: parent.horizontalCenter; width: r.u * 3.4; height: width
            radius: r.square ? width * 0.24 : width / 2; color: Qt.rgba(1, 1, 1, 0.16); border.color: Qt.rgba(1, 1, 1, 0.3)
            Text { anchors.centerIn: parent; text: "U"; color: "white"; font.pixelSize: parent.width * 0.45; font.weight: Font.Light } }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Usuário"; color: "#f4f6fa"; font.family: r.fontName; font.pixelSize: r.u * 0.9 }
        Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: r.u * 0.3
            Rectangle { width: r.u * 8; height: r.u * 1.4; radius: height / 2; color: Qt.rgba(1, 1, 1, r.glass + 0.04)
                border.color: Qt.rgba(r.accent.r, r.accent.g, r.accent.b, 0.55)
                Text { x: r.u * 0.6; anchors.verticalCenter: parent.verticalCenter; text: "Senha"; color: Qt.rgba(1, 1, 1, 0.45); font.pixelSize: r.u * 0.6 } }
            Rectangle { width: r.u * 1.4; height: width; radius: width / 2; color: Qt.rgba(r.accent.r, r.accent.g, r.accent.b, 0.3)
                Text { anchors.centerIn: parent; text: "→"; color: "white"; font.pixelSize: r.u * 0.6 } } }
    }
}
