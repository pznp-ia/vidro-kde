// Settings: search a place with the weather engine ("<provider>|validate|<text>").
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

Kirigami.FormLayout {
    id: page
    property alias cfg_place: placeField.text
    property alias cfg_placeName: nameField.text
    property string cfg_provider: "bbcukmet"
    property alias cfg_days: daysBox.value
    property alias cfg_showDetails: detailsBox.checked
    property alias cfg_updateMinutes: minutesBox.value
    property var results: []

    P5Support.DataSource {
        id: search
        engine: "weather"
        onNewData: (sourceName, d) => {
            // "<ion>|valid|single|multiple|place|NAME|extra|ID|place|..." → pairs of name + id
            const parts = String(d["validate"] || "").split("|");
            const ion = parts[0];
            const out = [];
            for (let i = 0; i < parts.length; i++) {
                if (parts[i] === "place") {
                    const name = parts[i + 1];
                    const extra = parts[i + 2] === "extra" ? parts[i + 3] : "";
                    out.push({ ion: ion, name: name, place: extra ? name + "|" + extra : name });
                }
            }
            page.results = page.results.concat(out);
            disconnectSource(sourceName);
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Cidade:"
        QQC2.TextField { id: query; placeholderText: "ex.: Lisboa"; onAccepted: go.clicked() }
        QQC2.Button {
            id: go
            text: "Procurar"
            onClicked: {
                page.results = [];
                for (const ion of ["bbcukmet", "wettercom", "dwd", "envcan", "noaa"])
                    search.connectSource(ion + "|validate|" + query.text);
            }
        }
    }
    ListView {
        Kirigami.FormData.label: "Resultados:"
        visible: page.results.length > 0
        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Math.min(contentHeight, Kirigami.Units.gridUnit * 10)
        clip: true
        model: page.results
        delegate: QQC2.ItemDelegate {
            width: ListView.view.width
            text: modelData.name + "  (" + modelData.ion + ")"
            onClicked: { placeField.text = modelData.place; nameField.text = modelData.name; page.cfg_provider = modelData.ion; }
        }
    }
    QQC2.Label { Kirigami.FormData.label: "Escolhida:"; text: nameField.text !== "" ? nameField.text + " (" + page.cfg_provider + ")" : "nenhuma" }
    QQC2.TextField { id: placeField; visible: false }
    QQC2.TextField { id: nameField; visible: false }
    QQC2.SpinBox { id: daysBox; Kirigami.FormData.label: "Dias de previsão:"; from: 0; to: 7 }
    QQC2.CheckBox { id: detailsBox; Kirigami.FormData.label: "Detalhes:"; text: "umidade e vento" }
    QQC2.SpinBox { id: minutesBox; Kirigami.FormData.label: "Atualizar a cada (min):"; from: 10; to: 180; stepSize: 10 }
}
