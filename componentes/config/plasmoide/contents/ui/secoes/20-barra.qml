// Seção: barra de rolagem dos apps (módulo ~/.local/share/vidro/modulos/barra.py)
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Barra de rolagem"
    icone: "view-list-text"
    previa: Component { PreviaBarra { app: s.app } }
    descricao: "Vale para os apps do KDE (estilo de apps Vidro / Union). \"Sobreposta\" põe a barra por cima do conteúdo, transparente de verdade, como no macOS — ligar/desligar vale a partir do próximo login; os outros ajustes valem em janelas novas."
    readonly property bool ligado: !!(app && app.cfg.Barra && app.cfg.Barra.ativo === "true")
    readonly property string modo: (app && app.cfg.Barra) ? app.cfg.Barra.modo : "vidro"
    Chave { app: s.app; grupo: "Barra"; chave: "ativo"; Kirigami.FormData.label: "Barra do Vidro:"; text: checked ? "ligada" : "desligada (barra padrão)" }
    Escolha {
        app: s.app; grupo: "Barra"; chave: "modo"; enabled: s.ligado
        Kirigami.FormData.label: "Estilo:"
        opcoes: [ { texto: "Vidro", valor: "vidro" }, { texto: "Neon fino", valor: "neon-fino" }, { texto: "Cor personalizada", valor: "cor" } ]
    }
    Cor { app: s.app; grupo: "Barra"; chave: "cor"; visible: s.modo === "cor"; enabled: s.ligado; Kirigami.FormData.label: "Cor:" }
    Deslizante { app: s.app; grupo: "Barra"; chave: "largura"; de: 2; ate: 16; unidade: " px"; enabled: s.ligado; Kirigami.FormData.label: "Espessura:" }
    Deslizante { app: s.app; grupo: "Barra"; chave: "opacidade"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Opacidade:" }
    Deslizante { app: s.app; grupo: "Barra"; chave: "realce"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Ao passar o mouse:" }
    Deslizante { app: s.app; grupo: "Barra"; chave: "arredondamento"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Arredondamento:" }
    Chave { app: s.app; grupo: "Barra"; chave: "trilho"; enabled: s.ligado; Kirigami.FormData.label: "Trilho:"; text: checked ? "visível" : "invisível" }
    readonly property bool sobre: !!(app && app.cfg.Barra && app.cfg.Barra.sobreposta === "true")
    readonly property bool some: !!(app && app.cfg.Barra && app.cfg.Barra.some === "true")
    Chave { app: s.app; grupo: "Barra"; chave: "sobreposta"; enabled: s.ligado; Kirigami.FormData.label: "Por cima do conteúdo:"; text: checked ? "sim (transparente de verdade)" : "não (faixa própria)" }
    Chave { app: s.app; grupo: "Barra"; chave: "some"; enabled: s.ligado && s.sobre; Kirigami.FormData.label: "Some quando parada:"; text: checked ? "sim" : "não" }
    Deslizante { app: s.app; grupo: "Barra"; chave: "espera"; de: 300; ate: 5000; passo: 100; unidade: " ms"; enabled: s.ligado && s.sobre && s.some; Kirigami.FormData.label: "Tempo até sumir:" }
    Deslizante { app: s.app; grupo: "Barra"; chave: "minima"; de: 0; ate: 100; unidade: "%"; enabled: s.ligado && s.sobre && s.some; Kirigami.FormData.label: "Visível quando parada:" }
}
