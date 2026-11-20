"use strict";
// Maximizar/restaurar (Vidro v14): morph contínuo só de geometria.
// Antes havia CrossFadePrevious (instantâneo da janela antiga por cima da nova) +
// blur forçado ligado/desligado: a barra de título aparecia duplicada em tamanhos
// diferentes e o blur "piscava" no início/fim. Agora o conteúdo atual é esticado do
// retângulo antigo até o novo numa única curva suave, sem segunda imagem.
class VidroMaximize {
    constructor() {
        effect.configChanged.connect(() => this.loadConfig());
        effects.windowAdded.connect((w) => this.manage(w));
        for (const w of effects.stackingOrder) this.manage(w);
        this.loadConfig();
    }
    loadConfig() { this.duration = animationTime(280); }
    geo(w) { return w.frameGeometry || w.geometry; }
    manage(w) {
        w.windowMaximizedStateAboutToChange.connect(() => this.about(w));
        w.windowMaximizedStateChanged.connect(() => this.changed(w));
        w.windowFrameGeometryChanged.connect(() => this.frame(w));
    }
    about(w) {
        if (!w.visible || effects.hasActiveFullScreenEffect) return;
        // se já estava animando, parte do retângulo atual na tela (sem salto)
        w.vOld = Object.assign({}, w.vShown || this.geo(w));
        w.vWait = true;
    }
    changed(w) { if (w.vWait && this.geo(w).width !== w.vOld.width) this.start(w); }
    frame(w) { if (w.vWait && w.vOld) this.start(w); }
    start(w) {
        w.vWait = false;
        const o = w.vOld, n = Object.assign({}, this.geo(w));
        delete w.vOld;
        if (w.vAnimGeo) { cancel(w.vAnimGeo); delete w.vAnimGeo; }
        if (o.width === n.width && o.height === n.height && o.x === n.x && o.y === n.y) return;
        w.vShown = null;
        w.vAnimGeo = animate({
            window: w, duration: this.duration,
            animations: [{
                type: Effect.Size, curve: QEasingCurve.OutCubic,
                from: { value1: o.width, value2: o.height }, to: { value1: n.width, value2: n.height }
            }, {
                type: Effect.Translation, curve: QEasingCurve.OutCubic,
                from: { value1: o.x - n.x - (n.width / 2 - o.width / 2), value2: o.y - n.y - (n.height / 2 - o.height / 2) },
                to: { value1: 0, value2: 0 }
            }]
        });
    }
}
new VidroMaximize();
