// Preview: taskbar (height, floating, position, alignment, glass, icons, clock)
import QtQuick
import "Util.js" as U
Item {
    id: r
    property var app
    readonly property real alt: Math.max(18, U.n(app, "Panel", "height", 44) * 0.6)
    readonly property bool floating: U.b(app, "Panel", "floating", true)
    readonly property string pos: U.v(app, "Panel", "location", "bottom")
    readonly property bool horiz: pos === "bottom" || pos === "top"
    readonly property bool fit: U.v(app, "Panel", "length", "fill") === "fit"
    readonly property string align: U.v(app, "Panel", "alignment", "center")
    readonly property bool glass: U.b(app, "Panel", "glass_enabled", false)
    readonly property real radius: glass ? U.n(app, "Panel", "glass_radius", 6) : 6
    readonly property real op: glass ? U.n(app, "Panel", "glass_opacity", 42) / 100 : (U.v(app, "Panel", "opacity", "translucent") === "opaque" ? 0.95 : 0.42)
    readonly property real outline: glass ? U.n(app, "Panel", "glass_border", 0) / 100 : 0
    readonly property color glassColor: (glass && U.v(app, "Panel", "glass_background", "theme") === "custom") ? U.color(U.v(app, "Panel", "glass_color", "#1c1e24")) : "#202326"
    readonly property real gap: 4 + U.n(app, "Panel", "icon_spacing", 1) * 4
    readonly property int seconds: Number(U.v(app, "Panel", "clock_seconds", "1"))
    readonly property bool showDate: U.b(app, "Panel", "clock_date", true)
    readonly property int hours: Number(U.v(app, "Panel", "hour_format", "1"))
    readonly property bool bold: U.b(app, "Panel", "clock_bold", false)
    readonly property var swatches: ["#5b8def", "#e5534b", "#3fb950", "#d29922", "#bc8cff", "#58a6ff"]
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: r.now = new Date() }
    Backdrop { anchors.fill: parent; app: r.app }
    readonly property real m: floating ? 8 : 0
    Rectangle {
        id: bar
        readonly property real comp: r.fit ? content.implicitWidth + 20 : (r.horiz ? r.width - 2 * r.m : r.height - 2 * r.m)
        width: r.horiz ? comp : r.alt
        height: r.horiz ? r.alt : comp
        x: r.pos === "left" ? r.m : r.pos === "right" ? r.width - width - r.m
           : r.align === "left" ? r.m : r.align === "right" ? r.width - width - r.m : (r.width - width) / 2
        y: r.pos === "top" ? r.m : r.pos === "bottom" ? r.height - height - r.m
           : r.align === "left" ? r.m : r.align === "right" ? r.height - height - r.m : (r.height - height) / 2
        radius: r.floating || r.glass ? r.radius : 0
        color: Qt.rgba(r.glassColor.r, r.glassColor.g, r.glassColor.b, r.op)
        border.color: Qt.rgba(1, 1, 1, r.outline)
        Flow {
            id: content
            anchors.fill: parent; anchors.margins: 6
            flow: r.horiz ? Flow.LeftToRight : Flow.TopToBottom
            spacing: r.gap
            Rectangle { width: r.alt - 12; height: width; radius: width / 2; color: "white"; opacity: 0.9 }
            Repeater { model: 5; Rectangle { width: r.alt - 12; height: width; radius: 5; color: r.swatches[index]; opacity: 0.9 } }
            Text {
                visible: r.horiz
                color: "white"; font.pixelSize: Math.max(9, r.alt * 0.34); font.bold: r.bold
                text: Qt.formatTime(r.now, (r.hours === 0 ? "h:mm" : "HH:mm") + (r.seconds === 2 ? ":ss" : "") + (r.hours === 0 ? " AP" : ""))
                      + (r.showDate ? "  " + Qt.formatDate(r.now, "dd/MM/yyyy") : "")
            }
        }
    }
}
