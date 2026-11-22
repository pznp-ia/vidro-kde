// Section: login screen (module login.py; applying to the system asks for the admin password)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "../common"
Section {
    id: s
    title: "Tela de login"
    icon: "system-users"
    preview: Component { PreviewLogin { app: s.app } }
    description: "A tela que pede a senha ao ligar o PC (SDDM). As mudanças ficam prontas aqui; para valerem no próximo boot use \"Aplicar na tela de login\" (pede a senha de administrador)."
    function v(k) { return (app && app.cfg.Login) ? String(app.cfg.Login[k]) : "" }
    property string result: ""
    property bool applying: false
    property var wallpapers: []
    property bool galleryLoading: false
    property bool showAll: false
    function loadGallery() {
        if (galleryLoading || wallpapers.length) return;
        galleryLoading = true;
        exec.connectSource("python3 -I \"$HOME/.local/share/vidro/modules/login.py\" --gallery #login-gallery" + Date.now());
    }
    function fileName(p) { return String(p).split("/").pop(); }
    function chooseFile(path) { s.app.set("Login", "file", path); s.app.set("Login", "background", "file"); }
    P5Support.DataSource {
        id: exec; engine: "executable"
        onNewData: (source, data) => {
            if (source.indexOf("#login-gallery") >= 0) {
                try { s.wallpapers = JSON.parse(String(data["stdout"] || "[]")); } catch (e) { s.wallpapers = []; }
                s.galleryLoading = false;
            } else if (source.indexOf("#login-apply") >= 0) {
                s.applying = false;
                s.result = data["exit code"] === 0 ? "Pronto! A tela de login nova aparece no próximo boot."
                    : "Não foi aplicado. " + String(data["stderr"] || data["stdout"] || "").trim().split("\n").slice(-2).join(" ");
            }
            disconnectSource(source);
        }
    }
    RowLayout {
        Kirigami.FormData.label: ""
        QQC2.Button { text: "Prévia em janela"; icon.name: "view-preview"
            onClicked: s.app.run("(\"$HOME/.local/bin/vidro-config\" apply login; P=\"$HOME/.local/share/vidro/bin/vidro-login-preview\"; T=\"$HOME/.local/share/vidro/login/theme\"; if [ -x \"$P\" ] && \"$P\" \"$T\"; then :; else QT_IM_MODULE=none sddm-greeter-qt6 --test-mode --theme \"$T\"; fi >/dev/null 2>&1 &) #login-testar" + Date.now()) }
        QQC2.Button { text: "Aplicar na tela de login"; icon.name: "dialog-ok-apply"; highlighted: true; enabled: !s.applying
            onClicked: { s.applying = true; s.result = "Esperando a senha de administrador…"; exec.connectSource("pkexec /bin/bash \"$HOME/.local/share/vidro/login/apply.sh\" #login-apply" + Date.now()) } }
    }
    QQC2.Label { Kirigami.FormData.label: ""; visible: s.result !== ""; text: s.result; wrapMode: Text.WordWrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 24; opacity: 0.8 }
    QQC2.Label { Kirigami.FormData.label: ""; text: "Na prévia: aperte Esc 3 vezes para fechar. Os botões de energia não fazem nada lá, e qualquer senha \"entra\" (fecha a janela)."; wrapMode: Text.WordWrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 24; opacity: 0.55 }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Fundo" }
    Choice { app: s.app; group: "Login"; key: "background"; Kirigami.FormData.label: "Fundo:"
        options: [ { text: "Honeywave (do KDE)", value: "honeywave" }, { text: "Meu papel de parede atual", value: "wallpaper" },
                  { text: "Foto ou papel de parede escolhido", value: "file" }, { text: "Vídeo", value: "video" }, { text: "Cor lisa", value: "color" } ] }

    // ---- photo: gallery of installed wallpapers + any photo ----
    RowLayout {
        Kirigami.FormData.label: "Foto:"
        visible: s.v("background") === "file"
        QQC2.Button { text: "Escolher foto…"; icon.name: "document-open"; onClicked: photoDlg.open() }
        QQC2.Label { text: s.v("file") ? s.fileName(s.v("file")) : "nenhuma escolhida"; opacity: 0.7; elide: Text.ElideMiddle; Layout.maximumWidth: Kirigami.Units.gridUnit * 12 }
    }
    FileDialog {
        id: photoDlg
        title: "Escolha uma foto para a tela de login"
        nameFilters: ["Imagens (*.jpg *.jpeg *.png *.webp)"]
        onAccepted: s.chooseFile(decodeURIComponent(String(selectedFile).replace(/^file:\/\//, "")))
    }
    ColumnLayout {
        Kirigami.FormData.label: "Papéis de parede:"
        visible: s.v("background") === "file" || s.v("background") === "honeywave"
        onVisibleChanged: if (visible) s.loadGallery()
        Component.onCompleted: if (visible) s.loadGallery()
        QQC2.Label { visible: s.galleryLoading; text: "Carregando miniaturas… (só demora na primeira vez)"; opacity: 0.6 }
        Flow {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 27
            spacing: 6
            Repeater {
                model: s.showAll ? s.wallpapers : s.wallpapers.slice(0, 12)
                Rectangle {
                    required property var modelData
                    readonly property bool chosen: s.v("background") === "file" && s.v("file") === modelData.path
                    width: 120; height: 75 + 16; radius: 8
                    color: chosen ? Qt.rgba(0.24, 0.68, 0.91, 0.35) : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.04))
                    border.width: chosen ? 2 : 0; border.color: Kirigami.Theme.highlightColor
                    Image { x: 4; y: 4; width: 112; height: 70; fillMode: Image.PreserveAspectCrop; asynchronous: true; source: "file://" + modelData.thumb }
                    QQC2.Label { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 1
                        text: modelData.name; font.pointSize: Kirigami.Theme.smallFont.pointSize; elide: Text.ElideRight; width: parent.width - 8; horizontalAlignment: Text.AlignHCenter }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: s.chooseFile(modelData.path) }
                }
            }
        }
        QQC2.Button { visible: s.wallpapers.length > 12; flat: true
            text: s.showAll ? "Mostrar menos" : "Mostrar todos (" + s.wallpapers.length + ")"; onClicked: s.showAll = !s.showAll }
    }

    // ---- video ----
    RowLayout {
        Kirigami.FormData.label: "Vídeo:"
        visible: s.v("background") === "video"
        QQC2.Button { text: "Escolher vídeo…"; icon.name: "video-x-generic"; onClicked: videoDlg.open() }
        QQC2.Label { text: s.v("video") ? s.fileName(s.v("video")) : "nenhum escolhido"; opacity: 0.7; elide: Text.ElideMiddle; Layout.maximumWidth: Kirigami.Units.gridUnit * 12 }
    }
    QQC2.Label { Kirigami.FormData.label: ""; visible: s.v("background") === "video"; opacity: 0.6; wrapMode: Text.WordWrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        text: "Toca em loop, sem som. O vídeo é copiado para o tema; prefira arquivos leves (MP4/WebM, até ~50 MB). Use a prévia em janela para ver em movimento." }
    FileDialog {
        id: videoDlg
        title: "Escolha um vídeo para a tela de login"
        nameFilters: ["Vídeos (*.mp4 *.webm *.mkv *.mov *.m4v *.ogv)"]
        onAccepted: { s.app.set("Login", "video", decodeURIComponent(String(selectedFile).replace(/^file:\/\//, ""))); s.app.set("Login", "background", "video"); }
    }
    ValueSlider { app: s.app; group: "Login"; key: "video_speed"; from: 25; to: 200; step: 5; unit: "%"; visible: s.v("background") === "video"; Kirigami.FormData.label: "Velocidade do vídeo:" }
    ColorButton { app: s.app; group: "Login"; key: "background_color"; visible: s.v("background") === "color"; Kirigami.FormData.label: "Cor:" }
    Toggle { app: s.app; group: "Login"; key: "lock_same"; Kirigami.FormData.label: "Tela de bloqueio (Win+L):"; text: checked ? "igual a esta (vale no próximo bloqueio)" : "visual Vidro padrão" }
    Toggle { app: s.app; group: "Login"; key: "ask_password"; Kirigami.FormData.label: "Pedir senha ao ligar:"; text: checked ? "sim (login automático desligado)" : "não (entra direto)" }
    Toggle { app: s.app; group: "Login"; key: "blur"; visible: s.v("background") !== "color"; Kirigami.FormData.label: "Desfocar:"; text: checked ? "sim" : "imagem nítida" }
    ValueSlider { app: s.app; group: "Login"; key: "blur_strength"; from: 4; to: 60; visible: s.v("background") !== "color"; enabled: s.v("blur") === "true"; Kirigami.FormData.label: "Força do desfoque:" }
    ValueSlider { app: s.app; group: "Login"; key: "dim"; from: 0; to: 90; unit: "%"; Kirigami.FormData.label: "Escurecer:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Relógio" }
    Toggle { app: s.app; group: "Login"; key: "show_clock"; Kirigami.FormData.label: "Relógio:"; text: checked ? "mostrar" : "esconder" }
    Choice { app: s.app; group: "Login"; key: "clock_format"; Kirigami.FormData.label: "Formato:"
        options: [ { text: "24 horas", value: "24h" }, { text: "12 horas (AM/PM)", value: "12h" } ] }
    Toggle { app: s.app; group: "Login"; key: "clock_seconds"; Kirigami.FormData.label: "Segundos:"; text: checked ? "sim" : "não" }
    ValueSlider { app: s.app; group: "Login"; key: "clock_size"; from: 40; to: 180; unit: "%"; Kirigami.FormData.label: "Tamanho:" }
    Choice { app: s.app; group: "Login"; key: "clock_weight"; Kirigami.FormData.label: "Espessura da letra:"
        options: [ { text: "Bem fina", value: "ExtraLight" }, { text: "Fina", value: "Light" }, { text: "Normal", value: "Normal" }, { text: "Semi-negrito", value: "DemiBold" }, { text: "Negrito", value: "Bold" } ] }
    Toggle { app: s.app; group: "Login"; key: "show_date"; Kirigami.FormData.label: "Data:"; text: checked ? "mostrar" : "esconder" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Senha e avatar" }
    Choice { app: s.app; group: "Login"; key: "layout"; Kirigami.FormData.label: "Posição:"
        options: [ { text: "Centro", value: "center" }, { text: "Esquerda", value: "left" } ] }
    ColorButton { app: s.app; group: "Login"; key: "accent"; Kirigami.FormData.label: "Cor de destaque:" }
    ValueSlider { app: s.app; group: "Login"; key: "glass"; from: 0; to: 40; unit: "%"; Kirigami.FormData.label: "Vidro dos campos:" }
    Toggle { app: s.app; group: "Login"; key: "avatar"; Kirigami.FormData.label: "Foto do usuário:"; text: checked ? "mostrar" : "esconder" }
    Choice { app: s.app; group: "Login"; key: "avatar_shape"; enabled: s.v("avatar") === "true"; Kirigami.FormData.label: "Forma da foto:"
        options: [ { text: "Círculo", value: "circle" }, { text: "Quadrado arredondado", value: "square" } ] }
    TextSetting { app: s.app; group: "Login"; key: "font"; Kirigami.FormData.label: "Fonte:" }
}
