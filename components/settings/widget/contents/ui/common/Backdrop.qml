// Preview background: the current wallpaper (copy made by vidro-titlebar); blurred copy or a gradient if missing.
import QtQuick
Item {
    id: bd
    property var app
    property bool blurred: false
    readonly property string base: (app && app.home) ? "file://" + app.home + "/.cache/vidro/" : ""
    Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "#24324f" } GradientStop { position: 1; color: "#7a3f2a" } } }
    Image {
        id: blur
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: bd.blurred || sharp.status !== Image.Ready
        source: bd.base ? bd.base + "blurred-wallpaper.jpg" : ""
    }
    Image {
        id: sharp
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: !bd.blurred && status === Image.Ready
        sourceSize.width: 1600
        source: bd.base ? bd.base + "wallpaper.jpg" : ""
    }
}
