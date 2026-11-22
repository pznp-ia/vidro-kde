// Section: profiles — save/restore the whole look (uses ~/.local/bin/vidro-profile)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Perfis"
    icon: "bookmarks"
    description: "Guarde o visual inteiro (todas as opções do Vidro e o papel de parede) com um nome e volte a ele quando quiser. Ao carregar um perfil, o visual de agora é guardado sozinho como \"auto-…\", então nada se perde."
    property var profiles: []
    property string message: ""
    property bool busy: false
    readonly property string bin: "$HOME/.local/bin/vidro-profile "

    function refresh() { exec.connectSource(bin + "json #list" + Date.now()); }
    function run(args, tag) { busy = true; exec.connectSource(bin + args + " 2>&1 #" + tag + Date.now()); }
    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            const out = String(data["stdout"] || "").trim();
            if (source.indexOf("#list") >= 0) {
                try { s.profiles = JSON.parse(out); } catch (e) { s.profiles = []; }
            } else {
                s.busy = false;
                s.message = (data["exit code"] === 0 ? "" : "Erro: ") + out.split("\n").slice(-1)[0];
                if (source.indexOf("#load") >= 0 && s.app) s.app.reload();
                s.refresh();
            }
            disconnectSource(source);
        }
    }
    Component.onCompleted: refresh()

    RowLayout {
        Kirigami.FormData.label: "Salvar o visual atual:"
        QQC2.TextField { id: newName; placeholderText: "nome do perfil"; implicitWidth: Kirigami.Units.gridUnit * 12; onAccepted: saveButton.clicked() }
        QQC2.Button { id: saveButton; text: "Salvar"; icon.name: "document-save"; enabled: newName.text.trim() !== "" && !s.busy
            onClicked: { s.run("save " + s.app.quote(newName.text.trim()), "save"); newName.text = ""; } }
    }
    QQC2.Label { Kirigami.FormData.label: ""; visible: s.message !== ""; text: s.message; opacity: 0.7; wrapMode: Text.WordWrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 24 }
    QQC2.BusyIndicator { Kirigami.FormData.label: ""; visible: s.busy; running: s.busy; implicitHeight: Kirigami.Units.iconSizes.medium }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Perfis guardados" }
    QQC2.Label { Kirigami.FormData.label: ""; visible: s.profiles.length === 0; text: "Nenhum perfil ainda."; opacity: 0.6 }
    Repeater {
        model: s.profiles
        RowLayout {
            Kirigami.FormData.label: modelData.auto ? "automático:" : ""
            QQC2.Label { text: modelData.name; font.bold: !modelData.auto; Layout.preferredWidth: Kirigami.Units.gridUnit * 11; elide: Text.ElideRight }
            QQC2.Label { text: String(modelData.created).replace("T", " ").slice(0, 16); opacity: 0.55; Layout.preferredWidth: Kirigami.Units.gridUnit * 7 }
            QQC2.Button { text: "Carregar"; icon.name: "document-open"; enabled: !s.busy; onClicked: s.run("load " + s.app.quote(modelData.name), "load") }
            QQC2.Button { icon.name: "edit-delete"; enabled: !s.busy; QQC2.ToolTip.text: "Apagar"; QQC2.ToolTip.visible: hovered
                onClicked: s.run("delete " + s.app.quote(modelData.name), "delete") }
        }
    }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Compartilhar" }
    RowLayout {
        Kirigami.FormData.label: "Exportar:"
        QQC2.ComboBox { id: exportName; model: s.profiles.map(p => p.name); implicitWidth: Kirigami.Units.gridUnit * 10 }
        QQC2.Button { text: "Salvar em Downloads"; icon.name: "document-export"; enabled: exportName.currentText !== "" && !s.busy
            onClicked: s.run("export " + s.app.quote(exportName.currentText) + " \"$HOME/Downloads/vidro-" + exportName.currentText.replace(/[^\w.-]/g, "_") + ".json\"", "export") }
    }
    RowLayout {
        Kirigami.FormData.label: "Importar:"
        QQC2.TextField { id: importPath; placeholderText: "/caminho/do/perfil.json"; implicitWidth: Kirigami.Units.gridUnit * 14 }
        QQC2.Button { text: "Importar"; icon.name: "document-import"; enabled: importPath.text.trim() !== "" && !s.busy
            onClicked: { s.run("import " + s.app.quote(importPath.text.trim()), "import"); importPath.text = ""; } }
    }
}
