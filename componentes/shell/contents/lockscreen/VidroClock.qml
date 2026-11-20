/*
    Vidro — relógio fino e elegante para a tela de bloqueio.
*/
import QtQuick
import QtQuick.Layouts

import org.kde.plasma.clock as PlasmaClock
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root
    spacing: 0

    // escala (o bloqueio encolhe um pouco o relógio quando o cartão aparece)
    property real escala: 1.0

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.locale().toString(timeSource.dateTime, "HH:mm")
        color: "#f4f6fa"
        font.family: Kirigami.Theme.defaultFont.family
        font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 8.5 * root.escala)
        font.weight: Font.ExtraLight
        font.letterSpacing: -2
        font.features: { "tnum": 1 }
        renderType: Text.QtRendering
        antialiasing: true
    }
    Text {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: -Kirigami.Units.smallSpacing
        text: {
            const s = Qt.locale().toString(timeSource.dateTime, "dddd, d 'de' MMMM");
            return s.charAt(0).toUpperCase() + s.slice(1);
        }
        color: Qt.rgba(0.96, 0.97, 0.98, 0.72)
        font.family: Kirigami.Theme.defaultFont.family
        font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.45)
        font.weight: Font.Normal
        font.letterSpacing: 0.6
        renderType: Text.QtRendering
    }

    PlasmaClock.Clock {
        id: timeSource
        trackSeconds: false
    }
}
