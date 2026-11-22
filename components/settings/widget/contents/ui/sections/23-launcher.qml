// Section: launcher — type and options (module launcher.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Menu iniciar: tipo e opções"
    icon: "application-menu"
    preview: Component { PreviewLauncher { app: s.app } }
    description: "Escolha o tipo de menu e como ele mostra os apps. Muda na hora; os valores abaixo são os do seu painel agora. A aparência (vidro, cantos, sombra) fica na aba \"Menu iniciar e pop-ups\"."
    readonly property bool kickoff: !!(app && app.cfg.Launcher && app.cfg.Launcher.type === "kickoff")
    Choice {
        app: s.app; group: "Launcher"; key: "type"
        Kirigami.FormData.label: "Tipo de menu:"
        options: [ { text: "Kickoff (com abas e favoritos)", value: "kickoff" },
                  { text: "Clássico (lista com submenus)", value: "classic" },
                  { text: "Tela cheia", value: "fullscreen" } ]
    }
    Choice {
        app: s.app; group: "Launcher"; key: "favorites"; visible: s.kickoff
        Kirigami.FormData.label: "Favoritos:"
        options: [ { text: "Grade", value: "0" }, { text: "Lista", value: "1" } ]
    }
    Choice {
        app: s.app; group: "Launcher"; key: "applications"; visible: s.kickoff
        Kirigami.FormData.label: "Todos os aplicativos:"
        options: [ { text: "Grade", value: "0" }, { text: "Lista", value: "1" } ]
    }
    Toggle { app: s.app; group: "Launcher"; key: "compact"; visible: s.kickoff; Kirigami.FormData.label: "Itens compactos:"; text: checked ? "sim" : "não" }
    Toggle { app: s.app; group: "Launcher"; key: "sidebar_right"; visible: s.kickoff; Kirigami.FormData.label: "Categorias à direita:"; text: checked ? "sim" : "não (à esquerda)" }
    Toggle { app: s.app; group: "Launcher"; key: "switch_on_hover"; visible: s.kickoff; Kirigami.FormData.label: "Trocar categoria ao passar o mouse:"; text: checked ? "sim" : "só com clique" }
    Choice {
        app: s.app; group: "Launcher"; key: "footer"; visible: s.kickoff
        Kirigami.FormData.label: "Botões do rodapé:"
        options: [ { text: "Energia (suspender, reiniciar, desligar)", value: "0" },
                  { text: "Sessão (bloquear, sair)", value: "1" },
                  { text: "Energia e sessão", value: "3" } ]
    }
    Toggle { app: s.app; group: "Launcher"; key: "captions"; visible: s.kickoff; Kirigami.FormData.label: "Nomes nos botões:"; text: checked ? "mostrar" : "só ícones" }
    Choice {
        app: s.app; group: "Launcher"; key: "name_format"
        Kirigami.FormData.label: "Nome dos apps:"
        options: [ { text: "Só o nome (Firefox)", value: "0" },
                  { text: "Só a descrição (Navegador)", value: "1" },
                  { text: "Nome e descrição", value: "2" },
                  { text: "Descrição e nome", value: "3" } ]
    }
    Toggle { app: s.app; group: "Launcher"; key: "alphabetical"; Kirigami.FormData.label: "Ordem alfabética:"; text: checked ? "sim" : "ordem do sistema" }
    Toggle { app: s.app; group: "Launcher"; key: "highlight_new"; visible: s.kickoff; Kirigami.FormData.label: "Destacar apps novos:"; text: checked ? "sim" : "não" }
    Choice {
        app: s.app; group: "Launcher"; key: "icon"
        Kirigami.FormData.label: "Ícone do botão:"
        options: [ { text: "Círculo (start-here-symbolic)", value: "start-here-symbolic" },
                  { text: "KDE", value: "start-here-kde-symbolic" },
                  { text: "KDE colorido", value: "start-here-kde" },
                  { text: "Grade de apps", value: "view-app-grid-symbolic" },
                  { text: "Menu (três linhas)", value: "application-menu" },
                  { text: "Distribuição", value: "distributor-logo" } ]
    }
    TextSetting { app: s.app; group: "Launcher"; key: "label"; placeholderText: "(sem texto)"; Kirigami.FormData.label: "Texto ao lado do ícone:" }
}
