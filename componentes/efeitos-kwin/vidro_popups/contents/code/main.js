// Baseado em fadingpopups (KWin, GPL-2.0-or-later) - fade+escala suaves para menus/pop-ups
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

var fadingPopupsEffect = {
    // Vidro: duração (ms), escala inicial (%) e deslize (px) vêm do kwinrc [Effect-vidro_popups]
    // (Configurações do Vidro → Menus). Escala 100 e deslize 0 = só fade.
    loadConfig: function () {
        fadingPopupsEffect.fadeInDuration = animationTime(effect.readConfig("Entrada", 150));
        fadingPopupsEffect.fadeOutDuration = animationTime(effect.readConfig("Saida", 110));
        fadingPopupsEffect.scale = Math.max(0.7, Math.min(1, effect.readConfig("Escala", 97) / 100));
        fadingPopupsEffect.slide = Math.max(0, Math.min(40, effect.readConfig("Deslize", 6)));
    },
    extra: function (window, opening) {
        var a = [];
        var s = fadingPopupsEffect.scale, d = fadingPopupsEffect.slide;
        if (s < 0.999) {
            a.push({ type: Effect.Scale, curve: opening ? QEasingCurve.OutCubic : QEasingCurve.InCubic,
                     from: opening ? { value1: s, value2: s } : { value1: 1, value2: 1 },
                     to: opening ? { value1: 1, value2: 1 } : { value1: s, value2: s } });
        }
        if (d > 0) {
            // tooltips e menus descem levemente até o lugar; popups do painel sobem a partir dele
            var g = window.frameGeometry || window.geometry;
            var area = effects.virtualScreenGeometry;
            var dy = (g && area && g.y + g.height / 2 > area.y + area.height / 2) ? d : -d;
            a.push({ type: Effect.Translation, curve: opening ? QEasingCurve.OutCubic : QEasingCurve.InCubic,
                     from: opening ? { value1: 0, value2: dy } : { value1: 0, value2: 0 },
                     to: opening ? { value1: 0, value2: 0 } : { value1: 0, value2: dy * 0.6 } });
        }
        return a;
    },
    slotWindowAdded: function (window) {
        if (effects.hasActiveFullScreenEffect) {
            return;
        }
        if (!isPopupWindow(window)) {
            return;
        }
        if (!window.visible) {
            return;
        }
        if (!effect.grab(window, Effect.WindowAddedGrabRole)) {
            return;
        }
        window.fadeInAnimation = animate({
            window: window,
            duration: fadingPopupsEffect.fadeInDuration,
            animations: [
                { type: Effect.Opacity, curve: QEasingCurve.OutCubic, from: 0.0, to: 1.0 }
            ].concat(fadingPopupsEffect.extra(window, true))
        });
    },
    slotWindowClosed: function (window) {
        if (effects.hasActiveFullScreenEffect) {
            return;
        }
        if (!isPopupWindow(window)) {
            return;
        }
        if (!window.visible || window.skipsCloseAnimation) {
            return;
        }
        if (!effect.grab(window, Effect.WindowClosedGrabRole)) {
            return;
        }
        window.fadeOutAnimation = animate({
            window: window,
            duration: fadingPopupsEffect.fadeOutDuration,
            animations: [
                { type: Effect.Opacity, curve: QEasingCurve.InCubic, from: 1.0, to: 0.0 }
            ].concat(fadingPopupsEffect.extra(window, false))
        });
    },
    slotWindowDataChanged: function (window, role) {
        if (role == Effect.WindowAddedGrabRole) {
            if (window.fadeInAnimation && effect.isGrabbed(window, role)) {
                cancel(window.fadeInAnimation);
                delete window.fadeInAnimation;
            }
        } else if (role == Effect.WindowClosedGrabRole) {
            if (window.fadeOutAnimation && effect.isGrabbed(window, role)) {
                cancel(window.fadeOutAnimation);
                delete window.fadeOutAnimation;
            }
        }
    },
    init: function () {
        fadingPopupsEffect.loadConfig();

        effect.configChanged.connect(fadingPopupsEffect.loadConfig);
        effects.windowAdded.connect(fadingPopupsEffect.slotWindowAdded);
        effects.windowClosed.connect(fadingPopupsEffect.slotWindowClosed);
        effects.windowDataChanged.connect(fadingPopupsEffect.slotWindowDataChanged);
    }
};

fadingPopupsEffect.init();
