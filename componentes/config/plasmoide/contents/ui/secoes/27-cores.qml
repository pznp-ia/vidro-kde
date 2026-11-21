// Seção: cor de destaque (seleção) e cor da fonte (módulo cores.py) — mudam na hora
import QtQuick
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Cores: destaque e fonte"
    icone: "color-management"
    previa: Component { PreviaCores { app: s.app } }
    descricao: "Cor de destaque = seleção (ex.: pasta selecionada no Dolphin), foco e realces. Cor da fonte = texto dos apps. Mudam na hora (vale para o esquema escuro Vidro)."
    readonly property var c: (app && app.cfg.Cores) ? app.cfg.Cores : ({})
    Escolha {
        app: s.app; grupo: "Cores"; chave: "destaque"
        Kirigami.FormData.label: "Cor de destaque:"
        opcoes: [ { texto: "Do tema (azul)", valor: "tema" }, { texto: "Cor personalizada", valor: "cor" } ]
    }
    Cor { app: s.app; grupo: "Cores"; chave: "cor_destaque"; visible: s.c.destaque === "cor"; Kirigami.FormData.label: "Cor:" }
    Deslizante { app: s.app; grupo: "Cores"; chave: "forca"; unidade: "%"; enabled: s.c.destaque === "cor"; Kirigami.FormData.label: "Força na seleção:" }
    Escolha {
        app: s.app; grupo: "Cores"; chave: "fonte"
        Kirigami.FormData.label: "Cor da fonte:"
        opcoes: [ { texto: "Do tema (branco)", valor: "tema" }, { texto: "Cor personalizada", valor: "cor" } ]
    }
    Cor { app: s.app; grupo: "Cores"; chave: "cor_fonte"; visible: s.c.fonte === "cor"; Kirigami.FormData.label: "Cor:" }
    Deslizante { app: s.app; grupo: "Cores"; chave: "secundario"; de: 0; ate: 80; unidade: "%"; enabled: s.c.fonte === "cor"; Kirigami.FormData.label: "Texto secundário mais apagado:" }
}
