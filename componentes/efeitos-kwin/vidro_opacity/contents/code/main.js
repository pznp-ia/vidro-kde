"use strict";
// Level 0..100 (kwinrc [Effect-vidro_opacity] Level). 0 = tudo opaco.
// 100 = janela ativa 75% (apps KDE), inativas 60%.
const EXCLUDE = /^(org\.kde\.(haruna|kdenlive|gwenview|okular|plasmawindowed))$|plasmawindowed|steam_app_|gamescope|^steam$|mpv|vlc|obs/i;  // plasmawindowed = Configurações do Vidro (sempre opaca para ler)
const ACTIVE_RE = /^org\.kde\.\w+$|^(konsole|dolphin)$/i;

const vidroOpacity = {
    level: 100,
    duration: 260,
    load() {
        this.level = Math.max(0, Math.min(100, effect.readConfig("Level", 100)));
    },
    eligible(w) {
        return w && w.managed && (w.normalWindow || w.dialog) && !w.deleted
            && !w.desktopWindow && !w.dock && !w.popupWindow && !w.specialWindow;
    },
    target(w) {
        if (!this.eligible(w) || w.fullScreen || EXCLUDE.test(w.windowClass)) return 1.0;
        const cls = (w.windowClass || "").split(" ").pop();
        if (w === effects.activeWindow) {
            return ACTIVE_RE.test(cls) ? 1.0 - 0.25 * this.level / 100 : 1.0;
        }
        return 1.0 - 0.40 * this.level / 100;
    },
    update(w, dur) {
        try { if (!w || w.deleted) return; } catch (e) { return; }
        // janela minimizada/oculta: solta a animação para o KWin parar de desenhá-la
        if (w.minimized || !w.visible) { this.release(w); return; }
        const t = this.target(w);
        if (w.vidroOpAnim !== undefined) {
            if (w.vidroOpTarget === t) return;
            if (retarget(w.vidroOpAnim, t, dur)) { w.vidroOpTarget = t; return; }
            cancel(w.vidroOpAnim); delete w.vidroOpAnim;
        }
        if (t >= 0.999 && w.vidroOpTarget === undefined) return; // nada a fazer
        const from = (w.vidroOpTarget !== undefined) ? w.vidroOpTarget : 1.0;
        w.vidroOpAnim = set({
            window: w,
            duration: dur,
            keepAlive: false,
            animations: [{ type: Effect.Opacity, from: from, to: t, curve: QEasingCurve.InOutSine }]
        });
        w.vidroOpTarget = t;
    },
    release(w) {
        if (w.vidroOpAnim !== undefined) { try { cancel(w.vidroOpAnim); } catch (e) {} }
        delete w.vidroOpAnim; delete w.vidroOpTarget;
    },
    updateAll(dur) {
        for (const w of effects.stackingOrder) {
            try { this.update(w, dur); } catch (e) { /* janela fechando: ignora */ }
        }
    },
    add(w) {
        w.windowFullScreenChanged && w.windowFullScreenChanged.connect(() => this.update(w, this.duration));
        w.minimizedChanged && w.minimizedChanged.connect(() => {
            if (w.minimized) this.release(w); else this.update(w, this.duration);
        });
        this.update(w, this.duration);
    },
    init() {
        this.load();
        effect.configChanged.connect(() => { this.load(); this.updateAll(400); });
        effects.windowActivated.connect(() => this.updateAll(this.duration));
        effects.windowAdded.connect((w) => this.add(w));
        effects.windowClosed.connect((w) => { try { if (w.vidroOpAnim !== undefined) { cancel(w.vidroOpAnim); delete w.vidroOpAnim; } } catch (e) {} });
        for (const w of effects.stackingOrder) { try { this.add(w); } catch (e) {} }
    }
};
vidroOpacity.init();
