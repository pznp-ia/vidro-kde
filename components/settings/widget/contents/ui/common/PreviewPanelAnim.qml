// Preview: the taskbar hiding and appearing in a loop with the chosen styles, durations and curve.
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    clip: true
    readonly property string showStyle: U.v(app, "PanelAnimation", "show_style", "slide")
    readonly property string hideStyle: U.v(app, "PanelAnimation", "hide_style", "slide")
    readonly property int showMs: U.n(app, "PanelAnimation", "show_ms", 260)
    readonly property int hideMs: U.n(app, "PanelAnimation", "hide_ms", 200)
    readonly property real dist: U.n(app, "PanelAnimation", "distance", 100) / 100
    readonly property real startScale: U.n(app, "PanelAnimation", "scale", 90) / 100
    readonly property bool on: U.b(app, "PanelAnimation", "enabled", true)
    readonly property string curve: U.v(app, "PanelAnimation", "curve", "smooth")
    function ease(showing) {
        if (curve === "snappy") return showing ? Easing.OutExpo : Easing.InExpo;
        if (curve === "spring") return showing ? Easing.OutBack : Easing.InBack;
        if (curve === "linear") return Easing.Linear;
        return showing ? Easing.OutCubic : Easing.InCubic;
    }
    function has(style, what) {
        if (!r.on || style === "none") return false;
        if (what === "move") return ["slide", "slidefade", "rise"].indexOf(style) >= 0;
        if (what === "fade") return ["fade", "slidefade", "scale", "rise"].indexOf(style) >= 0;
        return ["scale", "rise"].indexOf(style) >= 0;
    }
    readonly property real off: (bar.height + 12) * dist
    function play(showing) { loop.stop(); bar.reset(); if (showing) { bar.setHidden(); showAnim.restart(); } else hideAnim.restart(); }

    Backdrop { anchors.fill: parent; app: r.app }
    Rectangle {
        id: bar
        width: parent.width - 24; height: 36; radius: 10
        x: 12; y: parent.height - height - 10
        color: Qt.rgba(0.12, 0.13, 0.15, 0.62); border.color: Qt.rgba(1, 1, 1, 0.12)
        property real ty: 0
        property real sc: 1
        transform: [ Translate { y: bar.ty }, Scale { origin.x: bar.width / 2; origin.y: bar.height; xScale: bar.sc; yScale: bar.sc } ]
        function reset() { ty = 0; sc = 1; opacity = 1; }
        function setHidden() {
            ty = r.has(r.showStyle, "move") ? r.off : 0;
            sc = r.has(r.showStyle, "scale") ? r.startScale : 1;
            opacity = r.has(r.showStyle, "fade") ? 0 : (r.showStyle === "none" || !r.on ? 0 : 1);
        }
        Row {
            anchors.centerIn: parent; spacing: 8
            Repeater { model: ["#5b8def", "#e5534b", "#3fb950", "#d29922", "#bc8cff"]
                Rectangle { width: 22; height: 22; radius: 6; color: modelData; opacity: 0.9 } }
        }
        Text { anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "12:34"; color: "white"; font.pixelSize: 11 }
    }
    // hide: move/fade/scale out, then the panel is gone (no style = disappears at once)
    ParallelAnimation {
        id: hideAnim
        NumberAnimation { target: bar; property: "ty"; to: r.has(r.hideStyle, "move") ? r.off : 0; duration: r.hideMs; easing.type: r.ease(false) }
        NumberAnimation { target: bar; property: "sc"; to: r.has(r.hideStyle, "scale") ? r.startScale : 1; duration: r.hideMs; easing.type: r.ease(false) }
        NumberAnimation { target: bar; property: "opacity"; to: r.has(r.hideStyle, "fade") ? 0 : 1; duration: r.hideMs; easing.type: Easing.InCubic }
        onFinished: bar.setHidden()
    }
    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: bar; property: "ty"; to: 0; duration: r.has(r.showStyle, "move") ? r.showMs : 0; easing.type: r.ease(true) }
        NumberAnimation { target: bar; property: "sc"; to: 1; duration: r.has(r.showStyle, "scale") ? r.showMs : 0; easing.type: r.ease(true) }
        NumberAnimation { target: bar; property: "opacity"; to: 1; duration: r.has(r.showStyle, "fade") ? r.showMs : 0; easing.type: Easing.OutCubic }
    }
    SequentialAnimation {
        id: loop
        running: r.visible; loops: Animation.Infinite
        PauseAnimation { duration: 1300 }
        ScriptAction { script: hideAnim.restart() }
        PauseAnimation { duration: r.hideMs + 700 }
        ScriptAction { script: showAnim.restart() }
        PauseAnimation { duration: r.showMs }
    }
    Text { anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 8
        text: r.on ? "a barra some e volta em loop" : "animação desligada"; color: "white"; opacity: 0.7; font.pixelSize: 11
        style: Text.Outline; styleColor: Qt.rgba(0, 0, 0, 0.4) }
}
