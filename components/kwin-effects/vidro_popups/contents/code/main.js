// Based on fadingpopups (KWin, GPL-2.0-or-later) - smooth fade + scale for menus and popups
/*
    KWin - the KDE window manager
    This file is part of the KDE project.

    SPDX-FileCopyrightText: 2018 Vlad Zahorodnii <vlad.zahorodnii@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

"use strict";

var blacklist = [
    // ignore black background behind lockscreen
    "ksmserver ksmserver",
    // The logout screen has to be animated only by the logout effect.
    "ksmserver-logout-greeter ksmserver-logout-greeter",
    // The lockscreen isn't a popup window
    "kscreenlocker_greet kscreenlocker_greet",
    // KDE Plasma splash screen has to be animated only by the login effect.
    "ksplashqml ksplashqml",
];

function isPopupWindow(window) {
    // If the window is blacklisted, don't animate it.
    if (blacklist.indexOf(window.windowClass) != -1) {
        return false;
    }

    // Animate combo box popups, tooltips, popup menus, etc.
    if (window.popupWindow) {
        return true;
    }

    // Maybe the outline deserves its own effect.
    if (window.outline) {
        return true;
    }

    // Override-redirect windows are usually used for user interface
    // concepts that are expected to be animated by this effect, e.g.
    // popups that contain window thumbnails on X11, etc.
    if (!window.managed) {
        // Some utility windows can look like popup windows (e.g. the
        // address bar dropdown in Firefox), but we don't want to fade
        // them because the fade effect didn't do that.
        if (window.utility) {
            return false;
        }

        return true;
    }

    if (window.splash || window.toolbar || window.onScreenDisplay || window.appletPopup) {
        return true;
    }

    return false;
}

// Vidro: two families with their own style (kwinrc [Effect-vidro_popups]):
//   PanelStyle — launcher, clock, system tray and other panel popups:
//                slide (rises from the panel, fully opaque — no see-through phase) | fade | scale | none
//   MenuStyle  — right-click menus, combo boxes and tooltips:
//                fadescale (short fade + slight grow) | fade | slide | none
//   OpenMs, CloseMs, Scale (%), Slide (px)
// While animating, blur is forced on so it moves together with the popup (no blur "catching up").
function isPanelPopup(w) {
    return (w.windowClass || "").indexOf("plasmashell") >= 0 && !w.tooltip && !w.popupMenu && !w.dropdownMenu;
}
var vidroPopups = {
    loadConfig: function () {
        vidroPopups.openMs = animationTime(effect.readConfig("OpenMs", 150));
        vidroPopups.closeMs = animationTime(effect.readConfig("CloseMs", 110));
        vidroPopups.scale = Math.max(0.7, Math.min(1, effect.readConfig("Scale", 97) / 100));
        vidroPopups.slide = Math.max(0, Math.min(60, effect.readConfig("Slide", 6)));
        vidroPopups.panelStyle = effect.readConfig("PanelStyle", "slide");
        vidroPopups.menuStyle = effect.readConfig("MenuStyle", "fadescale");
    },
    // direction: popups in the bottom half rise from below, the others drop from above
    offset: function (w, distance) {
        var g = w.frameGeometry || w.geometry, area = effects.virtualScreenGeometry;
        return (g && area && g.y + g.height / 2 > area.y + area.height / 2) ? distance : -distance;
    },
    animations: function (w, opening) {
        var panel = isPanelPopup(w);
        var style = panel ? vidroPopups.panelStyle : vidroPopups.menuStyle;
        var c = opening ? QEasingCurve.OutCubic : QEasingCurve.InCubic;
        var list = [];
        var fade = function () { list.push({ type: Effect.Opacity, curve: c, from: opening ? 0 : 1, to: opening ? 1 : 0 }); };
        var grow = function (s) {
            list.push({ type: Effect.Scale, curve: c, from: opening ? { value1: s, value2: s } : { value1: 1, value2: 1 },
                        to: opening ? { value1: 1, value2: 1 } : { value1: s, value2: s } });
        };
        var move = function (dy) {
            list.push({ type: Effect.Translation, curve: opening ? QEasingCurve.OutCubic : QEasingCurve.InCubic,
                        from: opening ? { value1: 0, value2: dy } : { value1: 0, value2: 0 },
                        to: opening ? { value1: 0, value2: 0 } : { value1: 0, value2: dy } });
        };
        if (style === "none") return null;
        if (style === "slide") {
            var g = w.frameGeometry || w.geometry;
            // panel popups travel a bit more (a fifth of their height, at least the "Slide" setting)
            var dist = panel ? Math.max(vidroPopups.slide, Math.round((g ? g.height : 200) * 0.2)) : Math.max(4, vidroPopups.slide);
            move(vidroPopups.offset(w, dist));
            if (!opening) fade();   // closing: slide away while fading, so it never sits over other content
        } else if (style === "scale") {
            grow(vidroPopups.scale); fade();
        } else if (style === "fade") {
            fade();
        } else {   // fadescale
            fade();
            if (vidroPopups.scale < 0.999) grow(vidroPopups.scale);
            if (vidroPopups.slide > 0) move(vidroPopups.offset(w, vidroPopups.slide) * (opening ? 1 : 0.6));
        }
        return list;
    },
    run: function (w, opening) {
        if (effects.hasActiveFullScreenEffect || !isPopupWindow(w) || !w.visible) return;
        if (!opening && w.skipsCloseAnimation) return;
        var anims = vidroPopups.animations(w, opening);
        if (!anims || !anims.length) return;
        if (!effect.grab(w, opening ? Effect.WindowAddedGrabRole : Effect.WindowClosedGrabRole)) return;
        w.setData(Effect.WindowForceBlurRole, true);
        var id = animate({ window: w, duration: opening ? vidroPopups.openMs : vidroPopups.closeMs, animations: anims });
        if (opening) w.vidroIn = id; else w.vidroOut = id;
    },
    dataChanged: function (w, role) {
        if (role == Effect.WindowAddedGrabRole && w.vidroIn && effect.isGrabbed(w, role)) { cancel(w.vidroIn); delete w.vidroIn; }
        if (role == Effect.WindowClosedGrabRole && w.vidroOut && effect.isGrabbed(w, role)) { cancel(w.vidroOut); delete w.vidroOut; }
    },
    init: function () {
        vidroPopups.loadConfig();
        effect.configChanged.connect(vidroPopups.loadConfig);
        effect.animationEnded.connect(function (w) { w.setData(Effect.WindowForceBlurRole, null); delete w.vidroIn; delete w.vidroOut; });
        effects.windowAdded.connect(function (w) { vidroPopups.run(w, true); });
        effects.windowClosed.connect(function (w) { vidroPopups.run(w, false); });
        effects.windowDataChanged.connect(vidroPopups.dataChanged);
    }
};

vidroPopups.init();

