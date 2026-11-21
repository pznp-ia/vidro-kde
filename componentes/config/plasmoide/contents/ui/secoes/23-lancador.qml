// Seção: menu iniciar — tipo e opções (módulo lancador.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Menu iniciar: tipo e opções"
    icone: "application-menu"
    previa: Component { PreviaLancador { app: s.app } }
    descricao: "Escolha o tipo de menu e como ele mostra os apps. Muda na hora; os valores abaixo são os do seu painel agora. A aparência (vidro, cantos, sombra) fica na aba \"Menu iniciar e pop-ups\"."
    readonly property bool kickoff: !!(app && app.cfg.Lancador && app.cfg.Lancador.tipo === "kickoff")
    Escolha {
        app: s.app; grupo: "Lancador"; chave: "tipo"
        Kirigami.FormData.label: "Tipo de menu:"
        opcoes: [ { texto: "Kickoff (com abas e favoritos)", valor: "kickoff" },
                  { texto: "Clássico (lista com submenus)", valor: "classico" },
                  { texto: "Tela cheia", valor: "telacheia" } ]
    }
    Escolha {
        app: s.app; grupo: "Lancador"; chave: "favoritos"; visible: s.kickoff
        Kirigami.FormData.label: "Favoritos:"
        opcoes: [ { texto: "Grade", valor: "0" }, { texto: "Lista", valor: "1" } ]
    }
    Escolha {
        app: s.app; grupo: "Lancador"; chave: "aplicativos"; visible: s.kickoff
        Kirigami.FormData.label: "Todos os aplicativos:"
        opcoes: [ { texto: "Grade", valor: "0" }, { texto: "Lista", valor: "1" } ]
    }
    Chave { app: s.app; grupo: "Lancador"; chave: "compacto"; visible: s.kickoff; Kirigami.FormData.label: "Itens compactos:"; text: checked ? "sim" : "não" }
    Chave { app: s.app; grupo: "Lancador"; chave: "lateral_direita"; visible: s.kickoff; Kirigami.FormData.label: "Categorias à direita:"; text: checked ? "sim" : "não (à esquerda)" }
    Chave { app: s.app; grupo: "Lancador"; chave: "passar_mouse"; visible: s.kickoff; Kirigami.FormData.label: "Trocar categoria ao passar o mouse:"; text: checked ? "sim" : "só com clique" }
    Escolha {
        app: s.app; grupo: "Lancador"; chave: "rodape"; visible: s.kickoff
        Kirigami.FormData.label: "Botões do rodapé:"
        opcoes: [ { texto: "Energia (suspender, reiniciar, desligar)", valor: "0" },
                  { texto: "Sessão (bloquear, sair)", valor: "1" },
                  { texto: "Energia e sessão", valor: "3" } ]
    }
    Chave { app: s.app; grupo: "Lancador"; chave: "legendas"; visible: s.kickoff; Kirigami.FormData.label: "Nomes nos botões:"; text: checked ? "mostrar" : "só ícones" }
    Escolha {
        app: s.app; grupo: "Lancador"; chave: "nomes"
        Kirigami.FormData.label: "Nome dos apps:"
        opcoes: [ { texto: "Só o nome (Firefox)", valor: "0" },
                  { texto: "Só a descrição (Navegador)", valor: "1" },
                  { texto: "Nome e descrição", valor: "2" },
                  { texto: "Descrição e nome", valor: "3" } ]
    }
    Chave { app: s.app; grupo: "Lancador"; chave: "alfabetica"; Kirigami.FormData.label: "Ordem alfabética:"; text: checked ? "sim" : "ordem do sistema" }
    Chave { app: s.app; grupo: "Lancador"; chave: "novos"; visible: s.kickoff; Kirigami.FormData.label: "Destacar apps novos:"; text: checked ? "sim" : "não" }
    Escolha {
        app: s.app; grupo: "Lancador"; chave: "icone"
        Kirigami.FormData.label: "Ícone do botão:"
        opcoes: [ { texto: "Círculo (start-here-symbolic)", valor: "start-here-symbolic" },
                  { texto: "KDE", valor: "start-here-kde-symbolic" },
                  { texto: "KDE colorido", valor: "start-here-kde" },
                  { texto: "Grade de apps", valor: "view-app-grid-symbolic" },
                  { texto: "Menu (três linhas)", valor: "application-menu" },
                  { texto: "Distribuição", valor: "distributor-logo" } ]
    }
    Texto { app: s.app; grupo: "Lancador"; chave: "texto"; placeholderText: "(sem texto)"; Kirigami.FormData.label: "Texto ao lado do ícone:" }
}
