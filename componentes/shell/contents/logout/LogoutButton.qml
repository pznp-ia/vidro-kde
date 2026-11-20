/*
    Vidro — botão do logout: círculo de vidro + legenda discreta.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "timer.js" as AutoTriggerTimer

VidroAction {
    Layout.alignment: Qt.AlignTop
    tamanho: Kirigami.Units.gridUnit * 3.4
    Keys.onPressed: (event) => {
        AutoTriggerTimer.cancelAutoTrigger();
        event.accepted = false;
    }
}
