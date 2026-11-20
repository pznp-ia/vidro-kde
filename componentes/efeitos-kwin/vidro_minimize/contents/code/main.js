"use strict";
// Minimizar (Vidro v14): a janela viaja até o ícone dela na barra de tarefas.
// Movimento e escala usam a MESMA curva → o centro anda em linha reta e o retângulo
// encolhe proporcionalmente até ficar exatamente do tamanho do ícone, em cima dele.
// Opacidade fica cheia até o fim da viagem (só some ao "entrar" no ícone).
// Sem WindowForceBlurRole: ligar/desligar o blur causava um "pisca" no início/fim.
const vidroMin = {
    load() { this.duration = animationTime(360); },
    geo(w) { return w.frameGeometry || w.geometry; },
    anims(w, toIcon) {
        const r = this.geo(w), ic = w.iconGeometry;
        const hasIcon = ic && ic.width > 0 && ic.height > 0;
        let s, tx, ty;
        if (hasIcon) {
            s = Math.min(0.5, Math.max(0.02, Math.max(ic.width / r.width, ic.height / r.height)));
            tx = (ic.x + ic.width / 2) - (r.x + r.width / 2);
            ty = (ic.y + ic.height / 2) - (r.y + r.height / 2);
        } else {
            s = 0.6; tx = 0; ty = r.height * 0.12;
        }
        const big = { scale: { value1: 1, value2: 1 }, move: { value1: 0, value2: 0 }, op: 1 };
        const small = { scale: { value1: s, value2: s }, move: { value1: tx, value2: ty }, op: 0 };
        const a = toIcon ? big : small, b = toIcon ? small : big;
        const cGeo = QEasingCurve.InOutCubic;                       // igual p/ escala e movimento
        const cOp  = toIcon ? QEasingCurve.InExpo : QEasingCurve.OutExpo; // some só no final
        return [
            { type: Effect.Scale, from: a.scale, to: b.scale, curve: cGeo },
            { type: Effect.Translation, from: a.move, to: b.move, curve: cGeo },
            { type: Effect.Opacity, from: a.op, to: b.op, curve: cOp }
        ];
    },
    run(w, minimizing) {
        if (effects.hasActiveFullScreenEffect) return;
        const mine = minimizing ? "vMin" : "vUnmin", other = minimizing ? "vUnmin" : "vMin";
        if (w[other]) {
            if (redirect(w[other], Effect.Backward)) return;
            cancel(w[other]); delete w[other];
        }
        if (w[mine]) { if (redirect(w[mine], Effect.Forward)) return; cancel(w[mine]); }
        w[mine] = animate({ window: w, duration: this.duration, keepAlive: false, animations: this.anims(w, minimizing) });
    },
    add(w) { w.minimizedChanged.connect(() => vidroMin.run(w, w.minimized)); },
    init() {
        this.load();
        effect.configChanged.connect(() => this.load());
        effect.animationEnded.connect((w) => { delete w.vMin; delete w.vUnmin; });
        effects.windowAdded.connect((w) => this.add(w));
        for (const w of effects.stackingOrder) this.add(w);
    }
};
vidroMin.init();
