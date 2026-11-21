// Seção: estúdio do cursor (módulo cursor.py → ~/.local/share/vidro/cursor/gerar-cursor.py)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Estúdio do cursor"
    icone: "input-mouse"
    previa: Component { PreviaCursor { app: s.app } }
    descricao: "Monte o seu cursor: forma da seta, cores, contorno, cantos e sombra. O exemplo mostra o resultado na hora; ligue \"Usar no sistema\" para trocar o cursor de verdade (desligar volta ao que você usava)."
    function v(k) { return (app && app.cfg.Cursor) ? String(app.cfg.Cursor[k]) : "" }
    function modelo(m) { for (const k in m) s.app.definir("Cursor", k, m[k]); }
    Chave { app: s.app; grupo: "Cursor"; chave: "ativo"; Kirigami.FormData.label: "Usar no sistema:"; text: checked ? "sim (cursor do Vidro)" : "não (cursor de antes)" }
    Flow {
        Kirigami.FormData.label: "Modelos prontos:"
        width: Kirigami.Units.gridUnit * 26
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        spacing: Kirigami.Units.smallSpacing
        QQC2.Button { text: "Vidro escuro"; onClicked: s.modelo({ forma: "moderna", fundo: "#1d1e23", contorno: "#ffffff", destaque: "#5b9cf5", borda: "1.3", cantos: "1", sombra: "45" }) }
        QQC2.Button { text: "Branco clássico"; onClicked: s.modelo({ forma: "classica", fundo: "#ffffff", contorno: "#111111", destaque: "#3daee9", borda: "1", cantos: "0.5", sombra: "35" }) }
        QQC2.Button { text: "Mínimo"; onClicked: s.modelo({ forma: "minima", fundo: "#f4f4f6", contorno: "#1a1a1e", destaque: "#ff6b6b", borda: "1.1", cantos: "1.6", sombra: "25" }) }
        QQC2.Button { text: "Neon"; onClicked: s.modelo({ forma: "triangulo", fundo: "#0e0f14", contorno: "#39e6ff", destaque: "#ff3df2", borda: "1.6", cantos: "1.2", sombra: "60" }) }
        QQC2.Button { text: "Cor de destaque"; onClicked: s.modelo({ forma: "moderna", fundo: (s.app.cfg.Cores && s.app.cfg.Cores.cor_destaque) ? s.app.cfg.Cores.cor_destaque : "#3daee9", contorno: "#ffffff", destaque: "#ffffff", borda: "1.3", cantos: "1", sombra: "45" }) }
    }
    Escolha { app: s.app; grupo: "Cursor"; chave: "forma"; Kirigami.FormData.label: "Forma da seta:"
        opcoes: [ { texto: "Moderna (estilo macOS)", valor: "moderna" }, { texto: "Clássica", valor: "classica" },
                  { texto: "Mínima (sem cauda)", valor: "minima" }, { texto: "Triângulo", valor: "triangulo" } ] }
    Cor { app: s.app; grupo: "Cursor"; chave: "fundo"; Kirigami.FormData.label: "Cor de dentro:" }
    Cor { app: s.app; grupo: "Cursor"; chave: "contorno"; Kirigami.FormData.label: "Cor do contorno:" }
    Cor { app: s.app; grupo: "Cursor"; chave: "destaque"; Kirigami.FormData.label: "Detalhes (espera, selos):" }
    Deslizante { app: s.app; grupo: "Cursor"; chave: "borda"; de: 0; ate: 3; passo: 0.1; Kirigami.FormData.label: "Contorno:" }
    Deslizante { app: s.app; grupo: "Cursor"; chave: "cantos"; de: 0; ate: 3; passo: 0.1; Kirigami.FormData.label: "Cantos arredondados:" }
    Deslizante { app: s.app; grupo: "Cursor"; chave: "sombra"; unidade: "%"; Kirigami.FormData.label: "Sombra:" }
    Escolha { app: s.app; grupo: "Cursor"; chave: "tamanho"; Kirigami.FormData.label: "Tamanho no sistema:"
        opcoes: [ { texto: "Pequeno (24)", valor: "24" }, { texto: "Médio (32)", valor: "32" }, { texto: "Grande (48)", valor: "48" }, { texto: "Enorme (64)", valor: "64" } ] }
    // área de teste: cada quadrado usa um cursor (vale o cursor do sistema)
    Flow {
        Kirigami.FormData.label: "Teste (passe o mouse):"
        width: Kirigami.Units.gridUnit * 26
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        spacing: 4
        Repeater {
            model: [[Qt.ArrowCursor, "seta"], [Qt.PointingHandCursor, "mão"], [Qt.IBeamCursor, "texto"], [Qt.WaitCursor, "espera"],
                    [Qt.BusyCursor, "ocupado"], [Qt.OpenHandCursor, "pegar"], [Qt.ClosedHandCursor, "arrastar"], [Qt.CrossCursor, "mira"],
                    [Qt.SizeHorCursor, "↔"], [Qt.SizeVerCursor, "↕"], [Qt.SizeFDiagCursor, "⤡"], [Qt.SizeAllCursor, "mover"],
                    [Qt.ForbiddenCursor, "proibido"], [Qt.WhatsThisCursor, "ajuda"], [Qt.DragCopyCursor, "copiar"]]
            Rectangle {
                width: 74; height: 34; radius: 6
                color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.05)
                QQC2.Label { anchors.centerIn: parent; text: modelData[1]; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: modelData[0] }
            }
        }
    }
}
