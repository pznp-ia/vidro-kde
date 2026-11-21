// Seção: botões das janelas (módulo botoes.py — desenho no gerar-vidro.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Botões das janelas"
    icone: "window-close"
    previa: Component { PreviaBotoes { app: s.app } }
    descricao: "Lado, ordem e estilo dos botões fechar, minimizar e maximizar. Na janela ativa do exemplo, um botão aparece como fica ao passar o mouse. Ao mudar, as barras de título piscam uma vez."
    function v(k) { return (app && app.cfg.Botoes) ? String(app.cfg.Botoes[k]) : "" }
    Escolha { app: s.app; grupo: "Botoes"; chave: "posicao"; Kirigami.FormData.label: "Lado:"
        opcoes: [ { texto: "Esquerda (como no macOS)", valor: "esquerda" }, { texto: "Direita (como no Windows)", valor: "direita" } ] }
    Escolha { app: s.app; grupo: "Botoes"; chave: "ordem"; Kirigami.FormData.label: "Ordem:"
        opcoes: [ { texto: "Fechar, minimizar, maximizar", valor: "macos" }, { texto: "Minimizar, maximizar, fechar", valor: "windows" } ] }
    Chave { app: s.app; grupo: "Botoes"; chave: "menu"; Kirigami.FormData.label: "Botão de menu da janela:"; text: checked ? "no outro lado" : "não" }
    Escolha { app: s.app; grupo: "Botoes"; chave: "estilo"; Kirigami.FormData.label: "Estilo:"
        opcoes: [ { texto: "Semáforo (símbolo ao passar o mouse)", valor: "semaforo" },
                  { texto: "Semáforo com símbolos", valor: "simbolos" },
                  { texto: "Grafite (cor ao passar o mouse)", valor: "grafite" },
                  { texto: "Contorno (anéis coloridos)", valor: "contorno" },
                  { texto: "Só ícones (sem círculo)", valor: "icones" },
                  { texto: "Quadrados arredondados", valor: "quadrado" } ] }
    Deslizante { app: s.app; grupo: "Botoes"; chave: "tamanho"; de: 4; ate: 9; passo: 0.5; unidade: ""; Kirigami.FormData.label: "Tamanho:" }
    Deslizante { app: s.app; grupo: "Botoes"; chave: "espaco"; de: 0; ate: 12; unidade: " px"; Kirigami.FormData.label: "Espaço entre eles:" }
    Escolha { app: s.app; grupo: "Botoes"; chave: "inativos"; Kirigami.FormData.label: "Em janelas inativas:"
        opcoes: [ { texto: "Cinza", valor: "cinza" }, { texto: "Coloridos", valor: "cor" } ] }
    Escolha { app: s.app; grupo: "Botoes"; chave: "cor"; Kirigami.FormData.label: "Cores:"
        opcoes: [ { texto: "Vermelho, amarelo e verde", valor: "semaforo" }, { texto: "Todos de uma cor", valor: "unica" } ] }
    Cor { app: s.app; grupo: "Botoes"; chave: "cor_unica"; visible: s.v("cor") === "unica"; Kirigami.FormData.label: "Cor:" }
}
