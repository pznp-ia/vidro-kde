// Seção: ícones de arquivos (módulo icones.py → gerar-icones.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Ícones de arquivos"
    icone: "text-x-generic"
    previa: Component { PreviaArquivos { app: s.app } }
    descricao: "Como aparecem documentos, imagens, compactados e outros arquivos no Dolphin e nos diálogos. Muda na hora (leva alguns segundos para refazer os ícones)."
    function v(k) { return (app && app.cfg.Icones) ? String(app.cfg.Icones[k]) : "" }
    Escolha { app: s.app; grupo: "Icones"; chave: "doc_estilo"; Kirigami.FormData.label: "Papel:"
        opcoes: [ { texto: "Escuro", valor: "escuro" }, { texto: "Claro", valor: "claro" }, { texto: "Colorido pelo tipo", valor: "colorido" }, { texto: "Plano (sem degradê)", valor: "plano" } ] }
    Chave { app: s.app; grupo: "Icones"; chave: "doc_rotulo"; Kirigami.FormData.label: "Etiqueta da extensão:"; text: checked ? "mostrar (PDF, PNG…)" : "esconder" }
    Escolha { app: s.app; grupo: "Icones"; chave: "doc_cores"; Kirigami.FormData.label: "Cores:"
        opcoes: [ { texto: "Uma cor por tipo", valor: "tipo" }, { texto: "Todos de uma cor", valor: "unica" }, { texto: "Cinza", valor: "cinza" } ] }
    Cor { app: s.app; grupo: "Icones"; chave: "doc_cor"; visible: s.v("doc_cores") === "unica"; Kirigami.FormData.label: "Cor:" }
    Chave { app: s.app; grupo: "Icones"; chave: "doc_dobra"; Kirigami.FormData.label: "Canto dobrado:"; text: checked ? "sim" : "não (retângulo)" }
    Deslizante { app: s.app; grupo: "Icones"; chave: "doc_raio"; de: 0; ate: 10; unidade: " px"; Kirigami.FormData.label: "Cantos:" }
}
