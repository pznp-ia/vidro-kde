import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    readonly property int level: Plasmoid.configuration.level

    Plasmoid.icon: "contrast"
    Plasmoid.status: PlasmaCore.Types.ActiveStatus
    toolTipMainText: "Vidro"
    toolTipSubText: level + "% · role o mouse para ajustar · clique direito: Configurações do Vidro"

    function setLevel(v) {
        v = Math.max(0, Math.min(100, Math.round(v / 5) * 5));
        if (v === Plasmoid.configuration.level) return;
        Plasmoid.configuration.level = v;
        applyTimer.restart();
    }

    P5Support.DataSource {
        id: runner
        engine: "executable"
        onNewData: (source) => disconnectSource(source)
    }
    Timer {
        id: applyTimer
        interval: 60
        onTriggered: runner.connectSource("$HOME/.local/bin/vidro-transparencia " + root.level)
    }

    compactRepresentation: MouseArea {
        acceptedButtons: Qt.LeftButton
        onClicked: root.expanded = !root.expanded
        onWheel: (wheel) => root.setLevel(root.level + (wheel.angleDelta.y > 0 ? 5 : -5))
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
        Layout.maximumWidth: Kirigami.Units.iconSizes.smallMedium
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small
            height: width
            source: "contrast"
            active: parent.containsMouse
            opacity: 0.55 + 0.45 * root.level / 100
        }
        hoverEnabled: true
    }

    function abrirConfiguracoes() { runner.connectSource("plasmawindowed org.vidro.config >/dev/null 2>&1 & #" + Date.now()); root.expanded = false }

    // clique direito no ícone → "Configurações do Vidro…"
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Configurações do Vidro…"
            icon.name: "preferences-desktop-theme"
            onTriggered: root.abrirConfiguracoes()
        }
    ]

    // clique esquerdo: ajuste rápido da transparência + atalho para as configurações
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 13
        Layout.minimumWidth: Kirigami.Units.gridUnit * 13
        Layout.maximumWidth: Kirigami.Units.gridUnit * 13
        spacing: Kirigami.Units.smallSpacing
        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents.Label { text: "Transparência"; opacity: 0.8 }
            PlasmaComponents.Slider {
                Layout.fillWidth: true
                from: 0; to: 100; stepSize: 5
                value: root.level
                onMoved: root.setLevel(value)
            }
            PlasmaComponents.Label {
                text: root.level + "%"
                opacity: 0.7
                font: Kirigami.Theme.smallFont
                Layout.minimumWidth: Kirigami.Units.gridUnit * 1.8
                horizontalAlignment: Text.AlignRight
            }
        }
        PlasmaComponents.Button {
            Layout.fillWidth: true
            text: "Configurações do Vidro…"
            icon.name: "preferences-desktop-theme"
            onClicked: root.abrirConfiguracoes()
        }
    }
}
