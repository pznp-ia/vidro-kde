// Seção: versão clara (TESTE) — módulo ~/.local/share/vidro/modulos/claro.py
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Versão clara (teste)"
    icone: "weather-clear"
    previa: Component { PreviaSimples { app: s.app; clara: !!(s.app && s.app.cfg.Claro && s.app.cfg.Claro.ativo === "true"); vidro: (s.app && s.app.cfg.Claro && s.app.cfg.Claro.vidro !== undefined) ? Number(s.app.cfg.Claro.vidro) / 100 : 1 } }
    descricao: "Cores claras com as mesmas transparências. Ícones pequenos da lateral ainda são feitos para o escuro."
    readonly property bool ligado: !!(app && app.cfg.Claro && app.cfg.Claro.ativo === "true")
    Chave { app: s.app; grupo: "Claro"; chave: "ativo"; Kirigami.FormData.label: "Vidro claro:"; text: checked ? "ligado" : "desligado (escuro)" }
    Deslizante { app: s.app; grupo: "Claro"; chave: "vidro"; de: 20; ate: 160; passo: 5; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Opacidade da barra de título:" }
}
