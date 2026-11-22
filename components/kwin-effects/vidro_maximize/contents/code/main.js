"use strict";
// Vidro: maximize / restore animation. kwinrc [Effect-vidro_maximize]:
//   Style = morph — the current content is stretched from the old rectangle to the new one
//                   in one smooth curve, without a second image (no doubled titlebar, no blur blink)
//         | fade  — a quick opacity dip while the size changes
//         | none
//   Ms (duration), Curve = smooth | snappy | spring
function curveOf(name) {
    if (name === "snappy") return QEasingCurve.OutExpo;
    if (name === "spring") return QEasingCurve.OutBack;
    return QEasingCurve.OutCubic;
}
class VidroMaximize {
    constructor() {
        effect.configChanged.connect(() => this.loadConfig());
        effects.windowAdded.connect((w) => this.manage(w));
        for (const w of effects.stackingOrder) this.manage(w);
        this.loadConfig();
    }
    loadConfig() {
        this.style = effect.readConfig("Style", "morph");
        this.duration = animationTime(effect.readConfig("Ms", 280));
        this.curve = effect.readConfig("Curve", "smooth");
    }
    geo(w) { return w.frameGeometry || w.geometry; }
    manage(w) {
        w.windowMaximizedStateAboutToChange.connect(() => this.about(w));
        w.windowMaximizedStateChanged.connect(() => this.changed(w));
        w.windowFrameGeometryChanged.connect(() => this.frame(w));
    }
    about(w) {
        if (this.style === "none" || !w.visible || effects.hasActiveFullScreenEffect) return;
        // if it was already animating, start from the rectangle currently on screen (no jump)
        w.vidroOld = Object.assign({}, w.vidroShown || this.geo(w));
        w.vidroWait = true;
    }
    changed(w) { if (w.vidroWait && this.geo(w).width !== w.vidroOld.width) this.start(w); }
    frame(w) { if (w.vidroWait && w.vidroOld) this.start(w); }
    start(w) {
        w.vidroWait = false;
        const o = w.vidroOld, n = Object.assign({}, this.geo(w));
        delete w.vidroOld;
        if (w.vidroAnim) { cancel(w.vidroAnim); delete w.vidroAnim; }
        if (o.width === n.width && o.height === n.height && o.x === n.x && o.y === n.y) return;
        w.vidroShown = null;
        if (this.style === "fade") {
            w.vidroAnim = animate({ window: w, duration: this.duration,
                animations: [{ type: Effect.Opacity, from: 0.35, to: 1, curve: QEasingCurve.OutCubic }] });
            return;
        }
        const c = curveOf(this.curve);
        w.vidroAnim = animate({
            window: w, duration: this.duration,
            animations: [{
                type: Effect.Size, curve: c,
                from: { value1: o.width, value2: o.height }, to: { value1: n.width, value2: n.height }
            }, {
                type: Effect.Translation, curve: c,
                from: { value1: o.x - n.x - (n.width / 2 - o.width / 2), value2: o.y - n.y - (n.height / 2 - o.height / 2) },
                to: { value1: 0, value2: 0 }
            }]
        });
    }
}
new VidroMaximize();
