// Blurred wallpaper (made by vidro-titlebar) as the preview background; a gradient if missing.
import QtQuick
Item {
    property var app
    Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "#24324f" } GradientStop { position: 1; color: "#7a3f2a" } } }
    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        source: (app && app.home) ? "file://" + app.home + "/.cache/vidro/blurred-wallpaper.jpg" : ""
    }
}
