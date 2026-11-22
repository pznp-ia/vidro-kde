// Section: file icons (module icons.py → make-icons.py)
import QtQuick
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Ícones de arquivos"
    icon: "text-x-generic"
    preview: Component { PreviewFiles { app: s.app } }
    description: "Como aparecem documentos, imagens, compactados e outros arquivos no Dolphin e nos diálogos. Muda na hora (leva alguns segundos para refazer os ícones)."
    function v(k) { return (app && app.cfg.Icons) ? String(app.cfg.Icons[k]) : "" }
    Choice { app: s.app; group: "Icons"; key: "file_style"; Kirigami.FormData.label: "Papel:"
        options: [ { text: "Escuro", value: "dark" }, { text: "Claro", value: "light" }, { text: "Colorido pelo tipo", value: "colored" }, { text: "Plano (sem degradê)", value: "flat" } ] }
    Toggle { app: s.app; group: "Icons"; key: "file_label"; Kirigami.FormData.label: "Etiqueta da extensão:"; text: checked ? "mostrar (PDF, PNG…)" : "esconder" }
    Choice { app: s.app; group: "Icons"; key: "file_colors"; Kirigami.FormData.label: "Cores:"
        options: [ { text: "Uma cor por tipo", value: "type" }, { text: "Todos de uma cor", value: "single" }, { text: "Cinza", value: "gray" } ] }
    ColorButton { app: s.app; group: "Icons"; key: "file_color"; visible: s.v("file_colors") === "single"; Kirigami.FormData.label: "Cor:" }
    Toggle { app: s.app; group: "Icons"; key: "file_fold"; Kirigami.FormData.label: "Canto dobrado:"; text: checked ? "sim" : "não (retângulo)" }
    ValueSlider { app: s.app; group: "Icons"; key: "file_radius"; from: 0; to: 10; unit: " px"; Kirigami.FormData.label: "Cantos:" }
}
