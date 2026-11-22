// Vidro — taskbar (panel) show/hide animation, for panels that hide automatically.
// KWin emits windowHiddenChanged when an auto-hiding panel hides/shows; animations keep the
// hidden window painted until they end (AnimationEffect holds a visible ref).
// kwinrc [Effect-vidro_panel]:
//   ShowStyle / HideStyle: slide | fade | slidefade | scale | rise (slide + scale + fade) | none
//   ShowMs, HideMs; Curve: smooth | snappy | spring | linear
//   Distance (% of the panel thickness the slide travels, 10-150); Scale (% start size for scale/rise)
"use strict";

var vidroPanel = {
    load: function () {
        vidroPanel.showStyle = effect.readConfig("ShowStyle", "slide");
        vidroPanel.hideStyle = effect.readConfig("HideStyle", "slide");
        vidroPanel.showMs = animationTime(effect.readConfig("ShowMs", 260));
        vidroPanel.hideMs = animationTime(effect.readConfig("HideMs", 200));
        vidroPanel.curve = effect.readConfig("Curve", "smooth");
        vidroPanel.distance = Math.max(10, Math.min(150, effect.readConfig("Distance", 100))) / 100;
        vidroPanel.scale = Math.max(0.5, Math.min(1, effect.readConfig("Scale", 90) / 100));
    },
    curveFor: function (showing) {
        switch (vidroPanel.curve) {
        case "snappy": return showing ? QEasingCurve.OutExpo : QEasingCurve.InExpo;
        case "spring": return showing ? QEasingCurve.OutBack : QEasingCurve.InBack;
        case "linear": return QEasingCurve.Linear;
        default: return showing ? QEasingCurve.OutCubic : QEasingCurve.InCubic;
        }
    },
    // offset that pushes the panel off its screen edge
    edgeOffset: function (w) {
        var g = w.frameGeometry || w.geometry;
        var s = effects.virtualScreenGeometry;
        try { s = effects.clientArea(KWin.ScreenArea, w.screen, effects.currentDesktop); } catch (e) {}
        if (!g || !s) return { x: 0, y: g ? g.height : 40 };
        var d = vidroPanel.distance;
        var horizontal = g.width >= g.height;
        if (horizontal) {
            var bottom = g.y + g.height / 2 > s.y + s.height / 2;
            return { x: 0, y: Math.round((bottom ? 1 : -1) * (g.height + 12) * d) };
        }
        var right = g.x + g.width / 2 > s.x + s.width / 2;
        return { x: Math.round((right ? 1 : -1) * (g.width + 12) * d), y: 0 };
    },
    run: function (w, showing) {
        if (!w || !w.dock || effects.hasActiveFullScreenEffect) return;
        var style = showing ? vidroPanel.showStyle : vidroPanel.hideStyle;
        if (style === "none") return;
        if (w.vidroPanelAnim) { cancel(w.vidroPanelAnim); delete w.vidroPanelAnim; }
        var c = vidroPanel.curveFor(showing);
        var off = vidroPanel.edgeOffset(w);
        var list = [];
        var from = function (a, b) { return showing ? a : b; };
        if (style === "slide" || style === "slidefade" || style === "rise") {
            list.push({ type: Effect.Translation, curve: c,
                        from: from({ value1: off.x, value2: off.y }, { value1: 0, value2: 0 }),
                        to: from({ value1: 0, value2: 0 }, { value1: off.x, value2: off.y }) });
        }
        if (style === "fade" || style === "slidefade" || style === "scale" || style === "rise") {
            list.push({ type: Effect.Opacity, curve: showing ? QEasingCurve.OutCubic : QEasingCurve.InCubic,
                        from: from(0, 1), to: from(1, 0) });
        }
        if (style === "scale" || style === "rise") {
            var s = vidroPanel.scale;
            list.push({ type: Effect.Scale, curve: c,
                        from: from({ value1: s, value2: s }, { value1: 1, value2: 1 }),
                        to: from({ value1: 1, value2: 1 }, { value1: s, value2: s }) });
        }
        if (!list.length) return;
        w.setData(Effect.WindowForceBlurRole, true);
        w.vidroPanelAnim = animate({ window: w, duration: showing ? vidroPanel.showMs : vidroPanel.hideMs, animations: list });
    },
    watch: function (w) {
        if (!w || !w.dock || w.vidroPanelWatched) return;
        w.vidroPanelWatched = true;
        w.vidroPanelHidden = false;
        w.windowHiddenChanged.connect(function (win) {
            var x = win || w;
            // use KWin's own state when exposed, otherwise track it
            x.vidroPanelHidden = (typeof x.hidden === "boolean") ? x.hidden : !x.vidroPanelHidden;
            vidroPanel.run(x, !x.vidroPanelHidden);
        });
    },
    init: function () {
        vidroPanel.load();
        effect.configChanged.connect(vidroPanel.load);
        effect.animationEnded.connect(function (w) {
            if (!w.dock) return;
            w.setData(Effect.WindowForceBlurRole, null);
            delete w.vidroPanelAnim;
        });
        effects.windowAdded.connect(vidroPanel.watch);
        effects.stackingOrder.forEach(vidroPanel.watch);
    }
};

vidroPanel.init();
