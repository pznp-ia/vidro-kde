// Vidro Weather: static layout, no running animations or timers. The weather engine
// polls the provider every `updateMinutes`; the view repaints only when data changes.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    readonly property string source: Plasmoid.configuration.place !== ""
        ? Plasmoid.configuration.provider + "|weather|" + Plasmoid.configuration.place : ""
    property var data: ({})            // latest engine data (only replaced when it changes)
    readonly property bool ready: data["Temperature"] !== undefined || data["Current Conditions"] !== undefined

    P5Support.DataSource {
        id: engine
        engine: "weather"
        connectedSources: root.source !== "" ? [root.source] : []
        interval: Plasmoid.configuration.updateMinutes * 60 * 1000
        intervalAlignment: P5Support.Types.NoAlignment
        onNewData: (sourceName, d) => { if (sourceName === root.source) root.data = d; }
    }

    function num(v) { if (v === undefined || v === null || v === "" || v === "N/A") return null; const n = Number(v); return isNaN(n) ? null : Math.round(n); }
    function temp(v) { const n = num(v); return n === null ? "–" : n + "°"; }
    function icon(name) { return name && name !== "N/A" && name !== "weather-none-available" ? name : ""; }
    // current icon: the provider sometimes omits it; fall back to today's forecast icon
    readonly property string currentIcon: icon(data["Condition Icon"]) || (forecast.length ? icon(forecast[0].icon) : "") || "weather-none-available"
    readonly property var forecast: {
        const out = [];
        const total = Number(data["Total Weather Days"] || 0);
        for (let i = 0; i < Math.min(total, Plasmoid.configuration.days); i++) {
            const p = String(data["Short Forecast Day " + i] || "").split("|");
            if (p.length >= 5) out.push({ day: p[0], icon: p[1], text: p[2], high: p[3], low: p[4] });
        }
        return out;
    }
    readonly property string place: Plasmoid.configuration.placeName || data["Place"] || ""

    toolTipMainText: place
    toolTipSubText: ready ? temp(data["Temperature"]) + " · " + (data["Current Conditions"] || "") : "Sem dados"
    Plasmoid.icon: currentIcon

    compactRepresentation: MouseArea {
        Layout.minimumWidth: row.implicitWidth
        onClicked: root.expanded = !root.expanded
        RowLayout {
            id: row
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing
            Kirigami.Icon { source: root.currentIcon; Layout.fillHeight: true; Layout.preferredWidth: height }
            PC3.Label { text: root.temp(root.data["Temperature"]); visible: root.ready }
        }
    }

    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: implicitHeight
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        spacing: Kirigami.Units.largeSpacing

        PC3.Label {
            visible: root.source === ""
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: "Escolha a cidade nas configurações do widget."
        }
        // current conditions
        RowLayout {
            visible: root.source !== ""
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon {
                source: root.currentIcon
                Layout.preferredWidth: Kirigami.Units.iconSizes.huge; Layout.preferredHeight: Layout.preferredWidth
            }
            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                PC3.Label { text: root.temp(root.data["Temperature"]); font.pixelSize: Kirigami.Units.gridUnit * 2.6; font.weight: Font.Light }
                PC3.Label { text: root.data["Current Conditions"] || (root.ready ? "" : "Carregando…"); opacity: 0.8; elide: Text.ElideRight; Layout.fillWidth: true }
            }
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignTop
                PC3.Label { text: root.place; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignRight; Layout.alignment: Qt.AlignRight }
                PC3.Label {
                    visible: Plasmoid.configuration.showDetails && root.data["Humidity"] !== undefined
                    text: "Umidade " + root.num(root.data["Humidity"]) + "%"
                    opacity: 0.65; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignRight
                }
                PC3.Label {
                    visible: Plasmoid.configuration.showDetails && root.data["Wind Speed"] !== undefined && root.data["Wind Speed"] !== "N/A"
                    text: "Vento " + root.num(root.data["Wind Speed"]) + " " + (root.data["Wind Direction"] || "")
                    opacity: 0.65; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignRight
                }
            }
        }
        Rectangle { visible: root.forecast.length > 0; Layout.fillWidth: true; height: 1; color: Kirigami.Theme.textColor; opacity: 0.1 }
        // forecast
        RowLayout {
            visible: root.forecast.length > 0
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: root.forecast
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    PC3.Label { text: modelData.day; opacity: 0.7; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                    Kirigami.Icon { source: root.icon(modelData.icon) || "weather-none-available"; Layout.preferredWidth: Kirigami.Units.iconSizes.medium; Layout.preferredHeight: Layout.preferredWidth; Layout.alignment: Qt.AlignHCenter }
                    PC3.Label { text: root.temp(modelData.high); visible: root.num(modelData.high) !== null; Layout.alignment: Qt.AlignHCenter }
                    PC3.Label { text: root.temp(modelData.low); opacity: 0.55; font: Kirigami.Theme.smallFont; Layout.alignment: Qt.AlignHCenter }
                }
            }
        }
    }
}
