// Seção: menu iniciar e pop-ups do Plasma (módulo menuiniciar.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Menu iniciar e pop-ups do painel"
    icone: "start-here-kde"
    previa: Component { PreviaPopup { app: s.app } }
    descricao: "Fundo de vidro, cantos e sombra do menu iniciar, relógio, bandeja e outros pop-ups do Plasma. Ao mudar, o Plasma recarrega o estilo (pisca rápido)."
    readonly property bool ligado: !!(app && app.cfg.MenuIniciar && app.cfg.MenuIniciar.ativo === "true")
    Chave { app: s.app; grupo: "MenuIniciar"; chave: "ativo"; Kirigami.FormData.label: "Pop-ups do Vidro:"; text: checked ? "ligados" : "desligados (como eram)" }
    Deslizante { app: s.app; grupo: "MenuIniciar"; chave: "raio"; de: 2; ate: 30; unidade: " px"; enabled: s.ligado; Kirigami.FormData.label: "Cantos:" }
    Escolha {
        app: s.app; grupo: "MenuIniciar"; chave: "fundo"; enabled: s.ligado
        Kirigami.FormData.label: "Cor do vidro:"
        opcoes: [ { texto: "Do tema", valor: "tema" }, { texto: "Cor personalizada", valor: "cor" } ]
    }
    Cor { app: s.app; grupo: "MenuIniciar"; chave: "cor_vidro"; visible: !!(s.app && s.app.cfg.MenuIniciar && s.app.cfg.MenuIniciar.fundo === "cor"); enabled: s.ligado; Kirigami.FormData.label: "Cor:" }
    Deslizante { app: s.app; grupo: "MenuIniciar"; chave: "opacidade"; de: 30; ate: 100; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Opacidade do fundo:" }
    Deslizante { app: s.app; grupo: "MenuIniciar"; chave: "linhas"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Linhas do cabeçalho/rodapé:" }
    Deslizante { app: s.app; grupo: "MenuIniciar"; chave: "cabecalho"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Fundo do cabeçalho/rodapé:" }
    Deslizante { app: s.app; grupo: "MenuIniciar"; chave: "borda"; de: 0; ate: 60; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Contorno:" }
    Deslizante { app: s.app; grupo: "MenuIniciar"; chave: "sombra"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Sombra:" }
    Deslizante { app: s.app; grupo: "MenuIniciar"; chave: "tamanho"; de: 4; ate: 40; unidade: " px"; enabled: s.ligado; Kirigami.FormData.label: "Tamanho da sombra:" }
}
