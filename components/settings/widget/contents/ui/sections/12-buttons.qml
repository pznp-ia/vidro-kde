// Section: window buttons (module buttons.py — drawn by make-decoration.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Botões das janelas (estúdio)"
    icon: "window-close"
    preview: Component { PreviewButtons { app: s.app } }
    description: "Lado, ordem e estilo dos botões fechar, minimizar e maximizar. Na janela ativa do exemplo, um botão aparece como fica ao passar o mouse. Ao mudar, as barras de título piscam uma vez."
    function v(k) { return (app && app.cfg.Buttons) ? String(app.cfg.Buttons[k]) : "" }
    Choice { app: s.app; group: "Buttons"; key: "side"; Kirigami.FormData.label: "Lado:"
        options: [ { text: "Esquerda (como no macOS)", value: "left" }, { text: "Direita (como no Windows)", value: "right" } ] }
    Choice { app: s.app; group: "Buttons"; key: "order"; Kirigami.FormData.label: "Ordem:"
        options: [ { text: "Fechar, minimizar, maximizar", value: "macos" }, { text: "Minimizar, maximizar, fechar", value: "windows" } ] }
    Toggle { app: s.app; group: "Buttons"; key: "menu"; Kirigami.FormData.label: "Botão de menu da janela:"; text: checked ? "no outro lado" : "não" }
    Choice { app: s.app; group: "Buttons"; key: "style"; Kirigami.FormData.label: "Estilo:"
        options: [ { text: "Semáforo (símbolo ao passar o mouse)", value: "traffic" },
                  { text: "Semáforo com símbolos", value: "symbols" },
                  { text: "Grafite (cor ao passar o mouse)", value: "graphite" },
                  { text: "Contorno (anéis coloridos)", value: "outline" },
                  { text: "Só ícones (sem círculo)", value: "icons" },
                  { text: "Quadrados arredondados", value: "square" } ] }
    ValueSlider { app: s.app; group: "Buttons"; key: "size"; from: 4; to: 9; step: 0.5; unit: ""; Kirigami.FormData.label: "Tamanho:" }
    ValueSlider { app: s.app; group: "Buttons"; key: "spacing"; from: 0; to: 12; unit: " px"; Kirigami.FormData.label: "Espaço entre eles:" }
    Choice { app: s.app; group: "Buttons"; key: "inactive"; Kirigami.FormData.label: "Em janelas inativas:"
        options: [ { text: "Cinza", value: "gray" }, { text: "Coloridos", value: "color" } ] }
    Choice { app: s.app; group: "Buttons"; key: "color_mode"; Kirigami.FormData.label: "Cores:"
        options: [ { text: "Vermelho, amarelo e verde", value: "traffic" }, { text: "Todos de uma cor", value: "single" }, { text: "Uma cor para cada", value: "custom" } ] }
    ColorButton { app: s.app; group: "Buttons"; key: "single_color"; visible: s.v("color_mode") === "single"; Kirigami.FormData.label: "Cor:" }
    ColorButton { app: s.app; group: "Buttons"; key: "close_color"; visible: s.v("color_mode") === "custom"; Kirigami.FormData.label: "Fechar:" }
    ColorButton { app: s.app; group: "Buttons"; key: "minimize_color"; visible: s.v("color_mode") === "custom"; Kirigami.FormData.label: "Minimizar:" }
    ColorButton { app: s.app; group: "Buttons"; key: "maximize_color"; visible: s.v("color_mode") === "custom"; Kirigami.FormData.label: "Maximizar:" }
    Choice { app: s.app; group: "Buttons"; key: "symbols"; Kirigami.FormData.label: "Símbolos (×, –, ⤢):"
        options: [ { text: "Como o estilo faz", value: "auto" }, { text: "Só ao passar o mouse", value: "hover" }, { text: "Sempre", value: "always" }, { text: "Nunca", value: "never" } ] }
    ValueSlider { app: s.app; group: "Buttons"; key: "symbol_weight"; from: 0.8; to: 2.4; step: 0.1; enabled: s.v("symbols") !== "never"; Kirigami.FormData.label: "Espessura do símbolo:" }
    Choice { app: s.app; group: "Buttons"; key: "hover"; Kirigami.FormData.label: "Ao passar o mouse:"
        options: [ { text: "Como o estilo faz", value: "style" }, { text: "Clarear", value: "brighten" }, { text: "Brilho em volta", value: "glow" }, { text: "Nada muda", value: "none" } ] }
}
