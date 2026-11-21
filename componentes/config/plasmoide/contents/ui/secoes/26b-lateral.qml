// Seção: ícones pequenos da lateral (Dolphin, diálogos) — módulo icones.py
import QtQuick
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Ícones da lateral (Dolphin)"
    icone: "sidebar-show"
    previa: Component { PreviaLateral { app: s.app } }
    descricao: "Os ícones pequenos de Início, Downloads, Lixeira etc. na lateral do Dolphin e dos diálogos de abrir/salvar. Reabra o Dolphin para ver o tamanho novo."
    function v(k) { return (app && app.cfg.Icones) ? String(app.cfg.Icones[k]) : "" }
    Escolha { app: s.app; grupo: "Icones"; chave: "lado_estilo"; Kirigami.FormData.label: "Estilo:"
        opcoes: [ { texto: "Linha", valor: "linha" }, { texto: "Preenchido (ícone num quadrado)", valor: "preenchido" }, { texto: "Colorido (uma cor por local)", valor: "colorido" } ] }
    Cor { app: s.app; grupo: "Icones"; chave: "lado_cor"; visible: s.v("lado_estilo") !== "colorido"; Kirigami.FormData.label: "Cor:" }
    Deslizante { app: s.app; grupo: "Icones"; chave: "lado_traco"; de: 0.8; ate: 2.2; passo: 0.1; unidade: ""; Kirigami.FormData.label: "Espessura do traço:" }
    Escolha { app: s.app; grupo: "Icones"; chave: "lado_tamanho"; Kirigami.FormData.label: "Tamanho no Dolphin:"
        opcoes: [ { texto: "Automático", valor: "auto" }, { texto: "Pequeno (16 px)", valor: "16" }, { texto: "Médio (22 px)", valor: "22" }, { texto: "Grande (32 px)", valor: "32" } ] }
}
