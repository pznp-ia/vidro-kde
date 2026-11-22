// Section: animations (module animations.py → KWin effects vidro_windows, vidro_minimize, vidro_maximize, vidro_desktop)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Animações"
    icon: "kwin"
    description: "Abrir, fechar, minimizar, maximizar e mostrar a área de trabalho. Todas são leves (feitas pela própria KWin) e mudam na hora. Use \"Testar\" para ver no exemplo."
    preview: Component { PreviewAnimations { id: pv; app: s.app; Component.onCompleted: s.previewItem = pv } }
    property var previewItem: null
    function v(k) { return (app && app.cfg.Animations) ? String(app.cfg.Animations[k]) : "" }
    component TestButton: QQC2.Button { property string kind; text: "Testar"; icon.name: "media-playback-start"; onClicked: if (s.previewItem) s.previewItem.play(kind) }

    Choice { app: s.app; group: "Animations"; key: "curve"; Kirigami.FormData.label: "Movimento:"
        options: [ { text: "Suave", value: "smooth" }, { text: "Ágil (começa rápido)", value: "snappy" }, { text: "Mola (passa um pouco e volta)", value: "spring" } ] }
    ValueSlider { app: s.app; group: "Animations"; key: "speed"; from: 25; to: 300; step: 5; unit: "%"; Kirigami.FormData.label: "Velocidade geral do KDE:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Abrir e fechar janelas" }
    RowLayout { Kirigami.FormData.label: "Abrir:"
        Choice { app: s.app; group: "Animations"; key: "open_style"
            options: [ { text: "Crescer de leve", value: "scale" }, { text: "Zoom", value: "zoom" }, { text: "Subir deslizando", value: "glide" },
                       { text: "Pop (com quique)", value: "pop" }, { text: "Aparecer (fade)", value: "fade" }, { text: "Nenhuma", value: "none" } ] }
        TestButton { kind: "open" } }
    ValueSlider { app: s.app; group: "Animations"; key: "open_ms"; from: 80; to: 800; step: 10; unit: " ms"; enabled: s.v("open_style") !== "none"; Kirigami.FormData.label: "Duração ao abrir:" }
    RowLayout { Kirigami.FormData.label: "Fechar:"
        Choice { app: s.app; group: "Animations"; key: "close_style"
            options: [ { text: "Encolher de leve", value: "scale" }, { text: "Zoom", value: "zoom" }, { text: "Descer deslizando", value: "glide" },
                       { text: "Pop", value: "pop" }, { text: "Sumir (fade)", value: "fade" }, { text: "Nenhuma", value: "none" } ] }
        TestButton { kind: "close" } }
    ValueSlider { app: s.app; group: "Animations"; key: "close_ms"; from: 80; to: 800; step: 10; unit: " ms"; enabled: s.v("close_style") !== "none"; Kirigami.FormData.label: "Duração ao fechar:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Minimizar e maximizar" }
    RowLayout { Kirigami.FormData.label: "Minimizar:"
        Choice { app: s.app; group: "Animations"; key: "minimize_style"
            options: [ { text: "Ir até o ícone na barra", value: "icon" }, { text: "Encolher no lugar", value: "scale" },
                       { text: "Sumir (fade)", value: "fade" }, { text: "Cair", value: "drop" }, { text: "Nenhuma", value: "none" } ] }
        TestButton { kind: "minimize" } }
    ValueSlider { app: s.app; group: "Animations"; key: "minimize_ms"; from: 80; to: 900; step: 10; unit: " ms"; enabled: s.v("minimize_style") !== "none"; Kirigami.FormData.label: "Duração:" }
    RowLayout { Kirigami.FormData.label: "Maximizar:"
        Choice { app: s.app; group: "Animations"; key: "maximize_style"
            options: [ { text: "Transformar (esticar suave)", value: "morph" }, { text: "Esmaecer", value: "fade" }, { text: "Nenhuma", value: "none" } ] }
        TestButton { kind: "maximize" } }
    ValueSlider { app: s.app; group: "Animations"; key: "maximize_ms"; from: 80; to: 800; step: 10; unit: " ms"; enabled: s.v("maximize_style") !== "none"; Kirigami.FormData.label: "Duração:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Mostrar área de trabalho" }
    RowLayout { Kirigami.FormData.label: "Janelas:"
        Choice { app: s.app; group: "Animations"; key: "desktop_style"
            options: [ { text: "Vão para os cantos", value: "corners" }, { text: "Deslizam para o lado", value: "slide" },
                       { text: "Afundam", value: "sink" }, { text: "Somem (fade)", value: "fade" }, { text: "Nenhuma", value: "none" } ] }
        TestButton { kind: "desktop" } }
    ValueSlider { app: s.app; group: "Animations"; key: "desktop_ms"; from: 80; to: 900; step: 10; unit: " ms"; enabled: s.v("desktop_style") !== "none"; Kirigami.FormData.label: "Duração:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Menus e pop-ups" }
    Toggle { app: s.app; group: "Menus"; key: "animation"; Kirigami.FormData.label: "Animar:"; text: checked ? "sim" : "não (aparecem na hora)" }
    Choice { app: s.app; group: "Menus"; key: "panel_style"; Kirigami.FormData.label: "Menu iniciar, relógio, bandeja:"
        options: [ { text: "Subir direto (sem transparência)", value: "slide" }, { text: "Aparecer (fade)", value: "fade" },
                   { text: "Crescer", value: "scale" }, { text: "Nenhuma", value: "none" } ] }
    Choice { app: s.app; group: "Menus"; key: "menu_style"; Kirigami.FormData.label: "Menus de clique direito e dicas:"
        options: [ { text: "Aparecer e crescer de leve", value: "fadescale" }, { text: "Aparecer (fade)", value: "fade" },
                   { text: "Deslizar", value: "slide" }, { text: "Nenhuma", value: "none" } ] }
    ValueSlider { app: s.app; group: "Menus"; key: "open_ms"; from: 40; to: 400; step: 10; unit: " ms"; Kirigami.FormData.label: "Duração ao abrir:" }
    ValueSlider { app: s.app; group: "Menus"; key: "close_ms"; from: 40; to: 400; step: 10; unit: " ms"; Kirigami.FormData.label: "Duração ao fechar:" }
    ValueSlider { app: s.app; group: "Menus"; key: "scale"; from: 80; to: 100; unit: "%"; Kirigami.FormData.label: "Tamanho inicial (crescer):" }
    ValueSlider { app: s.app; group: "Menus"; key: "slide"; from: 0; to: 60; unit: " px"; Kirigami.FormData.label: "Distância (deslizar):" }
}
