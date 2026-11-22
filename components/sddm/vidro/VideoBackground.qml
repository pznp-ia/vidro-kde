// Vidro — video background (login and lock screen). Kept in its own file and loaded with a Loader:
// if QtMultimedia is missing, only this part fails and the photo background stays.
import QtQuick
import QtMultimedia
import QtQuick.Effects

Item {
    id: vb
    property url source
    property real speed: 1.0
    property bool blurred: false
    property real blurAmount: 0.5        // 0-1
    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState && player.hasVideo
    MediaPlayer {
        id: player
        source: vb.source
        loops: MediaPlayer.Infinite
        playbackRate: vb.speed
        videoOutput: out
        audioOutput: null
        Component.onCompleted: play()
    }
    VideoOutput {
        id: out
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: !vb.blurred
        opacity: vb.playing ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }
    MultiEffect {
        anchors.fill: parent
        source: out
        visible: vb.blurred
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: vb.blurAmount
        opacity: vb.playing ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }
}
