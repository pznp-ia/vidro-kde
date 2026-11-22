"use strict";
// Vidro: "show desktop" animation. kwinrc [Effect-vidro_desktop]:
//   Style = corners — each window flies to the screen corner nearest to it (like KWin's Window Aperture)
//         | slide   — windows slide off the nearest screen edge (left/right)
//         | sink    — windows shrink a little and fade, as if sinking into the desktop
//         | fade    — windows fade out in place
//         | none
//   Ms (duration), Curve = smooth | snappy | spring
// Leaving "show desktop" plays the same animation backwards from wherever it is (no jump).
function curveOf(name) {
    if (name === "snappy") return QEasingCurve.InOutExpo;
    if (name === "spring") return QEasingCurve.InOutBack;
    return QEasingCurve.InOutCubic;
}
const vidroDesktop = {
    load() {
        this.style = effect.readConfig("Style", "corners");
        this.duration = animationTime(effect.readConfig("Ms", 320));
        this.curve = effect.readConfig("Curve", "smooth");
    },
    // offset (dx, dy) and scale for one window when the desktop is shown
    away(w, screen) {
        const g = w.frameGeometry || w.geometry;
        const cx = g.x + g.width / 2, cy = g.y + g.height / 2;
        const sx = screen.x + screen.width / 2, sy = screen.y + screen.height / 2;
        switch (this.style) {
        case "slide": {
            const left = cx < sx;
            return { dx: left ? screen.x - g.x - g.width - 20 : screen.x + screen.width - g.x + 20, dy: 0, s: 1 };
        }
        case "sink": return { dx: 0, dy: g.height * 0.04, s: 0.88 };
        case "fade": return { dx: 0, dy: 0, s: 1 };
        default: {   // corners: move so that the window's far corner sits just inside the nearest screen corner
            const right = cx >= sx, bottom = cy >= sy;
            const tx = right ? screen.x + screen.width - screen.width / 16 : screen.x + screen.width / 16 - g.width;
            const ty = bottom ? screen.y + screen.height - screen.height / 16 : screen.y + screen.height / 16 - g.height;
            return { dx: tx - g.x, dy: ty - g.y, s: 1 };
        }
        }
    },
    changed(showing) {
        this.showing = showing;
        if (this.style === "none") return;
        const screen = effects.virtualScreenGeometry;
        const c = curveOf(this.curve);
        for (const w of effects.stackingOrder) {
            if (showing) {
                if (!w.hiddenByShowDesktop || !w.visible || w.dock) continue;
                const a = this.away(w, screen);
                if (w.vidroDesk) cancel(w.vidroDesk);
                const anims = [{ type: Effect.Opacity, to: 0, curve: c }];
                if (a.dx || a.dy) anims.push({ type: Effect.Translation, to: { value1: a.dx, value2: a.dy }, curve: c });
                if (a.s !== 1) anims.push({ type: Effect.Scale, to: a.s, curve: c });
                w.vidroDesk = set({ window: w, duration: this.duration, animations: anims });
            } else if (w.vidroDesk) {
                if (!w.visible) { cancel(w.vidroDesk); delete w.vidroDesk; continue; }
                if (!redirect(w.vidroDesk, Effect.Backward)) { cancel(w.vidroDesk); delete w.vidroDesk; }
            }
        }
    },
    ended(w) {
        // after the "back" animation finishes, drop the kept state
        if (!this.showing && w.vidroDesk) { cancel(w.vidroDesk); delete w.vidroDesk; }
    },
    init() {
        this.showing = false;
        this.load();
        effect.configChanged.connect(() => this.load());
        effects.showingDesktopChanged.connect((showing) => this.changed(showing));
        effect.animationEnded.connect((w) => this.ended(w));
    }
};
vidroDesktop.init();
