// Vidro — barra de rolagem sobreposta (transient) para o estilo Union.
// Plugin de estilo com a mesma chave "Union": carrega o Union verdadeiro (UnionWidgetsStyle.so do sistema)
// e o envolve num QProxyStyle que:
//   * liga SH_ScrollBar_Transient → o Qt desenha a barra POR CIMA do conteúdo (sem faixa própria),
//     então o trilho é transparente de verdade e o conteúdo aparece atrás;
//   * faz a barra sumir com fade quando parada (opcional) e reaparecer ao rolar/passar o mouse.
// Configuração: ~/.config/vidrorc [Barra] sobreposta, some, espera (ms), minima (% opacidade parada).
// Se algo falhar, usa o Union sem mudanças (ou Breeze/Fusion).
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

struct Cfg {
    bool sobreposta = true, some = true;
    int espera = 1200, minima = 0;
};

static Cfg lerCfg()
{
    Cfg c;
    const QString arq = QDir::homePath() + QStringLiteral("/.config/vidrorc");
    QSettings s(qEnvironmentVariable("XDG_CONFIG_HOME").isEmpty() ? arq : qEnvironmentVariable("XDG_CONFIG_HOME") + QStringLiteral("/vidrorc"), QSettings::IniFormat);
    s.beginGroup(QStringLiteral("Barra"));
    auto b = [&](const char *k, bool d) { const QString v = s.value(QLatin1String(k), d ? QStringLiteral("true") : QStringLiteral("false")).toString().trimmed().toLower(); return v == QLatin1String("true") || v == QLatin1String("1"); };
    const bool ativo = b("ativo", true);
    c.sobreposta = ativo && b("sobreposta", true);
    c.some = b("some", true);
    c.espera = qBound(200, s.value(QStringLiteral("espera"), 1200).toString().trimmed().toInt(), 10000);
    c.minima = qBound(0, s.value(QStringLiteral("minima"), 0).toString().trimmed().toInt(), 100);
    return c;
}

class VidroScrollStyle : public QProxyStyle
{
public:
    VidroScrollStyle(QStyle *base, const Cfg &c) : QProxyStyle(base), m_cfg(c) { m_filtro.s = this; }

    int styleHint(StyleHint h, const QStyleOption *o, const QWidget *w, QStyleHintReturn *r) const override
    {
        if (h == SH_ScrollBar_Transient)
            return m_cfg.sobreposta ? 1 : QProxyStyle::styleHint(h, o, w, r);
        return QProxyStyle::styleHint(h, o, w, r);
    }

    int pixelMetric(PixelMetric m, const QStyleOption *o, const QWidget *w) const override
    {
        // barra sobreposta: o conteúdo ocupa a largura toda e a barra fica por cima (como no macOS)
        if (m == PM_ScrollView_ScrollBarOverlap && m_cfg.sobreposta)
            return QProxyStyle::pixelMetric(PM_ScrollBarExtent, o, w);
        return QProxyStyle::pixelMetric(m, o, w);
    }

    void polish(QWidget *w) override
    {
        QProxyStyle::polish(w);
        if (!m_cfg.sobreposta || !m_cfg.some) return;
        if (auto *sb = qobject_cast<QScrollBar *>(w)) {
            sb->installEventFilter(&m_filtro);
            QObject::connect(sb, &QAbstractSlider::valueChanged, sb, [this, sb] { acordar(sb); });
            QObject::connect(sb, &QAbstractSlider::rangeChanged, sb, [this, sb] { acordar(sb); });
            sb->setProperty("_vidro_op", 1.0);
            agendar(sb);
        }
    }

    void drawComplexControl(ComplexControl cc, const QStyleOptionComplex *opt, QPainter *p, const QWidget *w) const override
    {
        if (cc == CC_ScrollBar && m_cfg.sobreposta && m_cfg.some && w) {
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
    class Filtro : public QObject {
    public:
        VidroScrollStyle *s = nullptr;
        bool eventFilter(QObject *o, QEvent *e) override {
            auto *sb = qobject_cast<QScrollBar *>(o);
            if (sb && (e->type() == QEvent::Enter || e->type() == QEvent::MouseButtonPress || e->type() == QEvent::Wheel || e->type() == QEvent::Show)) s->acordar(sb);
            if (sb && e->type() == QEvent::Leave) s->agendar(sb);
            return false;
        }
    };
    friend class Filtro;
    mutable Filtro m_filtro;

    void animar(QScrollBar *sb, qreal para, int ms) const
    {
        auto *anim = sb->findChild<QVariantAnimation *>(QStringLiteral("_vidro_anim"));
        if (!anim) {
            anim = new QVariantAnimation(sb);
            anim->setObjectName(QStringLiteral("_vidro_anim"));
            QObject::connect(anim, &QVariantAnimation::valueChanged, sb, [sb](const QVariant &v) { sb->setProperty("_vidro_op", v); sb->update(); });
        }
        anim->stop();
        anim->setStartValue(sb->property("_vidro_op").isValid() ? sb->property("_vidro_op").toReal() : 1.0);
        anim->setEndValue(para);
        anim->setDuration(ms);
        anim->setEasingCurve(QEasingCurve::InOutCubic);
        anim->start();
    }
    void acordar(QScrollBar *sb) const
    {
        animar(sb, 1.0, 120);
        agendar(sb);
    }
    void agendar(QScrollBar *sb) const
    {
        auto *t = sb->findChild<QTimer *>(QStringLiteral("_vidro_timer"));
        if (!t) {
            t = new QTimer(sb);
            t->setObjectName(QStringLiteral("_vidro_timer"));
            t->setSingleShot(true);
            QObject::connect(t, &QTimer::timeout, sb, [this, sb] {
                if (sb->underMouse() || sb->isSliderDown()) { agendar(sb); return; }
                animar(sb, m_cfg.minima / 100.0, 420);
            });
        }
        t->start(m_cfg.espera);
    }
    Cfg m_cfg;
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
        const Cfg c = lerCfg();
        if (!c.sobreposta) return base;  // desligado: Union puro
        return new VidroScrollStyle(base, c);
    }
};
#include "vidroscroll.moc"
