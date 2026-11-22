"use strict";
// Vidro: window open/close animations.
// Styles (kwinrc [Effect-vidro_windows] OpenStyle / CloseStyle):
//   fade  — opacity only
//   scale — grows from 92 % (closing shrinks to 92 %), like macOS
//   zoom  — grows from 60 % (closing shrinks to 60 %), more dramatic
//   glide — slides 40 px up into place (closing drops 40 px)
//   pop   — grows from 85 % with a small overshoot (spring curve)
//   none  — no animation
// Curve: smooth | snappy | spring. Durations follow KDE's global animation speed (animationTime).
// Window filtering follows KWin's own "scale" effect.
const blacklist = {
    "ksmserver ksmserver": [], "ksmserver-logout-greeter ksmserver-logout-greeter": [],
    "ksplashqml ksplashqml": [], "spectacle org.kde.spectacle": ["region-editor"],
};

function curves(name, opening) {
    if (name === "snappy") return opening ? QEasingCurve.OutExpo : QEasingCurve.InExpo;
    if (name === "spring") return opening ? QEasingCurve.OutBack : QEasingCurve.InBack;
    return opening ? QEasingCurve.OutCubic : QEasingCurve.InCubic;
}

class VidroWindows {
    constructor() {
        effect.configChanged.connect(() => this.loadConfig());
        effect.animationEnded.connect((w) => this.cleanup(w));
        effects.windowAdded.connect((w) => this.opened(w));
        effects.windowClosed.connect((w) => this.closed(w));
        effects.windowDataChanged.connect((w, role) => this.dataChanged(w, role));
        this.loadConfig();
    }
    loadConfig() {
        this.openStyle = effect.readConfig("OpenStyle", "scale");
        this.closeStyle = effect.readConfig("CloseStyle", "scale");
        this.openMs = animationTime(effect.readConfig("OpenMs", 220));
        this.closeMs = animationTime(effect.readConfig("CloseMs", 180));
        this.curve = effect.readConfig("Curve", "smooth");
    }
    static wanted(w) {
        if (w.windowClass === "plasmashell plasmashell" || w.windowClass === "plasmashell org.kde.plasmashell")
            return w.hasDecoration;
        const tags = blacklist[w.windowClass];
        if (tags && (tags.length === 0 || tags.includes(w.tag))) return false;
        if (w.hasDecoration) return true;
        if (w.popupWindow || w.lockScreen || w.outline || !w.managed) return false;
        return w.normalWindow || w.dialog;
    }
    // [scale from/to, y offset, curve name override]
    shape(style) {
        switch (style) {
        case "fade": return { scale: 1, dy: 0 };
        case "zoom": return { scale: 0.6, dy: 0 };
        case "glide": return { scale: 1, dy: 40 };
        case "pop": return { scale: 0.85, dy: 0, curve: "spring" };
        default: return { scale: 0.92, dy: 0 };   // scale
        }
    }
    animations(style, opening) {
        const s = this.shape(style);
        const list = [{ type: Effect.Opacity, from: opening ? 0 : 1, to: opening ? 1 : 0,
                        curve: opening ? QEasingCurve.OutCubic : QEasingCurve.InCubic }];
        const c = curves(s.curve || this.curve, opening);
        if (s.scale !== 1)
            list.push(opening ? { type: Effect.Scale, from: s.scale, to: 1, curve: c }
                              : { type: Effect.Scale, from: 1, to: s.scale, curve: c });
        if (s.dy !== 0)
            list.push(opening ? { type: Effect.Translation, from: { value1: 0, value2: s.dy }, to: { value1: 0, value2: 0 }, curve: c }
                              : { type: Effect.Translation, from: { value1: 0, value2: 0 }, to: { value1: 0, value2: s.dy }, curve: c });
        return list;
    }
    opened(w) {
        if (this.openStyle === "none" || effects.hasActiveFullScreenEffect || !VidroWindows.wanted(w) || !w.visible) return;
        if (effect.isGrabbed(w, Effect.WindowAddedGrabRole)) return;
        w.setData(Effect.WindowForceBlurRole, true);
        w.vidroOpen = animate({ window: w, duration: this.openMs, animations: this.animations(this.openStyle, true) });
    }
    closed(w) {
        if (this.closeStyle === "none" || effects.hasActiveFullScreenEffect || !VidroWindows.wanted(w) || !w.visible || w.skipsCloseAnimation) return;
        if (effect.isGrabbed(w, Effect.WindowClosedGrabRole)) return;
        if (w.vidroOpen) { cancel(w.vidroOpen); delete w.vidroOpen; }
        w.setData(Effect.WindowForceBlurRole, true);
        w.vidroClose = animate({ window: w, duration: this.closeMs, animations: this.animations(this.closeStyle, false) });
    }
    dataChanged(w, role) {
        // another effect grabbed the window: stop ours
        if (role === Effect.WindowAddedGrabRole && w.vidroOpen && effect.isGrabbed(w, role)) { cancel(w.vidroOpen); this.cleanup(w); }
        if (role === Effect.WindowClosedGrabRole && w.vidroClose && effect.isGrabbed(w, role)) { cancel(w.vidroClose); this.cleanup(w); }
    }
    cleanup(w) {
        w.setData(Effect.WindowForceBlurRole, null);
        delete w.vidroOpen; delete w.vidroClose;
    }
}
new VidroWindows();
