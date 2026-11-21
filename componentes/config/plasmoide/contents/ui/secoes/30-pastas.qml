// Seção: Dolphin (módulo ~/.local/share/vidro/modulos/pastas.py)
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Pastas (Dolphin)"
    icone: "system-file-manager"
    previa: Component { PreviaDolphin { app: s.app } }
    descricao: "Sem linhas de separação e com a área de arquivos na cor da interface. Reabra o Dolphin para ver. O fundo das listas vem do esquema de cores, então também vale para as listas dos outros apps do KDE."
    readonly property bool ligado: !!(app && app.cfg.Pastas && app.cfg.Pastas.ativo === "true")
    readonly property bool fundo: !!(app && app.cfg.Pastas && app.cfg.Pastas.unificar === "true")
    Chave { app: s.app; grupo: "Pastas"; chave: "ativo"; Kirigami.FormData.label: "Dolphin fluido:"; text: checked ? "ligado" : "desligado (igual aos outros apps)" }
    Deslizante { app: s.app; grupo: "Pastas"; chave: "linhas"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Linhas de separação:" }
    Deslizante { app: s.app; grupo: "Pastas"; chave: "espaco"; de: 0; ate: 16; unidade: " px"; enabled: s.ligado; Kirigami.FormData.label: "Respiro entre as partes:" }
    Chave { app: s.app; grupo: "Pastas"; chave: "unificar"; enabled: s.ligado; Kirigami.FormData.label: "Fundo dos arquivos:"; text: checked ? "na cor da interface" : "escuro original" }
    Escolha {
        app: s.app; grupo: "Pastas"; chave: "cor"; enabled: s.ligado
        Kirigami.FormData.label: "Cor do fundo:"
        opcoes: [ { texto: "Cor da interface", valor: "interface" }, { texto: "Cor personalizada", valor: "cor" } ]
    }
    Cor { app: s.app; grupo: "Pastas"; chave: "cor_fundo"; visible: !!(s.app && s.app.cfg.Pastas && s.app.cfg.Pastas.cor === "cor"); enabled: s.ligado; Kirigami.FormData.label: "Cor:" }
    Deslizante { app: s.app; grupo: "Pastas"; chave: "escuro"; unidade: "%"; enabled: s.ligado && s.fundo; Kirigami.FormData.label: "Cor escolhida ↔ mais escuro:" }
}
