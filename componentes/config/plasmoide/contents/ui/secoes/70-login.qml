// Seção: tela de login (módulo login.py; aplicar no sistema pede senha de administrador)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import "../comum"
Secao {
    id: s
    titulo: "Tela de login"
    icone: "system-users"
    previa: Component { PreviaLogin { app: s.app } }
    descricao: "A tela que pede a senha ao ligar o PC (SDDM). As mudanças ficam prontas aqui; para valerem no próximo boot use \"Aplicar na tela de login\" (pede a senha de administrador)."
    function v(k) { return (app && app.cfg.Login) ? String(app.cfg.Login[k]) : "" }
    property string resultado: ""
    property bool aplicando: false
    P5Support.DataSource {
        id: exec; engine: "executable"
        onNewData: (source, data) => {
            if (source.indexOf("#login-aplicar") >= 0) {
                s.aplicando = false;
                s.resultado = data["exit code"] === 0 ? "Pronto! A tela de login nova aparece no próximo boot."
                    : "Não foi aplicado. " + String(data["stderr"] || data["stdout"] || "").trim().split("\n").slice(-2).join(" ");
            }
            disconnectSource(source);
        }
    }
    RowLayout {
        Kirigami.FormData.label: ""
        QQC2.Button { text: "Testar (abre numa janela)"; icon.name: "view-preview"
            onClicked: s.app.rodar("(QT_IM_MODULE=none sddm-greeter-qt6 --test-mode --theme \"$HOME/.local/share/vidro/login/tema\" >/dev/null 2>&1 &) #login-testar" + Date.now()) }
        QQC2.Button { text: "Aplicar na tela de login"; icon.name: "dialog-ok-apply"; highlighted: true; enabled: !s.aplicando
            onClicked: { s.aplicando = true; s.resultado = "Esperando a senha de administrador…"; exec.connectSource("pkexec /bin/bash \"$HOME/.local/share/vidro/login/aplicar.sh\" #login-aplicar" + Date.now()) } }
    }
    QQC2.Label { Kirigami.FormData.label: ""; visible: s.resultado !== ""; text: s.resultado; wrapMode: Text.WordWrap; Layout.maximumWidth: Kirigami.Units.gridUnit * 24; opacity: 0.8 }
    QQC2.Label { Kirigami.FormData.label: ""; text: "No teste, feche com Alt+F4."; opacity: 0.55 }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Fundo" }
    Escolha { app: s.app; grupo: "Login"; chave: "fundo"; Kirigami.FormData.label: "Imagem:"
        opcoes: [ { texto: "Honeywave (do KDE)", valor: "honeywave" }, { texto: "Meu papel de parede atual", valor: "papel" },
                  { texto: "Outra imagem…", valor: "arquivo" }, { texto: "Cor lisa", valor: "cor" } ] }
    Texto { app: s.app; grupo: "Login"; chave: "arquivo"; visible: s.v("fundo") === "arquivo"; placeholderText: "/caminho/da/imagem.jpg"; Kirigami.FormData.label: "Arquivo:" }
    Cor { app: s.app; grupo: "Login"; chave: "cor_fundo"; visible: s.v("fundo") === "cor"; Kirigami.FormData.label: "Cor:" }
    Chave { app: s.app; grupo: "Login"; chave: "desfoque"; visible: s.v("fundo") !== "cor"; Kirigami.FormData.label: "Desfocar:"; text: checked ? "sim" : "imagem nítida" }
    Deslizante { app: s.app; grupo: "Login"; chave: "forca"; de: 4; ate: 60; visible: s.v("fundo") !== "cor"; enabled: s.v("desfoque") === "true"; Kirigami.FormData.label: "Força do desfoque:" }
    Deslizante { app: s.app; grupo: "Login"; chave: "escurecer"; de: 0; ate: 90; unidade: "%"; Kirigami.FormData.label: "Escurecer:" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Relógio" }
    Chave { app: s.app; grupo: "Login"; chave: "mostrar_relogio"; Kirigami.FormData.label: "Relógio:"; text: checked ? "mostrar" : "esconder" }
    Escolha { app: s.app; grupo: "Login"; chave: "relogio"; Kirigami.FormData.label: "Formato:"
        opcoes: [ { texto: "24 horas", valor: "24h" }, { texto: "12 horas (AM/PM)", valor: "12h" } ] }
    Chave { app: s.app; grupo: "Login"; chave: "segundos"; Kirigami.FormData.label: "Segundos:"; text: checked ? "sim" : "não" }
    Deslizante { app: s.app; grupo: "Login"; chave: "tamanho"; de: 40; ate: 180; unidade: "%"; Kirigami.FormData.label: "Tamanho:" }
    Escolha { app: s.app; grupo: "Login"; chave: "peso"; Kirigami.FormData.label: "Espessura da letra:"
        opcoes: [ { texto: "Bem fina", valor: "ExtraLight" }, { texto: "Fina", valor: "Light" }, { texto: "Normal", valor: "Normal" }, { texto: "Semi-negrito", valor: "DemiBold" }, { texto: "Negrito", valor: "Bold" } ] }
    Chave { app: s.app; grupo: "Login"; chave: "data"; Kirigami.FormData.label: "Data:"; text: checked ? "mostrar" : "esconder" }

    Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Senha e avatar" }
    Escolha { app: s.app; grupo: "Login"; chave: "posicao"; Kirigami.FormData.label: "Posição:"
        opcoes: [ { texto: "Centro", valor: "centro" }, { texto: "Esquerda", valor: "esquerda" } ] }
    Cor { app: s.app; grupo: "Login"; chave: "destaque"; Kirigami.FormData.label: "Cor de destaque:" }
    Deslizante { app: s.app; grupo: "Login"; chave: "vidro"; de: 0; ate: 40; unidade: "%"; Kirigami.FormData.label: "Vidro dos campos:" }
    Chave { app: s.app; grupo: "Login"; chave: "avatar"; Kirigami.FormData.label: "Foto do usuário:"; text: checked ? "mostrar" : "esconder" }
    Escolha { app: s.app; grupo: "Login"; chave: "forma_avatar"; enabled: s.v("avatar") === "true"; Kirigami.FormData.label: "Forma da foto:"
        opcoes: [ { texto: "Círculo", valor: "circulo" }, { texto: "Quadrado arredondado", valor: "quadrado" } ] }
    Texto { app: s.app; grupo: "Login"; chave: "fonte"; Kirigami.FormData.label: "Fonte:" }
}
