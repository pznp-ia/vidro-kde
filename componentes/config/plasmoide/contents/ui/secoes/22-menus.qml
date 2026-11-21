// Seção: menus de clique direito dos apps + animação de menus/pop-ups (módulo menus.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Menus (clique direito)"
    icone: "application-menu"
    previa: Component { PreviaMenu { app: s.app } }
    descricao: "Aparência dos menus dos apps do KDE e a animação de abrir/fechar de todos os menus e pop-ups."
    readonly property bool ligado: !!(app && app.cfg.Menus && app.cfg.Menus.ativo === "true")
    readonly property var cfgMenus: (app && app.cfg.Menus) ? app.cfg.Menus : ({})
    readonly property bool anim: !!(app && app.cfg.Menus && app.cfg.Menus.animacao === "true")
    Chave { app: s.app; grupo: "Menus"; chave: "ativo"; Kirigami.FormData.label: "Menus do Vidro:"; text: checked ? "ligados" : "desligados (padrão)" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "raio"; de: 0; ate: 24; unidade: " px"; enabled: s.ligado; Kirigami.FormData.label: "Cantos:" }
    Escolha {
        app: s.app; grupo: "Menus"; chave: "fundo"; enabled: s.ligado
        Kirigami.FormData.label: "Cor do fundo:"
        opcoes: [ { texto: "Do tema", valor: "tema" }, { texto: "Cor personalizada", valor: "cor" } ]
    }
    Cor { app: s.app; grupo: "Menus"; chave: "cor_fundo"; visible: s.cfgMenus.fundo === "cor"; enabled: s.ligado; Kirigami.FormData.label: "Cor:" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "opacidade"; de: 40; ate: 100; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Opacidade do fundo:" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "espaco"; de: 0; ate: 14; unidade: " px"; enabled: s.ligado; Kirigami.FormData.label: "Respiro:" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "separadores"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Linhas separadoras:" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "borda"; de: 0; ate: 60; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Contorno:" }
    Escolha {
        app: s.app; grupo: "Menus"; chave: "realce"; enabled: s.ligado
        Kirigami.FormData.label: "Item sob o mouse:"
        opcoes: [ { texto: "Vidro (neutro)", valor: "vidro" }, { texto: "Cor de destaque", valor: "destaque" }, { texto: "Cor personalizada", valor: "cor" } ]
    }
    Cor { app: s.app; grupo: "Menus"; chave: "cor_realce"; visible: s.cfgMenus.realce === "cor"; enabled: s.ligado; Kirigami.FormData.label: "Cor do realce:" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "intensidade"; de: 0; ate: 60; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Força do realce:" }
    Chave { app: s.app; grupo: "Menus"; chave: "animacao"; Kirigami.FormData.label: "Animação:"; text: checked ? "ligada" : "desligada" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "entrada"; de: 40; ate: 400; passo: 10; unidade: " ms"; enabled: s.anim; Kirigami.FormData.label: "Abrir:" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "saida"; de: 40; ate: 400; passo: 10; unidade: " ms"; enabled: s.anim; Kirigami.FormData.label: "Fechar:" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "escala"; de: 80; ate: 100; unidade: "%"; enabled: s.anim; Kirigami.FormData.label: "Zoom inicial:" }
    Deslizante { app: s.app; grupo: "Menus"; chave: "deslize"; de: 0; ate: 30; unidade: " px"; enabled: s.anim; Kirigami.FormData.label: "Deslize:" }
}
