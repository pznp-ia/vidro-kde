// Configurações do Vidro — app (plasmawindowed org.vidro.config) e widget. O conteúdo fica em comum/PainelVidro.qml.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "comum"

PlasmoidItem {
    id: raiz
    Plasmoid.icon: "preferences-desktop-theme"
    toolTipMainText: "Configurações do Vidro"
    preferredRepresentation: (Plasmoid.formFactor === PlasmaCore.Types.Planar || Plasmoid.formFactor === PlasmaCore.Types.Application) ? fullRepresentation : compactRepresentation

    compactRepresentation: Kirigami.Icon {
        source: "preferences-desktop-theme"
        MouseArea { anchors.fill: parent; onClicked: raiz.expanded = !raiz.expanded }
    }
    fullRepresentation: PainelVidro {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 46
        Layout.preferredHeight: Kirigami.Units.gridUnit * 36
        Layout.minimumWidth: Kirigami.Units.gridUnit * 34
        Layout.minimumHeight: Kirigami.Units.gridUnit * 16
    }
}
