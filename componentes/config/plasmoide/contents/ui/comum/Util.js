.pragma library
// ajudantes dos exemplos
function v(app, g, k, padrao) { return (app && app.cfg && app.cfg[g] && app.cfg[g][k] !== undefined) ? app.cfg[g][k] : padrao }
function n(app, g, k, padrao) { const x = Number(v(app, g, k, padrao)); return isNaN(x) ? padrao : x }
function b(app, g, k, padrao) { return String(v(app, g, k, padrao ? "true" : "false")).toLowerCase() === "true" }
function cor(hex, a) { const c = Qt.color(hex); return Qt.rgba(c.r, c.g, c.b, a === undefined ? 1 : a) }
function mix(c1, c2, t) { const a = Qt.color(c1), b2 = Qt.color(c2); return Qt.rgba(a.r + (b2.r - a.r) * t, a.g + (b2.g - a.g) * t, a.b + (b2.b - a.b) * t, 1) }
