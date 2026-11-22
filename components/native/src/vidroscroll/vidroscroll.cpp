// Vidro: overlay (transient) scrollbar for the Union style.
// A style plugin with the same key "Union": it loads the real Union (the system UnionWidgetsStyle.so)
// and wraps it in a QProxyStyle that:
//   * enables SH_ScrollBar_Transient → Qt draws the scrollbar ON TOP of the content (no own strip),
//     so the track is truly transparent and the content shows behind it;
//   * fades the scrollbar out when idle (optional) and back in on scroll/hover.
// Configuration: ~/.config/vidrorc [Scrollbar] enabled, overlay, autohide, delay (ms), min_opacity (% when idle).
// If anything fails it falls back to plain Union (or Breeze/Fusion).
#include <QApplication>
#include <QDir>
#include <QElapsedTimer>
#include <QEvent>
#include <QHash>
#include <QPainter>
#include <QPluginLoader>
#include <QPointer>
#include <QProxyStyle>
#include <QScrollBar>
#include <QSettings>
#include <QStyleFactory>
#include <QStyleOptionSlider>
#include <QStylePlugin>
#include <QTimer>
#include <QVariantAnimation>
#include <QLibraryInfo>

struct Config {
    bool overlay = true, autohide = true;
    int delay = 1200, minOpacity = 0;
};

static Config readConfig()
{
    Config c;
    const QString xdg = qEnvironmentVariable("XDG_CONFIG_HOME");
    QSettings s((xdg.isEmpty() ? QDir::homePath() + QStringLiteral("/.config") : xdg) + QStringLiteral("/vidrorc"), QSettings::IniFormat);
    // English names since v24; the Portuguese ones ([Barra]) are still read as a fallback
    const bool english = s.childGroups().contains(QStringLiteral("Scrollbar"));
    s.beginGroup(english ? QStringLiteral("Scrollbar") : QStringLiteral("Barra"));
    auto value = [&](const char *en, const char *pt, const QString &def) {
        return s.value(QLatin1String(english ? en : pt), def).toString().trimmed().toLower();
    };
    auto flag = [&](const char *en, const char *pt, bool def) {
        const QString v = value(en, pt, def ? QStringLiteral("true") : QStringLiteral("false"));
        return v == QLatin1String("true") || v == QLatin1String("1");
    };
    c.overlay = flag("enabled", "ativo", true) && flag("overlay", "sobreposta", true);
    c.autohide = flag("autohide", "some", true);
    c.delay = qBound(200, value("delay", "espera", QStringLiteral("1200")).toInt(), 10000);
    c.minOpacity = qBound(0, value("min_opacity", "minima", QStringLiteral("0")).toInt(), 100);
    return c;
}

class VidroScrollStyle : public QProxyStyle
{
public:
    VidroScrollStyle(QStyle *base, const Config &c) : QProxyStyle(base), m_cfg(c) { m_filter.s = this; }

    int styleHint(StyleHint h, const QStyleOption *o, const QWidget *w, QStyleHintReturn *r) const override
    {
        if (h == SH_ScrollBar_Transient)
            return m_cfg.overlay ? 1 : QProxyStyle::styleHint(h, o, w, r);
        return QProxyStyle::styleHint(h, o, w, r);
    }

    int pixelMetric(PixelMetric m, const QStyleOption *o, const QWidget *w) const override
    {
        // overlay scrollbar: the content takes the full width and the bar sits on top (like macOS)
        if (m == PM_ScrollView_ScrollBarOverlap && m_cfg.overlay)
            return QProxyStyle::pixelMetric(PM_ScrollBarExtent, o, w);
        return QProxyStyle::pixelMetric(m, o, w);
    }

    void polish(QWidget *w) override
    {
        QProxyStyle::polish(w);
        if (!m_cfg.overlay || !m_cfg.autohide) return;
        if (auto *sb = qobject_cast<QScrollBar *>(w)) {
            sb->installEventFilter(&m_filter);
            QObject::connect(sb, &QAbstractSlider::valueChanged, sb, [this, sb] { wake(sb); });
            QObject::connect(sb, &QAbstractSlider::rangeChanged, sb, [this, sb] { wake(sb); });
            sb->setProperty("_vidro_op", 1.0);
            schedule(sb);
        }
    }

    void drawComplexControl(ComplexControl cc, const QStyleOptionComplex *opt, QPainter *p, const QWidget *w) const override
    {
        if (cc == CC_ScrollBar && m_cfg.overlay && m_cfg.autohide && w) {
            const qreal op = w->property("_vidro_op").isValid() ? w->property("_vidro_op").toReal() : 1.0;
            if (op <= 0.001) return;
            p->save();
            p->setOpacity(p->opacity() * op);
            QProxyStyle::drawComplexControl(cc, opt, p, w);
            p->restore();
            return;
        }
        QProxyStyle::drawComplexControl(cc, opt, p, w);
    }

private:
    class Filter : public QObject {
    public:
        VidroScrollStyle *s = nullptr;
        bool eventFilter(QObject *o, QEvent *e) override {
            auto *sb = qobject_cast<QScrollBar *>(o);
            if (sb && (e->type() == QEvent::Enter || e->type() == QEvent::MouseButtonPress || e->type() == QEvent::Wheel || e->type() == QEvent::Show)) s->wake(sb);
            if (sb && e->type() == QEvent::Leave) s->schedule(sb);
            return false;
        }
    };
    friend class Filter;
    mutable Filter m_filter;

    void animateTo(QScrollBar *sb, qreal target, int ms) const
    {
        auto *anim = sb->findChild<QVariantAnimation *>(QStringLiteral("_vidro_anim"));
        if (!anim) {
            anim = new QVariantAnimation(sb);
            anim->setObjectName(QStringLiteral("_vidro_anim"));
            QObject::connect(anim, &QVariantAnimation::valueChanged, sb, [sb](const QVariant &v) { sb->setProperty("_vidro_op", v); sb->update(); });
        }
        anim->stop();
        anim->setStartValue(sb->property("_vidro_op").isValid() ? sb->property("_vidro_op").toReal() : 1.0);
        anim->setEndValue(target);
        anim->setDuration(ms);
        anim->setEasingCurve(QEasingCurve::InOutCubic);
        anim->start();
    }
    void wake(QScrollBar *sb) const
    {
        animateTo(sb, 1.0, 120);
        schedule(sb);
    }
    void schedule(QScrollBar *sb) const
    {
        auto *t = sb->findChild<QTimer *>(QStringLiteral("_vidro_timer"));
        if (!t) {
            t = new QTimer(sb);
            t->setObjectName(QStringLiteral("_vidro_timer"));
            t->setSingleShot(true);
            QObject::connect(t, &QTimer::timeout, sb, [this, sb] {
                if (sb->underMouse() || sb->isSliderDown()) { schedule(sb); return; }
                animateTo(sb, m_cfg.minOpacity / 100.0, 420);
            });
        }
        t->start(m_cfg.delay);
    }
    Config m_cfg;
};

class VidroScrollPlugin : public QStylePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QStyleFactoryInterface_iid FILE "vidroscroll.json")
public:
    QStyle *create(const QString &key) override
    {
        if (key.compare(QLatin1String("union"), Qt::CaseInsensitive) != 0) return nullptr;
        QStyle *base = nullptr;
        const QString real = QLibraryInfo::path(QLibraryInfo::PluginsPath) + QStringLiteral("/styles/UnionWidgetsStyle.so");
        QPluginLoader ld(real);
        if (auto *pl = qobject_cast<QStylePlugin *>(ld.instance())) base = pl->create(QStringLiteral("Union"));
        if (!base) base = QStyleFactory::create(QStringLiteral("Breeze"));
        if (!base) return nullptr;
        const Config c = readConfig();
        if (!c.overlay) return base;  // off: plain Union
        return new VidroScrollStyle(base, c);
    }
};
#include "vidroscroll.moc"
