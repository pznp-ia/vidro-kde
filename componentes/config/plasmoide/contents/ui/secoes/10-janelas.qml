// Seção: transparência das janelas (efeito vidro_opacity, comando vidro-transparencia)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Janelas"
    icone: "window"
    previa: Component { PreviaJanela { app: s.app } }
    descricao: "Transparência (0 = opacas; 100 = ativa 75%, inativas 60%) e cor da barra de título. Mudam na hora."
    RowLayout {
        Kirigami.FormData.label: "Transparência:"
        QQC2.Slider {
            id: sl; Layout.fillWidth: true; Layout.minimumWidth: 160
            from: 0; to: 100; stepSize: 5; snapMode: QQC2.Slider.SnapAlways
            value: (s.app && s.app.cfg.Janelas && s.app.cfg.Janelas.transparencia !== undefined) ? Number(s.app.cfg.Janelas.transparencia) : 50
            onMoved: aplicar.restart()
            Timer { id: aplicar; interval: 120; onTriggered: s.app.rodar("$HOME/.local/bin/vidro-transparencia " + Math.round(sl.value)) }
        }
        QQC2.Label { text: Math.round(sl.value) + "%"; Layout.minimumWidth: 44; opacity: 0.75; horizontalAlignment: Text.AlignRight }
    }
    Escolha {
        app: s.app; grupo: "Janelas"; chave: "barra"
        Kirigami.FormData.label: "Cor da barra de título:"
        opcoes: [ { texto: "Automática (pelo papel de parede)", valor: "tema" }, { texto: "Cor personalizada", valor: "cor" } ]
    }
    Cor { app: s.app; grupo: "Janelas"; chave: "cor_barra"; visible: !!(s.app && s.app.cfg.Janelas && s.app.cfg.Janelas.barra === "cor"); Kirigami.FormData.label: "Cor:" }
}
