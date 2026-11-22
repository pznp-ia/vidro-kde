// Section: taskbar (module panel.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Barra de tarefas e relógio"
    icon: "configure-toolbars"
    preview: Component { PreviewPanel { app: s.app } }
    description: "A barra onde ficam o menu iniciar e o relógio. Muda na hora; os valores abaixo são os do seu painel agora."
    function v(k) { return (app && app.cfg.Panel) ? String(app.cfg.Panel[k]) : "" }
    readonly property bool glass: v("glass_enabled") === "true"

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Barra" }
    ValueSlider { app: s.app; group: "Panel"; key: "height"; from: 24; to: 96; unit: " px"; Kirigami.FormData.label: "Altura:" }
    Toggle { app: s.app; group: "Panel"; key: "floating"; Kirigami.FormData.label: "Flutuante:"; text: checked ? "sim (afastada da borda)" : "não (colada na borda)" }
    Choice { app: s.app; group: "Panel"; key: "location"; Kirigami.FormData.label: "Posição:"
        options: [ { text: "Embaixo", value: "bottom" }, { text: "Em cima", value: "top" }, { text: "Esquerda", value: "left" }, { text: "Direita", value: "right" } ] }
    Choice { app: s.app; group: "Panel"; key: "length"; Kirigami.FormData.label: "Largura:"
        options: [ { text: "Tela toda", value: "fill" }, { text: "Só o conteúdo (estilo dock)", value: "fit" } ] }
    Choice { app: s.app; group: "Panel"; key: "alignment"; enabled: s.v("length") === "fit"; Kirigami.FormData.label: "Alinhamento:"
        options: [ { text: "Centro", value: "center" }, { text: "Início", value: "left" }, { text: "Fim", value: "right" } ] }
    Choice { app: s.app; group: "Panel"; key: "hiding"; Kirigami.FormData.label: "Esconder:"
        options: [ { text: "Nunca", value: "none" }, { text: "Sempre (aparece ao encostar o mouse)", value: "autohide" },
                  { text: "Quando uma janela encostar", value: "dodgewindows" }, { text: "Janelas podem cobrir", value: "windowsgobelow" } ] }
    Choice { app: s.app; group: "Panel"; key: "opacity"; Kirigami.FormData.label: "Fundo:"
        options: [ { text: "Translúcido", value: "translucent" }, { text: "Adaptativo (opaco com janela maximizada)", value: "adaptive" }, { text: "Opaco", value: "opaque" } ] }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Vidro da barra" }
    Toggle { app: s.app; group: "Panel"; key: "glass_enabled"; Kirigami.FormData.label: "Vidro personalizado:"; text: checked ? "ligado" : "desligado (desenho padrão do Vidro)" }
    ValueSlider { app: s.app; group: "Panel"; key: "glass_radius"; from: 0; to: 30; unit: " px"; enabled: s.glass; Kirigami.FormData.label: "Cantos:" }
    ValueSlider { app: s.app; group: "Panel"; key: "glass_opacity"; from: 5; to: 100; unit: "%"; enabled: s.glass; Kirigami.FormData.label: "Opacidade:" }
    ValueSlider { app: s.app; group: "Panel"; key: "glass_border"; from: 0; to: 60; unit: "%"; enabled: s.glass; Kirigami.FormData.label: "Contorno:" }
    ValueSlider { app: s.app; group: "Panel"; key: "glass_shadow"; unit: "%"; enabled: s.glass; Kirigami.FormData.label: "Sombra:" }
    Choice { app: s.app; group: "Panel"; key: "glass_background"; enabled: s.glass; Kirigami.FormData.label: "Cor:"
        options: [ { text: "Do tema", value: "theme" }, { text: "Cor personalizada", value: "custom" } ] }
    ColorButton { app: s.app; group: "Panel"; key: "glass_color"; visible: s.v("glass_background") === "custom"; enabled: s.glass; Kirigami.FormData.label: "Cor do vidro:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Ícones dos apps" }
    ValueSlider { app: s.app; group: "Panel"; key: "icon_spacing"; from: 0; to: 3; unit: ""; Kirigami.FormData.label: "Espaço entre ícones:" }
    Choice { app: s.app; group: "Panel"; key: "grouping"; Kirigami.FormData.label: "Janelas do mesmo app:"
        options: [ { text: "Agrupar", value: "1" }, { text: "Separadas", value: "0" } ] }
    Toggle { app: s.app; group: "Panel"; key: "current_desktop_only"; Kirigami.FormData.label: "Só da área de trabalho atual:"; text: checked ? "sim" : "todas" }
    Toggle { app: s.app; group: "Panel"; key: "current_screen_only"; Kirigami.FormData.label: "Só da tela atual:"; text: checked ? "sim" : "todas as telas" }
    Toggle { app: s.app; group: "Panel"; key: "audio_indicator"; Kirigami.FormData.label: "Mostrar quem toca som:"; text: checked ? "sim" : "não" }
    Toggle { app: s.app; group: "Panel"; key: "tooltips"; Kirigami.FormData.label: "Prévia ao passar o mouse:"; text: checked ? "sim" : "não" }
    Toggle { app: s.app; group: "Panel"; key: "hover_effect"; Kirigami.FormData.label: "Realce ao passar o mouse:"; text: checked ? "sim" : "não" }
    Toggle { app: s.app; group: "Panel"; key: "highlight_windows"; Kirigami.FormData.label: "Destacar a janela na prévia:"; text: checked ? "sim" : "não" }
    Choice { app: s.app; group: "Panel"; key: "middle_click"; Kirigami.FormData.label: "Clique do meio:"
        options: [ { text: "Abrir outra janela", value: "2" }, { text: "Fechar", value: "1" }, { text: "Minimizar/restaurar", value: "3" }, { text: "Nada", value: "0" } ] }
    ValueSlider { app: s.app; group: "Panel"; key: "rows"; from: 1; to: 3; unit: ""; Kirigami.FormData.label: "Linhas de ícones:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Mostrar área de trabalho" }
    IconPicker { app: s.app; group: "Panel"; key: "showdesktop_icon"; Kirigami.FormData.label: "Ícone do botão:"
        icons: ["user-desktop-symbolic", "user-desktop", "desktop-symbolic", "window-minimize-symbolic", "view-grid-symbolic",
                "go-down-symbolic", "view-restore-symbolic", "window-symbolic", "computer-symbolic", "start-here-symbolic",
                "media-playback-stop-symbolic", "draw-rectangle"] }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Relógio" }
    Choice { app: s.app; group: "Panel"; key: "clock_seconds"; Kirigami.FormData.label: "Segundos:"
        options: [ { text: "Só na dica", value: "1" }, { text: "Sempre", value: "2" }, { text: "Nunca", value: "0" } ] }
    Choice { app: s.app; group: "Panel"; key: "hour_format"; Kirigami.FormData.label: "Formato da hora:"
        options: [ { text: "Do idioma", value: "1" }, { text: "24 horas", value: "2" }, { text: "12 horas (AM/PM)", value: "0" } ] }
    Toggle { app: s.app; group: "Panel"; key: "clock_date"; Kirigami.FormData.label: "Data:"; text: checked ? "mostrar" : "esconder" }
    Choice { app: s.app; group: "Panel"; key: "date_format"; enabled: s.v("clock_date") === "true"; Kirigami.FormData.label: "Formato da data:"
        options: [ { text: "Curta (21/11/2026)", value: "shortDate" }, { text: "Longa (21 de novembro)", value: "longDate" }, { text: "ISO (2026-11-21)", value: "isoDate" }, { text: "Personalizada", value: "custom" } ] }
    TextSetting { app: s.app; group: "Panel"; key: "custom_date"; visible: s.v("date_format") === "custom"; placeholderText: "ex.: ddd d MMM"; Kirigami.FormData.label: "Data personalizada:" }
    Choice { app: s.app; group: "Panel"; key: "date_position"; enabled: s.v("clock_date") === "true"; Kirigami.FormData.label: "Data em relação à hora:"
        options: [ { text: "Automático", value: "0" }, { text: "Ao lado", value: "1" }, { text: "Embaixo", value: "2" } ] }
    Toggle { app: s.app; group: "Panel"; key: "clock_bold"; Kirigami.FormData.label: "Negrito:"; text: checked ? "sim" : "não" }
    Toggle { app: s.app; group: "Panel"; key: "clock_auto_font"; Kirigami.FormData.label: "Tamanho automático:"; text: checked ? "sim" : "escolher" }
    ValueSlider { app: s.app; group: "Panel"; key: "clock_font_size"; from: 7; to: 24; unit: " pt"; enabled: s.v("clock_auto_font") !== "true"; Kirigami.FormData.label: "Tamanho da letra:" }
}
