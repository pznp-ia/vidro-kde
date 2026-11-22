// Preview: a mock window that plays the chosen animation (open, close, minimize, maximize, show desktop)
// only when a "Test" button is pressed — nothing runs while idle.
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property string curveName: U.v(app, "Animations", "curve", "smooth")
    function easing(opening) {
        if (curveName === "snappy") return opening ? Easing.OutExpo : Easing.InExpo;
        if (curveName === "spring") return opening ? Easing.OutBack : Easing.InBack;
        return opening ? Easing.OutCubic : Easing.InCubic;
    }
    function ms(key, def) { return U.n(app, "Animations", key, def) * 100 / U.n(app, "Animations", "speed", 100); }

    Backdrop { anchors.fill: parent; app: r.app }
    // taskbar with the window's icon (target of the "icon" minimize)
    Rectangle {
        anchors.bottom: parent.bottom; width: parent.width; height: 24; color: Qt.rgba(0.1, 0.11, 0.13, 0.85)
        Rectangle { id: taskIcon; x: parent.width * 0.42; anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; radius: 4; color: "#5b8def" }
    }
    Rectangle {
        id: win
        readonly property rect home: Qt.rect(r.width * 0.28, r.height * 0.14, r.width * 0.44, r.height * 0.58)
        x: home.x; y: home.y; width: home.width; height: home.height
        radius: 10; color: Qt.rgba(0.13, 0.14, 0.17, 0.95); border.color: Qt.rgba(1, 1, 1, 0.1)
        transformOrigin: Item.Center
        Rectangle { width: parent.width; height: 26; radius: 10; color: Qt.rgba(1, 1, 1, 0.06)
            Row { x: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                Repeater { model: ["#ff5f57", "#febc2e", "#28c840"]; Rectangle { width: 10; height: 10; radius: 5; color: modelData } } } }
        Column { x: 14; y: 40; spacing: 8; Repeater { model: 4; Rectangle { width: win.width * (0.7 - index * 0.1); height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.15) } } }
    }
    function reset() {
        anim.stop(); win.opacity = 1; win.scale = 1;
        win.x = win.home.x; win.y = win.home.y; win.width = win.home.width; win.height = win.home.height;
    }
    // plays: kind = open | close | minimize | maximize | desktop
    function play(kind) {
        reset();
        const style = U.v(app, "Animations", kind + "_style", "");
        if (style === "none") return;
        anim.kind = kind; anim.style = style; anim.start();
    }
    SequentialAnimation {
        id: anim
        property string kind
        property string style
        ScriptAction { script: r.setup(anim.kind, anim.style) }
        ParallelAnimation {
            NumberAnimation { target: win; property: "opacity"; to: r.target.op; duration: r.target.ms; easing.type: r.target.ease }
            NumberAnimation { target: win; property: "scale"; to: r.target.s; duration: r.target.ms; easing.type: r.target.ease }
            NumberAnimation { target: win; property: "x"; to: r.target.x; duration: r.target.ms; easing.type: r.target.ease }
            NumberAnimation { target: win; property: "y"; to: r.target.y; duration: r.target.ms; easing.type: r.target.ease }
            NumberAnimation { target: win; property: "width"; to: r.target.w; duration: r.target.ms; easing.type: r.target.ease }
            NumberAnimation { target: win; property: "height"; to: r.target.h; duration: r.target.ms; easing.type: r.target.ease }
        }
        PauseAnimation { duration: 500 }
        ScriptAction { script: r.reset() }
    }
    property var target: ({ op: 1, s: 1, x: 0, y: 0, w: 0, h: 0, ms: 200, ease: Easing.OutCubic })
    function setup(kind, style) {
        const h = win.home;
        let t = { op: 1, s: 1, x: h.x, y: h.y, w: h.width, h: h.height, ms: 250, ease: easing(true) };
        if (kind === "open") {   // start state, then grow back to normal
            t.ms = ms("open_ms", 220);
            const s0 = style === "zoom" ? 0.6 : style === "pop" ? 0.85 : style === "fade" || style === "glide" ? 1 : 0.92;
            win.opacity = 0; win.scale = s0; if (style === "glide") win.y = h.y + 40;
            t.ease = style === "pop" ? Easing.OutBack : easing(true);
        } else if (kind === "close") {
            t.ms = ms("close_ms", 180); t.op = 0; t.ease = easing(false);
            t.s = style === "zoom" ? 0.6 : style === "pop" ? 0.85 : style === "fade" || style === "glide" ? 1 : 0.92;
            if (style === "glide") t.y = h.y + 40;
        } else if (kind === "minimize") {
            t.ms = ms("minimize_ms", 360); t.op = 0; t.ease = Easing.InOutCubic;
            if (style === "icon") { t.s = 0.05; t.x = taskIcon.x + 8 - h.width / 2; t.y = r.height - 12 - h.height / 2; }
            else if (style === "scale") t.s = 0.7;
            else if (style === "drop") { t.s = 0.9; t.y = r.height; }
        } else if (kind === "maximize") {
            t.ms = ms("maximize_ms", 280);
            if (style === "fade") { win.opacity = 0.35; t.op = 1; }
            t.x = 0; t.y = 0; t.w = r.width; t.h = r.height - 24;
        } else if (kind === "desktop") {
            t.ms = ms("desktop_ms", 320); t.op = 0; t.ease = Easing.InOutCubic;
            if (style === "corners") { t.x = r.width - r.width / 16; t.y = -h.height + r.height / 16; }
            else if (style === "slide") t.x = r.width + 20;
            else if (style === "sink") { t.s = 0.88; t.y = h.y + h.height * 0.04; }
        }
        target = t;
    }
}
