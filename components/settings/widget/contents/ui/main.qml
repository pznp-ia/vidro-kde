// Vidro Settings — app (plasmawindowed org.vidro.config) and widget. The content is in common/SettingsPanel.qml.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "common"

PlasmoidItem {
    id: root
    Plasmoid.icon: "preferences-desktop-theme"
    toolTipMainText: "Configurações do Vidro"
    preferredRepresentation: (Plasmoid.formFactor === PlasmaCore.Types.Planar || Plasmoid.formFactor === PlasmaCore.Types.Application) ? fullRepresentation : compactRepresentation

    compactRepresentation: Kirigami.Icon {
        source: "preferences-desktop-theme"
        MouseArea { anchors.fill: parent; onClicked: root.expanded = !root.expanded }
    }
    fullRepresentation: SettingsPanel {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 46
        Layout.preferredHeight: Kirigami.Units.gridUnit * 36
        Layout.minimumWidth: Kirigami.Units.gridUnit * 34
        Layout.minimumHeight: Kirigami.Units.gridUnit * 16
    }
}
