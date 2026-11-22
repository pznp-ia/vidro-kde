// Section: system sounds (module sounds.py → kdeglobals [Sounds], plasmaparc; Vidro glass set; "My preset")
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Sons do sistema"
    icon: "preferences-desktop-sound"
    description: "Escolha o tema de sons (os instalados, o conjunto \"Vidro\" (minimalista, com entrada e saída no clima dos anos 90), ou o seu próprio preset). Clique em ▶ para ouvir. Muda na hora."
    function v(k) { return (app && app.cfg.Sounds) ? String(app.cfg.Sounds[k]) : "" }
    readonly property string module: "\"$HOME/.local/share/vidro/modules/sounds.py\""
    property var themes: []
    property var events: []
    property var files: ({})
    property bool loading: false
    property string playingKey: ""
    property string status: ""
    function action(args, tag) { status = "Trabalhando…"; exec.connectSource("python3 -I " + module + " " + args + " #" + tag + Date.now()); }
    function urlPath(u) { return decodeURIComponent(String(u).replace(/^file:\/\//, "")); }
    readonly property string theme: v("theme") || "ocean"
    readonly property bool custom: theme === "vidro-custom"

    function load() {
        loading = true;
        exec.connectSource("python3 -I " + module + " --list #sounds-list" + Date.now());
    }
    function play(themeId, event) {
        playingKey = themeId + "/" + event; playTimer.restart();
        exec.connectSource("python3 -I " + module + " --play " + themeId + " " + event + " #sounds-play" + Date.now());
    }
    function playFile(path) {
        exec.connectSource("python3 -I " + module + " --play-file " + s.app.quote(path) + " #sounds-play" + Date.now());
    }
    function themeName(id) { for (const t of themes) if (t.id === id) return t.name; return id; }
    function fileName(p) { return String(p).split("/").pop(); }
    Timer { id: playTimer; interval: 900; onTriggered: s.playingKey = "" }
    Component.onCompleted: load()
    P5Support.DataSource {
        id: exec; engine: "executable"
        onNewData: (source, data) => {
            if (/#sounds-(import|export|save)/.test(source)) {
                const out = String(data["stdout"] || "").trim(), err = String(data["stderr"] || "").trim().split("\n").pop();
                if (data["exit code"] === 0) {
                    if (source.indexOf("#sounds-import") >= 0) { s.status = "Tema importado: " + out; s.app.set("Sounds", "theme", out); }
                    else if (source.indexOf("#sounds-save") >= 0) { s.status = "Preset salvo como tema: " + out; s.app.set("Sounds", "theme", out); }
                    else s.status = "Exportado para " + out;
                    s.load();
                } else s.status = "Não deu certo: " + err;
            } else if (source.indexOf("#sounds-list") >= 0) {
                try {
                    const d = JSON.parse(String(data["stdout"] || "{}"));
                    s.themes = d.themes || []; s.events = d.events || []; s.files = d.files || {};
                } catch (e) {}
                s.loading = false;
            }
            disconnectSource(source);
        }
    }

    Toggle { app: s.app; group: "Sounds"; key: "enabled"; Kirigami.FormData.label: "Sons do sistema:"; text: checked ? "ligados" : "desligados" }
    Toggle { app: s.app; group: "Sounds"; key: "volume_feedback"; Kirigami.FormData.label: "Som ao mudar o volume:"; text: checked ? "sim" : "não" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Tema de sons" }
    RowLayout {
        Kirigami.FormData.label: "Arquivos:"
        QQC2.Button { text: "Importar tema…"; icon.name: "document-import"; onClicked: importDlg.open()
            QQC2.ToolTip.text: "Temas de som comuns (.tar.gz, .tar.xz, .zip ou a pasta com index.theme) ou um pacote de sons soltos (ex.: sons do Windows .wav) — o Vidro tenta reconhecer cada um."
            QQC2.ToolTip.visible: hovered }
        QQC2.Button { text: "Importar pasta…"; icon.name: "folder-open"; onClicked: importFolderDlg.open() }
        QQC2.Button { text: "Exportar este tema…"; icon.name: "document-export"; onClicked: exportDlg.open() }
    }
    QQC2.Label { Kirigami.FormData.label: ""; visible: s.status !== ""; text: s.status; opacity: 0.75; wrapMode: Text.WordWrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 26 }
    FileDialog {
        id: importDlg
        title: "Importar tema de sons"
        nameFilters: ["Temas e sons (*.tar.gz *.tgz *.tar.xz *.tar.bz2 *.zip *.theme *.oga *.ogg *.wav *.flac *.mp3)", "Todos os arquivos (*)"]
        onAccepted: s.action("--import " + s.app.quote(s.urlPath(selectedFile)), "sounds-import")
    }
    FolderDialog {
        id: importFolderDlg
        title: "Pasta com um tema de sons (ou sons soltos)"
        onAccepted: s.action("--import " + s.app.quote(s.urlPath(selectedFolder)), "sounds-import")
    }
    FileDialog {
        id: exportDlg
        title: "Exportar o tema \"" + s.themeName(s.theme) + "\""
        fileMode: FileDialog.SaveFile
        defaultSuffix: "tar.gz"
        selectedFile: "file://" + (s.app ? s.app.home : "") + "/" + s.theme + ".tar.gz"
        nameFilters: ["Tema de sons (*.tar.gz)"]
        onAccepted: s.action("--export " + s.theme + " " + s.app.quote(s.urlPath(selectedFile)), "sounds-export")
    }
    QQC2.Label { Kirigami.FormData.label: ""; visible: s.loading; text: "Procurando os temas instalados…"; opacity: 0.6 }
    Flow {
        Kirigami.FormData.label: "Instalados:"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 27
        spacing: 6
        Repeater {
            model: s.themes
            Rectangle {
                required property var modelData
                readonly property bool chosen: s.theme === modelData.id
                width: 200; height: 58; radius: 10
                color: chosen ? Qt.rgba(0.24, 0.68, 0.91, 0.30) : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.04))
                border.width: chosen ? 2 : 1; border.color: chosen ? Kirigami.Theme.highlightColor : Qt.rgba(1, 1, 1, 0.08)
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: s.app.set("Sounds", "theme", modelData.id) }
                Column {
                    x: 12; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60
                    QQC2.Label { text: modelData.id === "vidro" ? "✦ Vidro" : modelData.name; font.bold: true; elide: Text.ElideRight; width: parent.width }
                    QQC2.Label { opacity: 0.6; font.pointSize: Kirigami.Theme.smallFont.pointSize; elide: Text.ElideRight; width: parent.width
                        text: modelData.id === "vidro" ? "minimalista; entrar e sair com clima anos 90"
                            : modelData.id === "vidro-custom" ? "você escolhe cada som"
                            : modelData.own + " de " + s.events.length + " sons próprios" }
                }
                QQC2.ToolButton {
                    anchors.right: parent.right; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter
                    icon.name: "media-playback-start"; QQC2.ToolTip.text: "Ouvir"; QQC2.ToolTip.visible: hovered
                    onClicked: s.play(modelData.id === "vidro-custom" ? "vidro-custom" : modelData.id, "desktop-login")
                }
            }
        }
    }

    // ---- my preset ----
    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Meu preset"; visible: s.custom }
    QQC2.Label { Kirigami.FormData.label: ""; visible: s.custom; wrapMode: Text.WordWrap; opacity: 0.65; Layout.maximumWidth: Kirigami.Units.gridUnit * 26
        text: "Para cada evento escolha um arquivo seu (OGG, WAV, FLAC ou MP3) ou o som de outro tema. O que você não escolher vem do tema base." }
    RowLayout {
        Kirigami.FormData.label: "Salvar como tema:"
        visible: s.custom
        QQC2.TextField { id: presetName; placeholderText: "Nome do seu tema"; implicitWidth: Kirigami.Units.gridUnit * 10 }
        QQC2.Button { text: "Salvar"; icon.name: "document-save"; enabled: presetName.text.trim() !== ""
            onClicked: s.action("--save-preset " + s.app.quote(presetName.text.trim()), "sounds-save") }
    }
    QQC2.ComboBox {
        Kirigami.FormData.label: "Tema base:"
        visible: s.custom
        model: s.themes.filter(t => t.id !== "vidro-custom")
        textRole: "name"; valueRole: "id"
        currentIndex: Math.max(0, model.findIndex(t => t.id === (s.v("custom_base") || "vidro")))
        onActivated: s.app.set("Sounds", "custom_base", currentValue)
    }

    // ---- event list (current theme) ----
    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Ouvir cada som — " + s.themeName(s.theme) }
    Repeater {
        model: s.events
        RowLayout {
            id: row
            required property var modelData
            readonly property string choice: s.v("custom_" + modelData.id)
            Kirigami.FormData.label: modelData.label + ":"
            spacing: Kirigami.Units.smallSpacing
            QQC2.ToolButton {
                icon.name: s.playingKey === s.theme + "/" + row.modelData.id ? "media-playback-playing" : "media-playback-start"
                onClicked: s.play(s.theme, row.modelData.id)
            }
            QQC2.Label {
                visible: !s.custom
                opacity: 0.55; font.pointSize: Kirigami.Theme.smallFont.pointSize
                text: { const f = (s.files[s.theme] || {})[row.modelData.id] || ""; return f ? s.fileName(f) : "sem som" }
            }
            // preset controls
            QQC2.ComboBox {
                visible: s.custom
                implicitWidth: Kirigami.Units.gridUnit * 9
                model: [{ t: "do tema base", v: "" }, { t: "meu arquivo…", v: "file" }].concat(
                    s.themes.filter(t => t.id !== "vidro-custom").map(t => ({ t: "de " + t.name, v: "theme:" + t.id })))
                textRole: "t"; valueRole: "v"
                currentIndex: {
                    if (!row.choice) return 0;
                    if (!row.choice.startsWith("theme:")) return 1;
                    return Math.max(0, model.findIndex(o => o.v === row.choice));
                }
                onActivated: {
                    if (currentValue === "file") fileDlg.open();
                    else s.app.set("Sounds", "custom_" + row.modelData.id, currentValue);
                }
            }
            QQC2.Label { visible: s.custom && row.choice !== "" && !row.choice.startsWith("theme:"); text: s.fileName(row.choice)
                opacity: 0.7; elide: Text.ElideMiddle; Layout.maximumWidth: Kirigami.Units.gridUnit * 8 }
            FileDialog {
                id: fileDlg
                title: "Som para \"" + row.modelData.label + "\""
                nameFilters: ["Sons (*.oga *.ogg *.wav *.flac *.mp3 *.opus)"]
                onAccepted: {
                    const p = decodeURIComponent(String(selectedFile).replace(/^file:\/\//, ""));
                    s.app.set("Sounds", "custom_" + row.modelData.id, p);
                    s.playFile(p);
                }
            }
        }
    }
}
