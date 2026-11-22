// NotepadK (formerly Kate Vidro) — focus-mode plugin for Kate.
// Focus mode: the whole window becomes a plain block in the editor color (no titlebar, menus,
// toolbars, tabs, panels, status bar, line numbers, icon border and scrollbars).
// A discreet floating button (or Ctrl+Shift+Space) shows/hides the interface with a smooth transition.
#include <KTextEditor/Document>
#include <KTextEditor/MainWindow>
#include <KTextEditor/Plugin>
#include <KTextEditor/View>
#include <KActionCollection>
#include <KConfigGroup>
#include <KSharedConfig>
#include <KPluginFactory>
#include <KXMLGUIClient>
#include <KXMLGUIFactory>
#include <KXmlGuiWindow>
#include <KSyntaxHighlighting/Repository>
#include <KSyntaxHighlighting/Theme>
#include <QJsonDocument>
#include <QJsonObject>
#include <QMetaEnum>
#include <QStandardPaths>
#include <KTextEditor/Editor>
#include <QAction>
#include <QCoreApplication>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFrame>
#include <QTextStream>
#include <QFile>
#include <QGuiApplication>
#include <QLabel>
#include <QMouseEvent>
#include <QWindow>
#include <QPropertyAnimation>
#include <QParallelAnimationGroup>
#include <QScrollBar>
#include <QEvent>
#include <QGraphicsOpacityEffect>
#include <QIcon>
#include <QMainWindow>
#include <QMenuBar>
#include <QPointer>
#include <QStatusBar>
#include <QTimer>
#include <QToolBar>
#include <QToolButton>
#include <QRegularExpression>
#include <KTextEditor/Document>

// Top strip in focus mode: same color as the editor, used to drag the window
// (clique duplo = maximizar/restaurar).
class NotepadKDragStrip : public QWidget
{
public:
    explicit NotepadKDragStrip(QWidget *parent) : QWidget(parent)
    {
        setAutoFillBackground(true);
        setCursor(Qt::OpenHandCursor);
    }
protected:
    void mousePressEvent(QMouseEvent *e) override
    {
        if (e->button() == Qt::LeftButton && window()->windowHandle()) window()->windowHandle()->startSystemMove();
    }
    void mouseDoubleClickEvent(QMouseEvent *e) override
    {
        if (e->button() != Qt::LeftButton) return;
        QWidget *w = window();
        w->isMaximized() ? w->showNormal() : w->showMaximized();
    }
};

class VidroFocusView : public QObject, public KXMLGUIClient
{
    Q_OBJECT
public:
    VidroFocusView(KTextEditor::Plugin *plugin, KTextEditor::MainWindow *mw)
        : QObject(mw), m_mw(mw)
    {
        Q_UNUSED(plugin)
        KXMLGUIClient::setComponentName(QStringLiteral("vidrofocus"), QStringLiteral("NotepadK"));
        // window title: "file — NotepadK" instead of "— Kate"
        QGuiApplication::setApplicationDisplayName(QStringLiteral("NotepadK"));
        m_action = actionCollection()->addAction(QStringLiteral("vidro_focus_full"));
        m_action->setText(QStringLiteral("Interface completa"));
        m_action->setIcon(QIcon::fromTheme(QStringLiteral("view-fullscreen")));
        m_action->setCheckable(true);
        KActionCollection::setDefaultShortcut(m_action, QKeySequence(QStringLiteral("Ctrl+Shift+Space")));
        connect(m_action, &QAction::toggled, this, &VidroFocusView::transition);
        setXML(QStringLiteral("<!DOCTYPE gui><gui name=\"vidrofocus\" version=\"1\"><MenuBar><Menu name=\"view\">"
                              "<Action name=\"vidro_focus_full\"/></Menu></MenuBar></gui>"));
        m_mw->guiFactory()->addClient(this);

        m_win = qobject_cast<QMainWindow *>(m_mw->window());
        if (m_win) {
            m_win->addAction(m_action); // atalho funciona mesmo sem menu
            if (auto *xw = qobject_cast<KXmlGuiWindow *>(m_win.data())) {
                // also in the window collection: shows up in Configure Shortcuts and is reachable over DBus
                QAction *mirror = xw->actionCollection()->addAction(QStringLiteral("vidro_focus_toggle"));
                mirror->setText(QStringLiteral("NotepadK: alternar interface completa"));
                connect(mirror, &QAction::triggered, m_action, &QAction::toggle);
            }
            m_strip = new NotepadKDragStrip(m_win);
            m_strip->hide();
            m_btn = new QToolButton(m_win);
            m_btn->setDefaultAction(m_action);
            m_btn->setToolButtonStyle(Qt::ToolButtonIconOnly);
            m_btn->setAutoRaise(true);
            m_btn->setFixedSize(28, 28);
            m_btn->setVisible(setting("ShowButton", 1));
            m_btn->setIconSize(QSize(16, 16));
            m_btn->setToolTip(QStringLiteral("Interface completa (Ctrl+Shift+Espaço)"));
            m_btn->setCursor(Qt::PointingHandCursor);
            m_fx = new QGraphicsOpacityEffect(m_btn);
            m_fx->setOpacity(kBtnOpacity);
            m_btn->setGraphicsEffect(m_fx);
            m_btn->installEventFilter(this);
            m_win->installEventFilter(this);
            if (setting("ShowButton", 1)) { m_btn->show(); m_btn->raise(); } else m_btn->hide();
            m_count = new QLabel(m_win);
            m_count->setAttribute(Qt::WA_TransparentForMouseEvents);
            m_count->hide();
            m_countTimer.setSingleShot(true);
            m_countTimer.setInterval(400);
            connect(&m_countTimer, &QTimer::timeout, this, &VidroFocusView::updateCount);
            if (QWidget *c = m_win->centralWidget()) c->installEventFilter(this);
        }
        connect(m_mw, &KTextEditor::MainWindow::viewCreated, this, [this](KTextEditor::View *v) {
            QTimer::singleShot(0, this, [this, v] { applyView(v, m_full); });
        });
        connect(m_mw, &KTextEditor::MainWindow::viewChanged, this, [this](KTextEditor::View *v) {
            if (m_doc) disconnect(m_doc, nullptr, this, nullptr);
            m_doc = v ? v->document() : nullptr;
            if (m_doc) connect(m_doc, &KTextEditor::Document::textChanged, this, [this] { m_countTimer.start(); });
            m_countTimer.start();
            QTimer::singleShot(0, this, [this] { applyMargins(); });
        });
        // apply the minimal mode after the window finishes building
        QTimer::singleShot(300, this, [this] { setFull(false); });
        m_full = !setting("StartFocused", 1);   // open in focus mode (default) or with the full interface
        QTimer::singleShot(1200, this, [this] { setFull(m_full); });
        if (setting("OpenAnimation", 1)) QTimer::singleShot(320, this, [this] { openAnimation(); });
    }

    ~VidroFocusView() override
    {
        if (m_mw && m_mw->guiFactory()) m_mw->guiFactory()->removeClient(this);
        QFile::remove(scriptPath());
    }

protected:
    bool eventFilter(QObject *o, QEvent *e) override
    {
        if (m_win && o == m_win->centralWidget() && e->type() == QEvent::Resize) {
            QTimer::singleShot(0, this, [this] { applyMargins(); });
        } else if (o == m_win && (e->type() == QEvent::Resize || e->type() == QEvent::Show || e->type() == QEvent::LayoutRequest)) {
            placeButton();
        } else if (o == m_btn && m_fx) {
            if (e->type() == QEvent::Enter) m_fx->setOpacity(1.0);
            else if (e->type() == QEvent::Leave) m_fx->setOpacity(m_full ? 0.6 : kBtnOpacity);
        }
        return QObject::eventFilter(o, e);
    }

private:
    // NotepadK settings (katerc [NotepadK], written by Vidro Settings → NotepadK)
    static int setting(const char *key, int def) { return KSharedConfig::openConfig()->group(QStringLiteral("NotepadK")).readEntry(key, def); }
    static QString settingStr(const char *key, const QString &def) { return KSharedConfig::openConfig()->group(QStringLiteral("NotepadK")).readEntry(key, def); }
    const int kStrip = qBound(16, setting("StripHeight", 30), 60); // height of the drag strip
    const qreal kBtnOpacity = qBound(5, setting("ButtonOpacity", 35), 100) / 100.0;

    QEasingCurve easing() const
    {
        const QString e = settingStr("Easing", QStringLiteral("smooth"));
        if (e == QLatin1String("fast")) return QEasingCurve::OutExpo;
        if (e == QLatin1String("bounce")) return QEasingCurve::OutBack;
        if (e == QLatin1String("linear")) return QEasingCurve::Linear;
        return QEasingCurve::InOutCubic;
    }

    // Text block: side/top margins and an optional centered column (N characters wide), focus mode only.
    void applyMargins()
    {
        if (!m_win) return;
        QWidget *c = m_win->centralWidget();
        if (!c) return;
        if (m_full) { c->setContentsMargins(0, 0, 0, 0); return; }
        const int margin = qBound(0, setting("Margin", 24), 300);
        const int top = qBound(0, setting("MarginTop", 8), 200);
        int side = margin;
        const int cols = setting("ColumnChars", 0);
        const auto views = m_mw->views();
        if (cols > 0 && !views.isEmpty()) {
            const QFont f = views.first()->configValue(QStringLiteral("font")).value<QFont>();
            const int colPx = QFontMetrics(f).horizontalAdvance(QString(cols, QLatin1Char('n'))) + 24;
            side = qMax(margin, (c->width() - colPx) / 2);
        }
        if (c->contentsMargins() != QMargins(side, top, side, top)) c->setContentsMargins(side, top, side, top);
        placeCount();
    }

    // discreet word counter (bottom right), focus mode only
    void updateCount()
    {
        if (!m_count) return;
        const bool on = !m_full && setting("WordCount", 0);
        if (!on || !m_doc) { m_count->hide(); return; }
        static const QRegularExpression ws(QStringLiteral("\\s+"));
        const QString t = m_doc->text().trimmed();
        const int n = t.isEmpty() ? 0 : int(t.split(ws, Qt::SkipEmptyParts).size());
        m_count->setText(n == 1 ? QStringLiteral("1 palavra") : QStringLiteral("%1 palavras").arg(n));
        const QColor bg = editorBackground();
        const QColor fg = bg.lightness() > 128 ? QColor(0, 0, 0, 110) : QColor(255, 255, 255, 110);
        m_count->setStyleSheet(QStringLiteral("color: %1; background: transparent; font-size: 9pt;").arg(fg.name(QColor::HexArgb)));
        m_count->adjustSize();
        m_count->show();
        placeCount();
    }
    void placeCount()
    {
        if (!m_count || !m_win) return;
        m_count->move(m_win->width() - m_count->width() - 18, m_win->height() - m_count->height() - 10);
        m_count->raise();
    }

    // Opening: the text area appears with a fade (a cover in the editor color that fades out)
    void openAnimation()
    {
        if (!m_win) return;
        auto *cover = new QWidget(m_win);
        cover->setAttribute(Qt::WA_TransparentForMouseEvents);
        cover->setAutoFillBackground(true);
        QPalette p = cover->palette();
        p.setColor(QPalette::Window, editorBackground());
        cover->setPalette(p);
        cover->setGeometry(0, 0, m_win->width(), m_win->height());
        auto *fx = new QGraphicsOpacityEffect(cover);
        fx->setOpacity(1.0);
        cover->setGraphicsEffect(fx);
        cover->show();
        cover->raise();
        auto *anim = new QPropertyAnimation(fx, "opacity", cover);
        anim->setDuration(qBound(150, int(setting("FadeMs", 320) * 1.6), 2000));
        anim->setStartValue(1.0);
        anim->setEndValue(0.0);
        anim->setEasingCurve(QEasingCurve::OutCubic);
        connect(anim, &QPropertyAnimation::finished, cover, &QObject::deleteLater);
        QTimer::singleShot(950, anim, [anim] { anim->start(); });   // after the focus layout settles
    }

    void placeButton()
    {
        if (!m_win || !m_btn) return;
        if (m_strip) {
            m_strip->setGeometry(0, 0, m_win->width(), kStrip);
            m_strip->setVisible(!m_full);
            m_strip->raise();
        }
        int top = full_or_strip_top();
        if (m_full && m_win->menuBar() && m_win->menuBar()->isVisible()) top += m_win->menuBar()->height();
        m_btn->move(m_win->width() - m_btn->width() - 22, top);
        m_btn->raise();
    }

    // Mode switch with a crossfade: freeze a snapshot of the window on top, apply the change
    // underneath and fade the snapshot out.
    void transition(bool full)
    {
        const QString style = settingStr("Transition", QStringLiteral("fade"));
        if (!m_win || !m_win->isVisible() || style == QLatin1String("none") || setting("FadeMs", 320) <= 0) { setFull(full); return; }
        if (m_overlay) { m_overlay->deleteLater(); m_overlay = nullptr; }
        auto *ov = new QLabel(m_win);
        ov->setPixmap(m_win->grab());
        ov->setAttribute(Qt::WA_TransparentForMouseEvents);
        ov->setGeometry(0, 0, m_win->width(), m_win->height());
        ov->setAlignment(Qt::AlignLeft | Qt::AlignTop);
        auto *fx = new QGraphicsOpacityEffect(ov);
        fx->setOpacity(1.0);
        ov->setGraphicsEffect(fx);
        ov->show();
        ov->raise();
        m_overlay = ov;
        setFull(full);
        ov->raise();
        const int ms = qBound(0, setting("FadeMs", 320), 1500);
        auto *anim = new QParallelAnimationGroup(ov);
        auto *fade = new QPropertyAnimation(fx, "opacity", anim);
        fade->setDuration(ms);
        fade->setStartValue(1.0);
        fade->setEndValue(0.0);
        fade->setEasingCurve(easing());
        anim->addAnimation(fade);
        const QRect r0 = ov->geometry();
        if (style == QLatin1String("slide") || style == QLatin1String("zoom")) {
            ov->setScaledContents(true);
            auto *geo = new QPropertyAnimation(ov, "geometry", anim);
            geo->setDuration(ms);
            geo->setStartValue(r0);
            if (style == QLatin1String("slide"))
                geo->setEndValue(r0.translated(0, full ? r0.height() / 10 : -r0.height() / 10));
            else {
                const int dx = r0.width() * (full ? -4 : 4) / 100, dy = r0.height() * (full ? -4 : 4) / 100;
                geo->setEndValue(r0.adjusted(dx, dy, -dx, -dy));
            }
            geo->setEasingCurve(easing());
            anim->addAnimation(geo);
        }
        connect(anim, &QAbstractAnimation::finished, ov, [this, ov] {
            if (m_overlay == ov) m_overlay = nullptr;
            ov->deleteLater();
        });
        // give the new layout one frame to settle before the fade starts
        QTimer::singleShot(16, anim, [anim] { anim->start(); });
    }

    QString scriptPath() const
    {
        return QDir::tempPath() + QStringLiteral("/notepadk-borda-%1.js").arg(QCoreApplication::applicationPid());
    }

    // Titlebar (KWin decoration) on/off for the windows of this process.
    void setBorder(bool on)
    {
        const QString path = scriptPath();
        QFile f(path);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) return;
        const bool hideBar = !on && setting("HideTitlebar", 1);
        const bool above = !on && setting("KeepAbove", 0);
        const double opacity = qBound(30, setting("WindowOpacity", 100), 100) / 100.0;
        f.write(QStringLiteral("for (const w of workspace.windowList()) { if (w.pid === %1 && w.normalWindow) { w.noBorder = %2; w.keepAbove = %3; w.opacity = %4; } }\n")
                    .arg(QCoreApplication::applicationPid())
                    .arg(hideBar ? QStringLiteral("true") : QStringLiteral("false"))
                    .arg(above ? QStringLiteral("true") : QStringLiteral("false"))
                    .arg(opacity)
                    .toUtf8());
        f.close();
        const QString name = QStringLiteral("notepadk-borda-%1-%2").arg(QCoreApplication::applicationPid()).arg(++m_scriptSeq);
        QDBusInterface kwin(QStringLiteral("org.kde.KWin"), QStringLiteral("/Scripting"), QStringLiteral("org.kde.kwin.Scripting"));
        if (!kwin.isValid()) return;
        QDBusReply<int> id = kwin.call(QStringLiteral("loadScript"), path, name);
        if (!id.isValid() || id.value() < 0) return;
        QDBusInterface script(QStringLiteral("org.kde.KWin"), QStringLiteral("/Scripting/Script%1").arg(id.value()), QStringLiteral("org.kde.kwin.Script"));
        script.call(QStringLiteral("run"));
        QTimer::singleShot(500, this, [name] {
            QDBusInterface k(QStringLiteral("org.kde.KWin"), QStringLiteral("/Scripting"), QStringLiteral("org.kde.kwin.Scripting"));
            k.call(QStringLiteral("unloadScript"), name);
        });
    }

    // real editor background color (view theme; otherwise the default editor theme)
    QColor editorBackground() const
    {
        const auto views = m_mw->views();
        const KSyntaxHighlighting::Theme t = views.isEmpty() ? KTextEditor::Editor::instance()->theme() : views.first()->theme();
        const QColor c = QColor::fromRgba(t.editorColor(KSyntaxHighlighting::Theme::BackgroundColor));
        return c.isValid() ? c : QColor(35, 38, 41);
    }

    static QString focusThemeName() { return QStringLiteral("NotepadK Foco"); }

    // Generates (in NotepadK's XDG_DATA_HOME) a copy of the current theme with the current line, icon border,
    // separator and folding in the background color. Kate only reads new themes at startup: takes effect next launch.
    static void writeFocusTheme(const KSyntaxHighlighting::Theme &base)
    {
        using T = KSyntaxHighlighting::Theme;
        if (!base.isValid() || base.name() == focusThemeName()) return;
        const QRgb bg = base.editorColor(T::BackgroundColor);
        auto hex = [](QRgb c) { return QColor::fromRgba(c).name(); };
        QJsonObject meta{{QStringLiteral("name"), focusThemeName()}, {QStringLiteral("revision"), 1},
                         {QStringLiteral("license"), QStringLiteral("MIT")}, {QStringLiteral("base"), base.name()}};
        QJsonObject ec;
        const QMetaEnum me = QMetaEnum::fromType<T::EditorColorRole>();
        for (int i = 0; i < me.keyCount(); ++i) {
            const auto role = static_cast<T::EditorColorRole>(me.value(i));
            QRgb c = base.editorColor(role);
            if (role == T::CurrentLine && setting("CurrentLine", 0)) {
                const QColor b = QColor::fromRgba(bg), t = QColor::fromRgba(base.textColor(T::Normal));
                c = QColor::fromRgbF(b.redF() * 0.95 + t.redF() * 0.05, b.greenF() * 0.95 + t.greenF() * 0.05, b.blueF() * 0.95 + t.blueF() * 0.05).rgba();
            } else if (role == T::CurrentLine || role == T::IconBorder || role == T::Separator || role == T::CodeFolding
                || role == T::LineNumbers || role == T::WordWrapMarker || role == T::TabMarker)
                c = bg;
            ec.insert(QString::fromLatin1(me.key(i)), hex(c));
        }
        QJsonObject ts;
        const QMetaEnum mt = QMetaEnum::fromType<T::TextStyle>();
        for (int i = 0; i < mt.keyCount(); ++i) {
            const auto st = static_cast<T::TextStyle>(mt.value(i));
            QJsonObject o;
            if (base.textColor(st)) o.insert(QStringLiteral("text-color"), hex(base.textColor(st)));
            if (base.selectedTextColor(st)) o.insert(QStringLiteral("selected-text-color"), hex(base.selectedTextColor(st)));
            if (base.backgroundColor(st)) o.insert(QStringLiteral("background-color"), hex(base.backgroundColor(st)));
            if (base.selectedBackgroundColor(st)) o.insert(QStringLiteral("selected-background-color"), hex(base.selectedBackgroundColor(st)));
            if (base.isBold(st)) o.insert(QStringLiteral("bold"), true);
            if (base.isItalic(st)) o.insert(QStringLiteral("italic"), true);
            if (base.isUnderline(st)) o.insert(QStringLiteral("underline"), true);
            if (base.isStrikeThrough(st)) o.insert(QStringLiteral("strike-through"), true);
            ts.insert(QString::fromLatin1(mt.key(i)), o);
        }
        meta.insert(QStringLiteral("revision"), setting("CurrentLine", 0) ? 2 : 1);
        const QJsonObject root{{QStringLiteral("metadata"), meta}, {QStringLiteral("editor-colors"), ec}, {QStringLiteral("text-styles"), ts}};
        const QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/org.kde.syntax-highlighting/themes");
        QDir().mkpath(dir);
        QFile f(dir + QStringLiteral("/notepadk-foco.theme"));
        const QByteArray data = QJsonDocument(root).toJson();
        if (f.open(QIODevice::ReadOnly) && f.readAll() == data) return;
        f.close();
        if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) f.write(data);
    }

    static bool focusThemeAvailable()
    {
        return KTextEditor::Editor::instance()->repository().theme(focusThemeName()).name() == focusThemeName();
    }

    // Focus mode: everything (window, frames, background) in the editor background color.
    void applyColors(bool full)
    {
        if (!m_win) return;
        if (full) {
            if (m_palSaved) { m_win->setPalette(m_origPal); m_palSaved = false; }
            return;
        }
        if (!m_palSaved) { m_origPal = m_win->palette(); m_palSaved = true; }
        QPalette p = m_origPal;
        const QColor bg = editorBackground();
        for (auto role : {QPalette::Window, QPalette::Base, QPalette::AlternateBase, QPalette::Button, QPalette::Mid, QPalette::Dark, QPalette::Shadow, QPalette::Light, QPalette::Midlight})
            for (auto grp : {QPalette::Active, QPalette::Inactive, QPalette::Disabled})
                p.setColor(grp, role, bg);
        m_win->setPalette(p);
    }

    // Scrollbars: hidden in focus mode (width/height 0), back in full mode.
    void applyScrollBars(KTextEditor::View *v, bool full)
    {
        const auto bars = v->findChildren<QScrollBar *>();
        for (QScrollBar *sb : bars) {
            if (sb->orientation() == Qt::Vertical) sb->setMaximumWidth(full ? QWIDGETSIZE_MAX : 0);
            else sb->setMaximumHeight(full ? QWIDGETSIZE_MAX : 0);
        }
    }

    int full_or_strip_top() const { return m_full ? 6 : (kStrip - 28) / 2; }

    static bool isChrome(QWidget *w)
    {
        const QByteArray cls = w->metaObject()->className();
        return cls.contains("TabBar") || cls.contains("UrlBar") || cls.contains("StatusBar")
            || cls.contains("ToolBar") || cls.contains("KateNavigation") || cls.contains("ViewSpaceTab");
    }

    void setFull(bool full)
    {
        m_full = full;
        if (m_action->isChecked() != full) {
            const QSignalBlocker b(m_action);
            m_action->setChecked(full);
        }
        if (!m_win) return;
        if (m_borderOn != full) { m_borderOn = full; setBorder(full); }
        applyColors(full);
        m_win->setContentsMargins(0, full ? 0 : kStrip, 0, 0); // room for the drag strip
        if (m_win->menuBar()) m_win->menuBar()->setVisible(full);
        if (m_win->statusBar()) m_win->statusBar()->setVisible(full);
        const auto bars = m_win->findChildren<QToolBar *>();
        for (QToolBar *tb : bars) tb->setVisible(full);
        // side panels, tabs, navigation/URL bar, Kate's status bar
        const auto widgets = m_win->findChildren<QWidget *>();
        for (QWidget *w : widgets) {
            if (w == m_btn || w == m_overlay || w == m_strip || !isChrome(w)) continue;
            if (!full) {
                if (w->isVisible()) { m_hidden.append(QPointer<QWidget>(w)); w->setVisible(false); }
            }
        }
        // footer of the central area (separator line + 24 px bar): everything that does not contain the editor
        if (!full) {
            QWidget *central = m_win->findChild<QWidget *>(QStringLiteral("KateCentralWidget"));
            if (!central) central = m_win->centralWidget();
            if (central) {
                const auto kids = central->findChildren<QWidget *>(Qt::FindDirectChildrenOnly);
                for (QWidget *w : kids) {
                    if (w->isVisible() && !w->findChild<KTextEditor::View *>()) { m_hidden.append(QPointer<QWidget>(w)); w->setVisible(false); }
                }
            }
        }
        if (full) {
            for (const QPointer<QWidget> &w : std::as_const(m_hidden)) if (w) w->setVisible(true);
            m_hidden.clear();
        }
        // side panels: use Kate's own command
        const auto acts = m_win->findChildren<QAction *>();
        for (QAction *a : acts) {
            if (a->objectName() == QLatin1String("kate_mdi_sidebar_visibility") && a->isCheckable() && a->isChecked() != full)
                a->trigger();
        }
        const auto views = m_mw->views();
        for (KTextEditor::View *v : views) applyView(v, full);
        if (m_btn) {
            m_btn->setIcon(QIcon::fromTheme(full ? QStringLiteral("view-restore") : QStringLiteral("view-fullscreen")));
            m_btn->setToolTip(full ? QStringLiteral("Modo foco (Ctrl+Shift+Espaço)") : QStringLiteral("Interface completa (Ctrl+Shift+Espaço)"));
            if (m_fx) m_fx->setOpacity(full ? 0.6 : kBtnOpacity);
        }
        placeButton();
        applyMargins();
        updateCount();
        if (!full && qEnvironmentVariableIsSet("NOTEPADK_DEBUG"))
            QTimer::singleShot(800, this, [this] { dumpTree(); });
    }

    void dumpTree()
    {
        QFile f(QDir::tempPath() + QStringLiteral("/notepadk-arvore.txt"));
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) return;
        QTextStream out(&f);
        out << "win " << m_win->width() << "x" << m_win->height() << "\n";
        const auto ws = m_win->findChildren<QWidget *>();
        for (QWidget *w : ws) {
            if (!w->isVisibleTo(m_win) || w->width() <= 0 || w->height() <= 0) continue;
            const QPoint p = w->mapTo(m_win, QPoint(0, 0));
            int depth = 0;
            for (QWidget *q = w; q && q != m_win; q = q->parentWidget()) ++depth;
            out << QString(depth, QLatin1Char(' ')) << w->metaObject()->className() << " '" << w->objectName() << "' "
                << p.x() << "," << p.y() << " " << w->width() << "x" << w->height();
            if (auto *fr = qobject_cast<QFrame *>(w)) out << " frame=" << fr->frameShape();
            out << " bg=" << w->palette().color(w->backgroundRole()).name() << " auto=" << w->autoFillBackground() << "\n";
        }
        for (KTextEditor::View *v : m_mw->views())
            for (const char *k : {"theme", "icon-border-color", "background-color", "icon-bar"})
                out << "cfg " << k << " = " << v->configValue(QString::fromLatin1(k)).toString() << " valid=" << v->configValue(QString::fromLatin1(k)).isValid() << "\n";
        out << "bg " << editorBackground().name() << "\n";
    }

    void applyView(KTextEditor::View *v, bool full)
    {
        if (!v) return;
        if (!m_orig.contains(v)) {
            QVariantMap o;
            for (const char *k : {"line-numbers", "icon-bar", "folding-bar", "scrollbar-minimap", "scrollbar-preview", "modification-markers", "dynamic-word-wrap", "icon-border-color", "theme"})
                o.insert(QString::fromLatin1(k), v->configValue(QString::fromLatin1(k)));
            m_orig.insert(v, o);
            connect(v, &QObject::destroyed, this, [this, v] { m_orig.remove(v); });
        }
        if (full) {
            const QVariantMap o = m_orig.value(v);
            for (auto it = o.cbegin(); it != o.cend(); ++it) v->setConfigValue(it.key(), it.value());
        } else {
            v->setConfigValue(QStringLiteral("line-numbers"), false);
            v->setConfigValue(QStringLiteral("icon-bar"), false);
            v->setConfigValue(QStringLiteral("folding-bar"), false);
            v->setConfigValue(QStringLiteral("scrollbar-minimap"), false);
            v->setConfigValue(QStringLiteral("scrollbar-preview"), false);
            v->setConfigValue(QStringLiteral("modification-markers"), false);
            v->setConfigValue(QStringLiteral("dynamic-word-wrap"), true);
            writeFocusTheme(v->theme());
            // "NotepadK Foco" theme: no current-line band and no left border line
            if (focusThemeAvailable()) v->setConfigValue(QStringLiteral("theme"), focusThemeName());
            v->setConfigValue(QStringLiteral("icon-border-color"), editorBackground());
        }
        applyScrollBars(v, full);
    }

    KTextEditor::MainWindow *m_mw;
    QPointer<QMainWindow> m_win;
    QAction *m_action = nullptr;
    QToolButton *m_btn = nullptr;
    QGraphicsOpacityEffect *m_fx = nullptr;
    QPointer<QLabel> m_overlay;
    NotepadKDragStrip *m_strip = nullptr;
    QPalette m_origPal;
    bool m_palSaved = false;
    bool m_borderOn = true;
    int m_scriptSeq = 0;
    QList<QPointer<QWidget>> m_hidden;
    QHash<KTextEditor::View *, QVariantMap> m_orig;
    bool m_full = false;
    QLabel *m_count = nullptr;
    QTimer m_countTimer;
    QPointer<KTextEditor::Document> m_doc;
};

class VidroFocusPlugin : public KTextEditor::Plugin
{
    Q_OBJECT
public:
    explicit VidroFocusPlugin(QObject *parent, const QVariantList & = QVariantList()) : KTextEditor::Plugin(parent) {}
    QObject *createView(KTextEditor::MainWindow *mw) override
    {
        // only acts in NotepadK (VIDRO_FOCUS=1); inert in the normal Kate
        if (qEnvironmentVariableIsEmpty("VIDRO_FOCUS")) return new QObject(mw);
        return new VidroFocusView(this, mw);
    }
};

K_PLUGIN_FACTORY_WITH_JSON(VidroFocusPluginFactory, "plugin.json", registerPlugin<VidroFocusPlugin>();)
#include "plugin.moc"
