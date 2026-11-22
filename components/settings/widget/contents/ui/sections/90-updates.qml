// Section: updates — uses ~/.local/bin/vidro-update (versions published on GitHub)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Atualizações"
    icon: "system-software-update"
    description: "Procura versões novas do Vidro no GitHub. Suas configurações e o backup de antes do Vidro são mantidos."

    property string installed: "…"
    property string available: ""
    property string status: ""      // "", "checking", "new", "current", "error", "updating", "done"
    property string notes: ""
    property string output: ""
    property var versions: []

    readonly property string cmdCheck: "$HOME/.local/bin/vidro-update --check 2>&1 #check" + seq
    readonly property string cmdList: "$HOME/.local/bin/vidro-update --list 2>&1 #list" + seq
    property int seq: 0

    function check() { seq += 1; status = "checking"; exec.connectSource(cmdCheck); exec.connectSource(cmdList); }
    function install(v) {
        status = "updating"; output = "";
        exec.connectSource("$HOME/.local/bin/vidro-update" + (v ? " --version '" + v.replace(/'/g, "") + "'" : "") + " 2>&1 #install" + Date.now());
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            const out = String(data["stdout"] || "");
            if (source.indexOf("#check") >= 0) {
                const kv = {};
                out.split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) kv[l.slice(0, i)] = l.slice(i + 1); });
                if (kv.installed) s.installed = kv.installed;
                s.available = kv.available || "";
                s.notes = (kv.notes || "").replace(/\\n/g, "\n");
                s.status = kv.state || "error";
                if (s.status === "error") s.output = out.trim();
            } else if (source.indexOf("#list") >= 0) {
                s.versions = out.split("\n").filter(l => /^[ *] v/.test(l)).map(l => l.slice(2).trim().split(/\s+/)[0]);
            } else if (source.indexOf("#install") >= 0) {
                s.output = out.trim();
                s.status = data["exit code"] === 0 ? "done" : "error";
            }
            disconnectSource(source);
        }
    }
    Component.onCompleted: check()

    QQC2.Label {
        Kirigami.FormData.label: "Versão instalada:"
        text: s.installed
        font.bold: true
    }
    QQC2.Label {
        Kirigami.FormData.label: "Situação:"
        Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        wrapMode: Text.WordWrap
        text: ({
            "": "",
            "checking": "Procurando no GitHub…",
            "new": "Há uma versão nova: " + s.available,
            "current": "Você já tem a versão mais nova.",
            "error": "Não consegui verificar (sem internet?).",
            "updating": "Baixando e instalando… pode levar um minuto.",
            "done": "Pronto! Feche e abra este app. Algumas partes valem depois de sair e entrar na sessão."
        })[s.status]
        color: s.status === "new" ? Kirigami.Theme.positiveTextColor
             : s.status === "error" ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
    }
    RowLayout {
        Kirigami.FormData.label: ""
        QQC2.Button {
            text: "Procurar de novo"
            icon.name: "view-refresh"
            enabled: s.status !== "checking" && s.status !== "updating"
            onClicked: s.check()
        }
        QQC2.Button {
            text: "Atualizar para " + s.available
            icon.name: "system-software-update"
            visible: s.status === "new"
            highlighted: true
            onClicked: s.install("")
        }
        QQC2.BusyIndicator { running: visible; visible: s.status === "checking" || s.status === "updating"; implicitHeight: Kirigami.Units.iconSizes.medium; implicitWidth: implicitHeight }
    }
    QQC2.Label {
        Kirigami.FormData.label: "Novidades:"
        visible: s.status === "new" && s.notes !== ""
        text: s.notes
        textFormat: Text.MarkdownText
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 26
    }
    RowLayout {
        Kirigami.FormData.label: "Outra versão:"
        visible: s.versions.length > 1
        QQC2.ComboBox { id: picker; model: s.versions }
        QQC2.Button {
            text: "Instalar esta"
            enabled: s.status !== "updating" && picker.currentText !== "" && picker.currentText !== s.installed
            onClicked: s.install(picker.currentText)
        }
    }
    QQC2.TextArea {
        Kirigami.FormData.label: "Detalhes:"
        visible: s.output !== ""
        text: s.output
        readOnly: true
        wrapMode: Text.WordWrap
        font.family: "monospace"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        Layout.preferredHeight: Kirigami.Units.gridUnit * 8
    }
}
