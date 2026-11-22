"use strict";
// Vidro: minimize / restore animation. kwinrc [Effect-vidro_minimize]:
//   Style = icon   — the window travels to its taskbar icon and shrinks to the icon's size
//                    (scale and movement share one curve: the center moves in a straight line)
//         | scale  — shrinks in place and fades
//         | fade   — fades out in place
//         | drop   — sinks towards the bottom of the screen while fading
//         | none
//   Ms (duration), Curve = smooth | snappy | spring
// No WindowForceBlurRole: toggling blur on/off made the window blink at start/end.
function geoCurve(name) {
    if (name === "snappy") return QEasingCurve.InOutExpo;
    if (name === "spring") return QEasingCurve.InOutBack;
    return QEasingCurve.InOutCubic;
}
const vidroMinimize = {
    load() {
        this.style = effect.readConfig("Style", "icon");
        this.duration = animationTime(effect.readConfig("Ms", 360));
        this.curve = effect.readConfig("Curve", "smooth");
    },
    geo(w) { return w.frameGeometry || w.geometry; },
    // target state of a minimized window: scale, translation, opacity
    target(w) {
        const r = this.geo(w), icon = w.iconGeometry;
        const hasIcon = icon && icon.width > 0 && icon.height > 0;
        switch (this.style) {
        case "scale": return { s: 0.7, tx: 0, ty: 0 };
        case "fade": return { s: 1, tx: 0, ty: 0 };
        case "drop": return { s: 0.9, tx: 0, ty: effects.virtualScreenGeometry.height - r.y };
        default:
            if (!hasIcon) return { s: 0.6, tx: 0, ty: r.height * 0.12 };
            return {
                s: Math.min(0.5, Math.max(0.02, Math.max(icon.width / r.width, icon.height / r.height))),
                tx: (icon.x + icon.width / 2) - (r.x + r.width / 2),
                ty: (icon.y + icon.height / 2) - (r.y + r.height / 2),
            };
        }
    },
    anims(w, minimizing) {
        const t = this.target(w);
        const big = { scale: { value1: 1, value2: 1 }, move: { value1: 0, value2: 0 }, op: 1 };
        const small = { scale: { value1: t.s, value2: t.s }, move: { value1: t.tx, value2: t.ty }, op: 0 };
        const a = minimizing ? big : small, b = minimizing ? small : big;
        const c = geoCurve(this.curve);
        // icon style: fully opaque until it "enters" the icon; the others fade along
        const cOp = this.style === "icon" ? (minimizing ? QEasingCurve.InExpo : QEasingCurve.OutExpo)
                                          : (minimizing ? QEasingCurve.InCubic : QEasingCurve.OutCubic);
        const list = [{ type: Effect.Opacity, from: a.op, to: b.op, curve: cOp }];
        if (t.s !== 1) list.push({ type: Effect.Scale, from: a.scale, to: b.scale, curve: c });
        if (t.tx !== 0 || t.ty !== 0) list.push({ type: Effect.Translation, from: a.move, to: b.move, curve: c });
        return list;
    },
    run(w, minimizing) {
        if (this.style === "none" || effects.hasActiveFullScreenEffect) return;
        const mine = minimizing ? "vidroMin" : "vidroUnmin", other = minimizing ? "vidroUnmin" : "vidroMin";
        if (w[other]) {   // reversing mid-way: run the same animation backwards (no jump)
            if (redirect(w[other], Effect.Backward)) return;
            cancel(w[other]); delete w[other];
        }
        if (w[mine]) { if (redirect(w[mine], Effect.Forward)) return; cancel(w[mine]); }
        w[mine] = animate({ window: w, duration: this.duration, keepAlive: false, animations: this.anims(w, minimizing) });
    },
    add(w) { w.minimizedChanged.connect(() => vidroMinimize.run(w, w.minimized)); },
    init() {
        this.load();
        effect.configChanged.connect(() => this.load());
        effect.animationEnded.connect((w) => { delete w.vidroMin; delete w.vidroUnmin; });
        effects.windowAdded.connect((w) => this.add(w));
        for (const w of effects.stackingOrder) this.add(w);
    }
};
vidroMinimize.init();
