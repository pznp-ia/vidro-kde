// Vidro Settings: tabs on the side (one per file in ../sections/*.qml) and content on the right.
// Each section gets "app" (this panel): app.cfg[Group][key], app.set(Group, key, value), app.run(cmd),
// app.home (home folder), app.version (changes after every apply — to reload images).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

Item {
    id: app
    property var cfg: ({})
    property var sections: []
    property bool ready: false
    property var pending: ({})
    property string home: ""
    property int version: 0
    property bool showTitle: true   // compatibilidade
    readonly property string sectionsFolder: Qt.resolvedUrl("../sections").toString().replace("file://", "")

    function run(cmd) { exec.connectSource(cmd) }
    function quote(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function set(g, k, v) {
        const novo = Object.assign({}, cfg);
        novo[g] = Object.assign({}, cfg[g] || {});
        novo[g][k] = String(v);
        cfg = novo;
        pending[g + "\u0001" + k] = String(v);
        saveTimer.restart();
    }
    function reload() { exec.connectSource(cmdJson); exec.connectSource(cmdSections); exec.connectSource(cmdHome); }
    readonly property string cmdJson: "$HOME/.local/bin/vidro-config json"
    readonly property string cmdSections: "ls " + quote(sectionsFolder) + " #secoes"
    readonly property string cmdHome: "echo $HOME #home"
    property int seq: 0
    // sidebar groups; a section file goes to the group whose prefix list contains its number
    readonly property var categories: [
        { name: "general", label: "Geral", files: ["05"] },
        { name: "windows", label: "Janelas", files: ["10", "12", "14"] },
        { name: "apps", label: "Aplicativos", files: ["13", "20", "22", "27", "30", "40", "60", "65"] },
        { name: "desktop", label: "Área de trabalho", files: ["23", "24", "28", "26", "26a", "26b", "80", "70"] },
        { name: "system", label: "Sistema", files: ["90"] }
    ]
    property var openCategories: ["general", "windows"]
    function categoryOf(file) {
        const prefix = String(file).split("-")[0];
        for (const c of categories) if (c.files.indexOf(prefix) >= 0) return c.name;
        return "system";
    }
    function sectionsIn(name) {
        const out = [];
        for (let i = 0; i < sections.length; i++) if (categoryOf(sections[i]) === name) out.push(i);
        return out;
    }
    function toggleCategory(name) {
        const l = openCategories.slice(), i = l.indexOf(name);
        if (i >= 0) l.splice(i, 1); else l.push(name);
        openCategories = l;
    }
    function revealCurrent() {   // keep the group of the open tab expanded
        if (!sections.length) return;
        const c = categoryOf(sections[current] || "");
        if (openCategories.indexOf(c) < 0) toggleCategory(c);
    }
    onCurrentChanged: revealCurrent()
    onSectionsChanged: revealCurrent()
    property int current: 0

    Timer {
        id: saveTimer; interval: 250
        onTriggered: {
            for (const key in app.pending) {
                const p = key.split("\u0001");
                app.seq += 1;
                app.run("$HOME/.local/bin/vidro-config set " + app.quote(p[0]) + " " + app.quote(p[1]) + " " + app.quote(app.pending[key]) + " --apply #apply" + app.seq);
            }
            app.pending = ({});
        }
    }
    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            if (source === app.cmdJson) {
                try { app.cfg = JSON.parse(data["stdout"]); } catch (e) { app.cfg = ({}); }
                app.ready = true;
            } else if (source === app.cmdSections) {
                app.sections = data["stdout"].split("\n").filter(s => s.endsWith(".qml"));
            } else if (source === app.cmdHome) {
                app.home = data["stdout"].trim();
            } else if (source.indexOf("#apply") >= 0) {
                app.version += 1;
            }
            disconnectSource(source);
        }
    }
    Component.onCompleted: reload()

    RowLayout {
        anchors.fill: parent
        spacing: 0
        // ---- abas ----
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.04)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: 2
                Kirigami.Heading { text: "Vidro"; level: 2; Layout.margins: Kirigami.Units.largeSpacing }
                // grouped, scrollable tab list: category headers open/close their tabs
                QQC2.ScrollView {
                    id: tabScroller
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
                    ColumnLayout {
                        width: tabScroller.availableWidth
                        spacing: 1
                        Repeater {
                            model: app.categories
                            ColumnLayout {
                                id: cat
                                Layout.fillWidth: true
                                spacing: 1
                                readonly property var members: app.sectionsIn(modelData.name)
                                readonly property bool open: app.openCategories.indexOf(modelData.name) >= 0
                                visible: members.length > 0
                                QQC2.ItemDelegate {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    icon.name: cat.open ? "arrow-down" : "arrow-right"
                                    font.bold: true
                                    onClicked: app.toggleCategory(modelData.name)
                                }
                                Repeater {
                                    model: cat.open ? cat.members : []
                                    QQC2.ItemDelegate {
                                        Layout.fillWidth: true
                                        Layout.leftMargin: Kirigami.Units.largeSpacing
                                        // depends on the repeater count so it updates once the tabs have loaded
                                        readonly property var sec: sectionsRepeater.count > modelData && sectionsRepeater.itemAt(modelData) ? sectionsRepeater.itemAt(modelData).item : null
                                        text: sec ? sec.title : ""
                                        icon.name: sec ? sec.icon : ""
                                        highlighted: app.current === modelData
                                        visible: !!sec
                                        onClicked: app.current = modelData
                                    }
                                }
                            }
                        }
                    }
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    text: "Recarregar Plasma"
                    icon.name: "view-refresh"
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: "Reinicia o painel/área de trabalho e recarrega o KWin para aplicar tudo (a tela pisca por 2 segundos)."
                    onClicked: app.run("(dbus-send --session --type=method_call --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure; systemctl --user restart plasma-plasmashell.service) >/dev/null 2>&1 & #recarregar" + Date.now())
                }
                QQC2.Label {
                    text: "Barra, menus e Dolphin: apps já abertos mudam ao reabrir."
                    wrapMode: Text.WordWrap; opacity: 0.55; font: Kirigami.Theme.smallFont
                    Layout.fillWidth: true; Layout.margins: Kirigami.Units.smallSpacing
                }
            }
        }
        Kirigami.Separator { Layout.fillHeight: true; opacity: 0.3 }
        // ---- content ----
        QQC2.ScrollView {
            id: scroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            ColumnLayout {
                width: scroller.availableWidth
                Repeater {
                    id: sectionsRepeater
                    model: app.ready ? app.sections : []
                    delegate: Loader {
                        Layout.fillWidth: true
                        visible: app.current === index
                        source: Qt.resolvedUrl("../sections/" + modelData)
                        onLoaded: item.app = app
                    }
                }
                Item { Layout.preferredHeight: Kirigami.Units.largeSpacing }
            }
        }
    }
}
