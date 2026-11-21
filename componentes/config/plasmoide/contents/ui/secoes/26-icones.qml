// Seção: cor das pastas (módulo icones.py) — muda na hora em todos os apps
import QtQuick
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Pastas (cores dos ícones)"
    icone: "folder"
    previa: Component { PreviaPastas { app: s.app } }
    descricao: "Cor das pastas grandes no Dolphin, no menu e nos diálogos. Muda na hora."
    readonly property bool ligado: !!(app && app.cfg.Icones && app.cfg.Icones.ativo === "true")
    readonly property string modo: (app && app.cfg.Icones) ? app.cfg.Icones.modo : "grafite"
    Chave { app: s.app; grupo: "Icones"; chave: "ativo"; Kirigami.FormData.label: "Cores do Vidro:"; text: checked ? "ligadas" : "desligadas (pastas escuras originais)" }
    Escolha {
        app: s.app; grupo: "Icones"; chave: "modo"; enabled: s.ligado
        Kirigami.FormData.label: "Estilo:"
        opcoes: [ { texto: "Grafite claro", valor: "grafite" }, { texto: "Escuro", valor: "escuro" },
                  { texto: "Cor de destaque", valor: "destaque" }, { texto: "Cor personalizada", valor: "cor" } ]
    }
    Cor { app: s.app; grupo: "Icones"; chave: "cor"; visible: s.modo === "cor"; enabled: s.ligado; Kirigami.FormData.label: "Cor:" }
    Deslizante { app: s.app; grupo: "Icones"; chave: "brilho"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Brilho:" }
    Deslizante { app: s.app; grupo: "Icones"; chave: "relevo"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Relevo:" }
    Deslizante { app: s.app; grupo: "Icones"; chave: "saturacao"; unidade: "%"; enabled: s.ligado && (s.modo === "destaque" || s.modo === "cor"); Kirigami.FormData.label: "Saturação:" }
}
