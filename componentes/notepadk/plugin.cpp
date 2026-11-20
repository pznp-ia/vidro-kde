// NotepadK (antigo Kate Vidro) — plugin de modo foco do Kate.
// Modo foco: a janela inteira vira um bloco liso da cor do editor (sem barra de título, menus,
// barras, abas, painéis, status, números de linha, coluna de ícones e barras de rolagem).
// Um botão flutuante discreto (ou Ctrl+Shift+Espaço) mostra/esconde a interface, com transição suave.
#include <KTextEditor/Document>
#include <KTextEditor/MainWindow>
#include <KTextEditor/Plugin>
#include <KTextEditor/View>
#include <KActionCollection>
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

// Faixa do topo no modo foco: mesma cor do editor, serve para arrastar a janela
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
        // título das janelas: "arquivo — NotepadK" em vez de "— Kate"
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
                // também na coleção da janela: aparece em Configurar atalhos e fica acessível via DBus
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
            m_btn->setIconSize(QSize(16, 16));
            m_btn->setToolTip(QStringLiteral("Interface completa (Ctrl+Shift+Espaço)"));
            m_btn->setCursor(Qt::PointingHandCursor);
            m_fx = new QGraphicsOpacityEffect(m_btn);
            m_fx->setOpacity(0.35);
            m_btn->setGraphicsEffect(m_fx);
            m_btn->installEventFilter(this);
            m_win->installEventFilter(this);
            m_btn->show();
            m_btn->raise();
        }
        connect(m_mw, &KTextEditor::MainWindow::viewCreated, this, [this](KTextEditor::View *v) {
            QTimer::singleShot(0, this, [this, v] { applyView(v, m_full); });
        });
        // aplica o modo mínimo depois que a janela terminar de montar
        QTimer::singleShot(300, this, [this] { setFull(false); });
        QTimer::singleShot(1200, this, [this] { setFull(m_full); });
    }

    ~VidroFocusView() override
    {
        if (m_mw && m_mw->guiFactory()) m_mw->guiFactory()->removeClient(this);
        QFile::remove(scriptPath());
    }

protected:
    bool eventFilter(QObject *o, QEvent *e) override
    {
        if (o == m_win && (e->type() == QEvent::Resize || e->type() == QEvent::Show || e->type() == QEvent::LayoutRequest)) {
            placeButton();
        } else if (o == m_btn && m_fx) {
            if (e->type() == QEvent::Enter) m_fx->setOpacity(1.0);
            else if (e->type() == QEvent::Leave) m_fx->setOpacity(m_full ? 0.6 : 0.35);
        }
        return QObject::eventFilter(o, e);
    }

private:
    static constexpr int kStrip = 30; // altura da faixa de arrastar

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

    // Troca de modo com crossfade: congela uma foto da janela por cima, aplica a mudança
    // por baixo e some com a foto aos poucos.
    void transition(bool full)
    {
        if (!m_win || !m_win->isVisible()) { setFull(full); return; }
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
        auto *anim = new QPropertyAnimation(fx, "opacity", ov);
        anim->setDuration(320);
        anim->setStartValue(1.0);
        anim->setEndValue(0.0);
        anim->setEasingCurve(QEasingCurve::InOutCubic);
        connect(anim, &QPropertyAnimation::finished, ov, [this, ov] {
            if (m_overlay == ov) m_overlay = nullptr;
            ov->deleteLater();
        });
        // dá um quadro para o layout novo assentar antes de começar o fade
        QTimer::singleShot(16, anim, [anim] { anim->start(); });
    }

    QString scriptPath() const
    {
        return QDir::tempPath() + QStringLiteral("/notepadk-borda-%1.js").arg(QCoreApplication::applicationPid());
    }

    // Barra de título (decoração do KWin) ligada/desligada para as janelas deste processo.
    void setBorder(bool on)
    {
        const QString path = scriptPath();
        QFile f(path);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) return;
        f.write(QStringLiteral("for (const w of workspace.windowList()) { if (w.pid === %1 && w.normalWindow) w.noBorder = %2; }\n")
                    .arg(QCoreApplication::applicationPid())
                    .arg(on ? QStringLiteral("false") : QStringLiteral("true"))
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

    // cor de fundo real do editor (tema da view; senão o tema padrão do editor)
    QColor editorBackground() const
    {
        const auto views = m_mw->views();
        const KSyntaxHighlighting::Theme t = views.isEmpty() ? KTextEditor::Editor::instance()->theme() : views.first()->theme();
        const QColor c = QColor::fromRgba(t.editorColor(KSyntaxHighlighting::Theme::BackgroundColor));
        return c.isValid() ? c : QColor(35, 38, 41);
    }

    static QString focusThemeName() { return QStringLiteral("NotepadK Foco"); }

    // Gera (em XDG_DATA_HOME do NotepadK) uma cópia do tema atual com linha atual, borda de ícones,
    // separador e dobras na cor do fundo. O Kate só lê temas novos ao iniciar: vale a partir da próxima abertura.
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
            if (role == T::CurrentLine || role == T::IconBorder || role == T::Separator || role == T::CodeFolding
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

    // Modo foco: tudo (janela, molduras, fundo) com a cor do fundo do editor.
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

    // Barras de rolagem: some no modo foco (largura/altura 0), volta no modo completo.
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
        m_win->setContentsMargins(0, full ? 0 : kStrip, 0, 0); // espaço da faixa de arrastar
        if (m_win->menuBar()) m_win->menuBar()->setVisible(full);
        if (m_win->statusBar()) m_win->statusBar()->setVisible(full);
        const auto bars = m_win->findChildren<QToolBar *>();
        for (QToolBar *tb : bars) tb->setVisible(full);
        // painéis laterais, abas, barra de navegação/URL, barra de status do Kate
        const auto widgets = m_win->findChildren<QWidget *>();
        for (QWidget *w : widgets) {
            if (w == m_btn || w == m_overlay || w == m_strip || !isChrome(w)) continue;
            if (!full) {
                if (w->isVisible()) { m_hidden.append(QPointer<QWidget>(w)); w->setVisible(false); }
            }
        }
        // rodapé da área central (linha separadora + barra de 24 px): tudo que não contém o editor
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
        // painéis laterais: usa o comando nativo do Kate
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
            if (m_fx) m_fx->setOpacity(full ? 0.6 : 0.35);
        }
        placeButton();
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
            // tema "NotepadK Foco": sem faixa na linha atual nem fio na borda esquerda
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
};

class VidroFocusPlugin : public KTextEditor::Plugin
{
    Q_OBJECT
public:
    explicit VidroFocusPlugin(QObject *parent, const QVariantList & = QVariantList()) : KTextEditor::Plugin(parent) {}
    QObject *createView(KTextEditor::MainWindow *mw) override
    {
        // só age no NotepadK (VIDRO_FOCUS=1); no Kate normal fica inerte
        if (qEnvironmentVariableIsEmpty("VIDRO_FOCUS")) return new QObject(mw);
        return new VidroFocusView(this, mw);
    }
};

K_PLUGIN_FACTORY_WITH_JSON(VidroFocusPluginFactory, "plugin.json", registerPlugin<VidroFocusPlugin>();)
#include "plugin.moc"
