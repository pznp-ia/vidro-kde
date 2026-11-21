// Seção: atualizações — usa ~/.local/bin/vidro-atualizar (versões publicadas no GitHub)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Atualizações"
    icone: "system-software-update"
    descricao: "Procura versões novas do Vidro no GitHub. Suas configurações e o backup de antes do Vidro são mantidos."

    property string instalada: "…"
    property string disponivel: ""
    property string estado: ""      // "", "procurando", "nova", "atual", "erro", "atualizando", "feito"
    property string notas: ""
    property string saida: ""
    property var versoes: []

    readonly property string cmdVerificar: "$HOME/.local/bin/vidro-atualizar --verificar 2>&1 #verificar" + seq
    readonly property string cmdLista: "$HOME/.local/bin/vidro-atualizar --lista 2>&1 #lista" + seq
    property int seq: 0

    function verificar() { seq += 1; estado = "procurando"; exec.connectSource(cmdVerificar); exec.connectSource(cmdLista); }
    function instalar(v) {
        estado = "atualizando"; saida = "";
        exec.connectSource("$HOME/.local/bin/vidro-atualizar" + (v ? " --versao '" + v.replace(/'/g, "") + "'" : "") + " 2>&1 #instalar" + Date.now());
    }

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (source, data) => {
            const out = String(data["stdout"] || "");
            if (source.indexOf("#verificar") >= 0) {
                const kv = {};
                out.split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) kv[l.slice(0, i)] = l.slice(i + 1); });
                if (kv.instalada) s.instalada = kv.instalada;
                s.disponivel = kv.disponivel || "";
                s.notas = (kv.notas || "").replace(/\\n/g, "\n");
                s.estado = kv.estado || "erro";
                if (s.estado === "erro") s.saida = out.trim();
            } else if (source.indexOf("#lista") >= 0) {
                s.versoes = out.split("\n").filter(l => /^[ *] v/.test(l)).map(l => l.slice(2).trim().split(/\s+/)[0]);
            } else if (source.indexOf("#instalar") >= 0) {
                s.saida = out.trim();
                s.estado = data["exit code"] === 0 ? "feito" : "erro";
            }
            disconnectSource(source);
        }
    }
    Component.onCompleted: verificar()

    QQC2.Label {
        Kirigami.FormData.label: "Versão instalada:"
        text: s.instalada
        font.bold: true
    }
    QQC2.Label {
        Kirigami.FormData.label: "Situação:"
        Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        wrapMode: Text.WordWrap
        text: ({
            "": "",
            "procurando": "Procurando no GitHub…",
            "nova": "Há uma versão nova: " + s.disponivel,
            "atual": "Você já tem a versão mais nova.",
            "erro": "Não consegui verificar (sem internet?).",
            "atualizando": "Baixando e instalando… pode levar um minuto.",
            "feito": "Pronto! Feche e abra este app. Algumas partes valem depois de sair e entrar na sessão."
        })[s.estado]
        color: s.estado === "nova" ? Kirigami.Theme.positiveTextColor
             : s.estado === "erro" ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
    }
    RowLayout {
        Kirigami.FormData.label: ""
        QQC2.Button {
            text: "Procurar de novo"
            icon.name: "view-refresh"
            enabled: s.estado !== "procurando" && s.estado !== "atualizando"
            onClicked: s.verificar()
        }
        QQC2.Button {
            text: "Atualizar para " + s.disponivel
            icon.name: "system-software-update"
            visible: s.estado === "nova"
            highlighted: true
            onClicked: s.instalar("")
        }
        QQC2.BusyIndicator { running: visible; visible: s.estado === "procurando" || s.estado === "atualizando"; implicitHeight: Kirigami.Units.iconSizes.medium; implicitWidth: implicitHeight }
    }
    QQC2.Label {
        Kirigami.FormData.label: "Novidades:"
        visible: s.estado === "nova" && s.notas !== ""
        text: s.notas
        textFormat: Text.MarkdownText
        wrapMode: Text.WordWrap
        Layout.maximumWidth: Kirigami.Units.gridUnit * 26
    }
    RowLayout {
        Kirigami.FormData.label: "Outra versão:"
        visible: s.versoes.length > 1
        QQC2.ComboBox { id: escolha; model: s.versoes }
        QQC2.Button {
            text: "Instalar esta"
            enabled: s.estado !== "atualizando" && escolha.currentText !== "" && escolha.currentText !== s.instalada
            onClicked: s.instalar(escolha.currentText)
        }
    }
    QQC2.TextArea {
        Kirigami.FormData.label: "Detalhes:"
        visible: s.saida !== ""
        text: s.saida
        readOnly: true
        wrapMode: Text.WordWrap
        font.family: "monospace"
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        Layout.preferredHeight: Kirigami.Units.gridUnit * 8
    }
}
