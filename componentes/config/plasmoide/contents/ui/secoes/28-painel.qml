// Seção: barra de tarefas (módulo painel.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Barra de tarefas e relógio"
    icone: "configure-toolbars"
    previa: Component { PreviaPainel { app: s.app } }
    descricao: "A barra onde ficam o menu iniciar e o relógio. Muda na hora; os valores abaixo são os do seu painel agora."
    function v(k) { return (app && app.cfg.Painel) ? String(app.cfg.Painel[k]) : "" }
    readonly property bool vidro: v("vidro_ativo") === "true"

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Barra" }
    Deslizante { app: s.app; grupo: "Painel"; chave: "altura"; de: 24; ate: 96; unidade: " px"; Kirigami.FormData.label: "Altura:" }
    Chave { app: s.app; grupo: "Painel"; chave: "flutuante"; Kirigami.FormData.label: "Flutuante:"; text: checked ? "sim (afastada da borda)" : "não (colada na borda)" }
    Escolha { app: s.app; grupo: "Painel"; chave: "posicao"; Kirigami.FormData.label: "Posição:"
        opcoes: [ { texto: "Embaixo", valor: "bottom" }, { texto: "Em cima", valor: "top" }, { texto: "Esquerda", valor: "left" }, { texto: "Direita", valor: "right" } ] }
    Escolha { app: s.app; grupo: "Painel"; chave: "largura"; Kirigami.FormData.label: "Largura:"
        opcoes: [ { texto: "Tela toda", valor: "fill" }, { texto: "Só o conteúdo (estilo dock)", valor: "fit" } ] }
    Escolha { app: s.app; grupo: "Painel"; chave: "alinhamento"; enabled: s.v("largura") === "fit"; Kirigami.FormData.label: "Alinhamento:"
        opcoes: [ { texto: "Centro", valor: "center" }, { texto: "Início", valor: "left" }, { texto: "Fim", valor: "right" } ] }
    Escolha { app: s.app; grupo: "Painel"; chave: "ocultar"; Kirigami.FormData.label: "Esconder:"
        opcoes: [ { texto: "Nunca", valor: "none" }, { texto: "Sempre (aparece ao encostar o mouse)", valor: "autohide" },
                  { texto: "Quando uma janela encostar", valor: "dodgewindows" }, { texto: "Janelas podem cobrir", valor: "windowsgobelow" } ] }
    Escolha { app: s.app; grupo: "Painel"; chave: "opacidade"; Kirigami.FormData.label: "Fundo:"
        opcoes: [ { texto: "Translúcido", valor: "translucent" }, { texto: "Adaptativo (opaco com janela maximizada)", valor: "adaptive" }, { texto: "Opaco", valor: "opaque" } ] }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Vidro da barra" }
    Chave { app: s.app; grupo: "Painel"; chave: "vidro_ativo"; Kirigami.FormData.label: "Vidro personalizado:"; text: checked ? "ligado" : "desligado (desenho padrão do Vidro)" }
    Deslizante { app: s.app; grupo: "Painel"; chave: "vidro_raio"; de: 0; ate: 30; unidade: " px"; enabled: s.vidro; Kirigami.FormData.label: "Cantos:" }
    Deslizante { app: s.app; grupo: "Painel"; chave: "vidro_opacidade"; de: 5; ate: 100; unidade: "%"; enabled: s.vidro; Kirigami.FormData.label: "Opacidade:" }
    Deslizante { app: s.app; grupo: "Painel"; chave: "vidro_contorno"; de: 0; ate: 60; unidade: "%"; enabled: s.vidro; Kirigami.FormData.label: "Contorno:" }
    Deslizante { app: s.app; grupo: "Painel"; chave: "vidro_sombra"; unidade: "%"; enabled: s.vidro; Kirigami.FormData.label: "Sombra:" }
    Escolha { app: s.app; grupo: "Painel"; chave: "vidro_fundo"; enabled: s.vidro; Kirigami.FormData.label: "Cor:"
        opcoes: [ { texto: "Do tema", valor: "tema" }, { texto: "Cor personalizada", valor: "cor" } ] }
    Cor { app: s.app; grupo: "Painel"; chave: "vidro_cor"; visible: s.v("vidro_fundo") === "cor"; enabled: s.vidro; Kirigami.FormData.label: "Cor do vidro:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Ícones dos apps" }
    Deslizante { app: s.app; grupo: "Painel"; chave: "espaco_icones"; de: 0; ate: 3; unidade: ""; Kirigami.FormData.label: "Espaço entre ícones:" }
    Escolha { app: s.app; grupo: "Painel"; chave: "agrupar"; Kirigami.FormData.label: "Janelas do mesmo app:"
        opcoes: [ { texto: "Agrupar", valor: "1" }, { texto: "Separadas", valor: "0" } ] }
    Chave { app: s.app; grupo: "Painel"; chave: "so_area_atual"; Kirigami.FormData.label: "Só da área de trabalho atual:"; text: checked ? "sim" : "todas" }
    Chave { app: s.app; grupo: "Painel"; chave: "so_tela_atual"; Kirigami.FormData.label: "Só da tela atual:"; text: checked ? "sim" : "todas as telas" }
    Chave { app: s.app; grupo: "Painel"; chave: "audio"; Kirigami.FormData.label: "Mostrar quem toca som:"; text: checked ? "sim" : "não" }
    Chave { app: s.app; grupo: "Painel"; chave: "dicas"; Kirigami.FormData.label: "Prévia ao passar o mouse:"; text: checked ? "sim" : "não" }
    Chave { app: s.app; grupo: "Painel"; chave: "efeito_mouse"; Kirigami.FormData.label: "Realce ao passar o mouse:"; text: checked ? "sim" : "não" }
    Chave { app: s.app; grupo: "Painel"; chave: "destacar_janelas"; Kirigami.FormData.label: "Destacar a janela na prévia:"; text: checked ? "sim" : "não" }
    Escolha { app: s.app; grupo: "Painel"; chave: "clique_meio"; Kirigami.FormData.label: "Clique do meio:"
        opcoes: [ { texto: "Abrir outra janela", valor: "2" }, { texto: "Fechar", valor: "1" }, { texto: "Minimizar/restaurar", valor: "3" }, { texto: "Nada", valor: "0" } ] }
    Deslizante { app: s.app; grupo: "Painel"; chave: "linhas"; de: 1; ate: 3; unidade: ""; Kirigami.FormData.label: "Linhas de ícones:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Relógio" }
    Escolha { app: s.app; grupo: "Painel"; chave: "segundos"; Kirigami.FormData.label: "Segundos:"
        opcoes: [ { texto: "Só na dica", valor: "1" }, { texto: "Sempre", valor: "2" }, { texto: "Nunca", valor: "0" } ] }
    Escolha { app: s.app; grupo: "Painel"; chave: "horas"; Kirigami.FormData.label: "Formato da hora:"
        opcoes: [ { texto: "Do idioma", valor: "1" }, { texto: "24 horas", valor: "2" }, { texto: "12 horas (AM/PM)", valor: "0" } ] }
    Chave { app: s.app; grupo: "Painel"; chave: "data"; Kirigami.FormData.label: "Data:"; text: checked ? "mostrar" : "esconder" }
    Escolha { app: s.app; grupo: "Painel"; chave: "formato_data"; enabled: s.v("data") === "true"; Kirigami.FormData.label: "Formato da data:"
        opcoes: [ { texto: "Curta (21/11/2026)", valor: "shortDate" }, { texto: "Longa (21 de novembro)", valor: "longDate" }, { texto: "ISO (2026-11-21)", valor: "isoDate" }, { texto: "Personalizada", valor: "custom" } ] }
    Texto { app: s.app; grupo: "Painel"; chave: "data_personalizada"; visible: s.v("formato_data") === "custom"; placeholderText: "ex.: ddd d MMM"; Kirigami.FormData.label: "Data personalizada:" }
    Escolha { app: s.app; grupo: "Painel"; chave: "posicao_data"; enabled: s.v("data") === "true"; Kirigami.FormData.label: "Data em relação à hora:"
        opcoes: [ { texto: "Automático", valor: "0" }, { texto: "Ao lado", valor: "1" }, { texto: "Embaixo", valor: "2" } ] }
    Chave { app: s.app; grupo: "Painel"; chave: "negrito"; Kirigami.FormData.label: "Negrito:"; text: checked ? "sim" : "não" }
    Chave { app: s.app; grupo: "Painel"; chave: "fonte_auto"; Kirigami.FormData.label: "Tamanho automático:"; text: checked ? "sim" : "escolher" }
    Deslizante { app: s.app; grupo: "Painel"; chave: "tamanho_fonte"; de: 7; ate: 24; unidade: " pt"; enabled: s.v("fonte_auto") !== "true"; Kirigami.FormData.label: "Tamanho da letra:" }
}
