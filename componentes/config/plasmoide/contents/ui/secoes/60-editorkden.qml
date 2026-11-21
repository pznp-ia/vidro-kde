// Seção: EditorKden (módulo ~/.local/share/vidro/modulos/editorkden.py)
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "EditorKden (Kdenlive)"
    icone: "kdenlive"
    previa: Component { PreviaSimples { app: s.app; destaque: (s.app && s.app.cfg.EditorKden && s.app.cfg.EditorKden.cor) ? s.app.cfg.EditorKden.cor : "#0a84ff"; raio: (s.app && s.app.cfg.EditorKden && s.app.cfg.EditorKden.arredondamento !== undefined) ? Number(s.app.cfg.EditorKden.arredondamento) : 10 } }
    descricao: "Kdenlive com visual minimalista inspirado no macOS, com configuração própria (o Kdenlive normal não muda). Abra pelo menu: EditorKden."
    readonly property bool ligado: !!(app && app.cfg.EditorKden && app.cfg.EditorKden.ativo === "true")
    Chave { app: s.app; grupo: "EditorKden"; chave: "ativo"; Kirigami.FormData.label: "EditorKden:"; text: checked ? "instalado no menu" : "desligado" }
    Cor { app: s.app; grupo: "EditorKden"; chave: "cor"; enabled: s.ligado; Kirigami.FormData.label: "Cor de destaque:" }
    Deslizante { app: s.app; grupo: "EditorKden"; chave: "fundo"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Claridade do grafite:" }
    Deslizante { app: s.app; grupo: "EditorKden"; chave: "contraste"; unidade: "%"; enabled: s.ligado; Kirigami.FormData.label: "Contraste dos painéis:" }
    Deslizante { app: s.app; grupo: "EditorKden"; chave: "arredondamento"; de: 0; ate: 16; unidade: " px"; enabled: s.ligado; Kirigami.FormData.label: "Arredondamento:" }
    Deslizante { app: s.app; grupo: "EditorKden"; chave: "fonte"; de: 8; ate: 14; unidade: " pt"; enabled: s.ligado; Kirigami.FormData.label: "Tamanho da letra:" }
    Chave { app: s.app; grupo: "EditorKden"; chave: "titulos"; enabled: s.ligado; Kirigami.FormData.label: "Títulos dos painéis:"; text: checked ? "visíveis" : "escondidos" }
    Chave { app: s.app; grupo: "EditorKden"; chave: "boasvindas"; enabled: s.ligado; Kirigami.FormData.label: "Tela de boas-vindas:"; text: checked ? "mostrar" : "abrir direto no editor" }
}
