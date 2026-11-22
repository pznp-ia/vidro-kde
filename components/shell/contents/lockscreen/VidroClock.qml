/*
    Vidro — relógio fino e elegante para a tela de bloqueio.
*/
import QtQuick
import QtQuick.Layouts

import org.kde.plasma.clock as PlasmaClock
import org.kde.kirigami as Kirigami
import "VidroOptions.js" as VO

ColumnLayout {
    id: root
    spacing: 0

    // scale (the lock screen shrinks the clock a little when the card appears)
    property real escala: 1.0
    readonly property bool alignLeftV: VO.on && VO.alignLeft
    readonly property string family: VO.on && VO.font ? VO.font : Kirigami.Theme.defaultFont.family

    Text {
        Layout.alignment: root.alignLeftV ? Qt.AlignLeft : Qt.AlignHCenter
        text: !VO.on ? Qt.locale().toString(timeSource.dateTime, "HH:mm")
            : Qt.locale("en_US").toString(timeSource.dateTime, (VO.clock12h ? "h:mm" : "HH:mm") + (VO.clockSeconds ? ":ss" : "") + (VO.clock12h ? " AP" : ""))
        color: "#f4f6fa"
        font.family: root.family
        font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 8.5 * root.escala * (VO.on ? VO.clockScale : 1))
        font.weight: !VO.on ? Font.ExtraLight : ({ "ExtraLight": Font.ExtraLight, "Light": Font.Light, "Normal": Font.Normal, "DemiBold": Font.DemiBold, "Bold": Font.Bold })[VO.clockWeight] || Font.ExtraLight
        font.letterSpacing: -2
        font.features: { "tnum": 1 }
        renderType: Text.QtRendering
        antialiasing: true
    }
    Text {
        Layout.alignment: root.alignLeftV ? Qt.AlignLeft : Qt.AlignHCenter
        Layout.topMargin: -Kirigami.Units.smallSpacing
        visible: !VO.on || VO.showDate
        text: {
            const s = Qt.locale().toString(timeSource.dateTime, "dddd, d 'de' MMMM");
            return s.charAt(0).toUpperCase() + s.slice(1);
        }
        color: Qt.rgba(0.96, 0.97, 0.98, 0.72)
        font.family: root.family
        font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.45)
        font.weight: Font.Normal
        font.letterSpacing: 0.6
        renderType: Text.QtRendering
    }

    PlasmaClock.Clock {
        id: timeSource
        trackSeconds: VO.on && VO.clockSeconds
    }
}
