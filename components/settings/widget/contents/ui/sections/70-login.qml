// Section: login screen (module login.py; applying to the system asks for the admin password)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
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
    P5Support.DataSource {
        id: exec; engine: "executable"
        onNewData: (source, data) => {
            if (source.indexOf("#login-apply") >= 0) {
                s.applying = false;
                s.result = data["exit code"] === 0 ? "Pronto! A tela de login nova aparece no próximo boot."
                    : "Não foi aplicado. " + String(data["stderr"] || data["stdout"] || "").trim().split("\n").slice(-2).join(" ");
            }
            disconnectSource(source);
        }
    }
    RowLayout {
        Kirigami.FormData.label: ""
        QQC2.Button { text: "Testar (abre numa janela)"; icon.name: "view-preview"
            onClicked: s.app.run("(QT_IM_MODULE=none sddm-greeter-qt6 --test-mode --theme \"$HOME/.local/share/vidro/login/theme\" >/dev/null 2>&1 &) #login-testar" + Date.now()) }
        QQC2.Button { text: "Aplicar na tela de login"; icon.name: "dialog-ok-apply"; highlighted: true; enabled: !s.applying
            onClicked: { s.applying = true; s.result = "Esperando a senha de administrador…"; exec.connectSource("pkexec /bin/bash \"$HOME/.local/share/vidro/login/apply.sh\" #login-apply" + Date.now()) } }
    }
    QQC2.Label { Kirigami.FormData.label: ""; visible: s.result !== ""; text: s.result; wrapMode: Text.WordWrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 24; opacity: 0.8 }
    QQC2.Label { Kirigami.FormData.label: ""; text: "No teste, feche com Alt+F4."; opacity: 0.55 }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Fundo" }
    Choice { app: s.app; group: "Login"; key: "background"; Kirigami.FormData.label: "Imagem:"
        options: [ { text: "Honeywave (do KDE)", value: "honeywave" }, { text: "Meu papel de parede atual", value: "wallpaper" },
                  { text: "Outra imagem…", value: "file" }, { text: "Cor lisa", value: "color" } ] }
    TextSetting { app: s.app; group: "Login"; key: "file"; visible: s.v("background") === "file"; placeholderText: "/caminho/da/imagem.jpg"; Kirigami.FormData.label: "Arquivo:" }
    ColorButton { app: s.app; group: "Login"; key: "background_color"; visible: s.v("background") === "color"; Kirigami.FormData.label: "Cor:" }
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
