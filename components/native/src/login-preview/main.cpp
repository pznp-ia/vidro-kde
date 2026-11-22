// Vidro login preview: runs an SDDM theme (Main.qml) in a normal, resizable window with fake
// sddm/userModel/sessionModel/keyboard objects. Nothing is executed: power buttons do nothing,
// any password "logs in" (closes the window).
//   vidro-login-preview THEME_DIR [--screenshot FILE] [--size WxH]
// Close: Esc three times, Alt+F4 or the window button.
#include <QAbstractListModel>
#include <QDir>
#include <QFile>
#include <QGuiApplication>
#include <QKeyEvent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQmlPropertyMap>
#include <QQuickItem>
#include <QQuickView>
#include <QSettings>
#include <QTimer>
#include <pwd.h>
#include <unistd.h>

class Sddm : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString hostName READ hostName CONSTANT)
    Q_PROPERTY(bool canPowerOff READ yes CONSTANT)
    Q_PROPERTY(bool canReboot READ yes CONSTANT)
    Q_PROPERTY(bool canSuspend READ yes CONSTANT)
    Q_PROPERTY(bool canHibernate READ no CONSTANT)
    Q_PROPERTY(bool canHybridSleep READ no CONSTANT)
public:
    QString hostName() const { char b[256] = {0}; gethostname(b, 255); return QString::fromLocal8Bit(b); }
    bool yes() const { return true; }
    bool no() const { return false; }
    Q_INVOKABLE void login(const QString &, const QString &password, int) {
        // empty password = shows the "wrong password" animation; anything else = success, closes
        QTimer::singleShot(500, this, [this, password] {
            if (password.isEmpty()) Q_EMIT loginFailed();
            else { Q_EMIT loginSucceeded(); QTimer::singleShot(350, qApp, &QGuiApplication::quit); }
        });
    }
    Q_INVOKABLE void powerOff() {}
    Q_INVOKABLE void reboot() {}
    Q_INVOKABLE void suspend() {}
    Q_INVOKABLE void hibernate() {}
    Q_INVOKABLE void hybridSleep() {}
Q_SIGNALS:
    void loginFailed();
    void loginSucceeded();
    void informationMessage(const QString &message);
};

class Keyboard : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool capsLock READ no CONSTANT)
    Q_PROPERTY(bool numLock READ no CONSTANT)
    Q_PROPERTY(int currentLayout READ zero CONSTANT)
    Q_PROPERTY(QVariantList layouts READ layouts CONSTANT)
public:
    bool no() const { return false; }
    int zero() const { return 0; }
    QVariantList layouts() const { return {}; }
};

class ListModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int lastIndex READ lastIndex CONSTANT)
    Q_PROPERTY(int count READ count CONSTANT)
public:
    QList<QHash<QByteArray, QString>> rows;
    QList<QByteArray> names;
    int lastIndex() const { return 0; }
    int count() const { return rows.size(); }
    int rowCount(const QModelIndex &p = {}) const override { return p.isValid() ? 0 : rows.size(); }
    QVariant data(const QModelIndex &i, int role) const override {
        if (!i.isValid() || i.row() >= rows.size()) return {};
        const int n = role - Qt::UserRole - 1;
        return (n >= 0 && n < names.size()) ? QVariant(rows[i.row()].value(names[n])) : QVariant();
    }
    QHash<int, QByteArray> roleNames() const override {
        QHash<int, QByteArray> r;
        for (int n = 0; n < names.size(); ++n) r[Qt::UserRole + 1 + n] = names[n];
        return r;
    }
};

class Closer : public QObject {
    int presses = 0;
    QTimer reset;
public:
    Closer() { reset.setSingleShot(true); reset.setInterval(1500); connect(&reset, &QTimer::timeout, [this] { presses = 0; }); }
    bool eventFilter(QObject *o, QEvent *e) override {
        if (e->type() == QEvent::KeyPress && static_cast<QKeyEvent *>(e)->key() == Qt::Key_Escape && !static_cast<QKeyEvent *>(e)->isAutoRepeat()) {
            if (++presses >= 3) { QGuiApplication::quit(); return true; }
            reset.start();
        }
        return QObject::eventFilter(o, e);
    }
};

static void readConf(QQmlPropertyMap *map, const QString &file) {
    QSettings s(file, QSettings::IniFormat);
    // QSettings maps [General] to the top level (like SDDM does)
    for (const QString &k : s.childKeys()) map->insert(k, s.value(k).toString());
}

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    app.setDesktopFileName(QStringLiteral("vidro-login-preview"));
    app.setApplicationDisplayName(QStringLiteral("Prévia da tela de login"));
    const QStringList a = app.arguments();
    if (a.size() < 2) { qWarning("usage: vidro-login-preview THEME_DIR [--screenshot FILE] [--size WxH]"); return 1; }
    const QDir theme(a[1]);
    QString shot; QSize size(1280, 720);
    for (int i = 2; i + 1 < a.size(); ++i) {
        if (a[i] == QLatin1String("--screenshot")) shot = a[i + 1];
        if (a[i] == QLatin1String("--size")) { const auto p = a[i + 1].split(QLatin1Char('x')); if (p.size() == 2) size = QSize(p[0].toInt(), p[1].toInt()); }
    }

    QString confName = QStringLiteral("theme.conf");
    {
        QSettings meta(theme.filePath(QStringLiteral("metadata.desktop")), QSettings::IniFormat);
        confName = meta.value(QStringLiteral("SddmGreeterTheme/ConfigFile"), confName).toString();
    }
    auto *config = new QQmlPropertyMap(&app);
    readConf(config, theme.filePath(confName));
    readConf(config, theme.filePath(confName + QStringLiteral(".user")));

    auto *users = new ListModel;
    users->names = {"name", "realName", "icon", "homeDir", "needsPassword"};
    if (passwd *pw = getpwuid(getuid())) {
        const QString name = QString::fromLocal8Bit(pw->pw_name);
        QString real = QString::fromLocal8Bit(pw->pw_gecos).section(QLatin1Char(','), 0, 0);
        QString icon;
        for (const QString &f : {QStringLiteral("/var/lib/AccountsService/icons/") + name, QDir::homePath() + QStringLiteral("/.face.icon"), QDir::homePath() + QStringLiteral("/.face")})
            if (QFile::exists(f)) { icon = QStringLiteral("file://") + f; break; }
        users->rows.append({{"name", name}, {"realName", real}, {"icon", icon}, {"homeDir", QDir::homePath()}, {"needsPassword", "true"}});
    }
    auto *sessions = new ListModel;
    sessions->names = {"name", "file", "comment"};
    for (const QString &dir : {QStringLiteral("/usr/share/wayland-sessions"), QStringLiteral("/usr/share/xsessions")}) {
        for (const QString &f : QDir(dir).entryList({QStringLiteral("*.desktop")})) {
            QSettings d(dir + QLatin1Char('/') + f, QSettings::IniFormat);
            const QString n = d.value(QStringLiteral("Desktop Entry/Name")).toString();
            if (!n.isEmpty() && d.value(QStringLiteral("Desktop Entry/NoDisplay")).toString() != QLatin1String("true"))
                sessions->rows.append({{"name", n}, {"file", f}, {"comment", QString()}});
        }
    }

    Sddm sddm; Keyboard keyboard;
    QQuickView view;
    QQmlContext *ctx = view.rootContext();
    ctx->setContextProperty(QStringLiteral("config"), config);
    ctx->setContextProperty(QStringLiteral("sddm"), &sddm);
    ctx->setContextProperty(QStringLiteral("userModel"), users);
    ctx->setContextProperty(QStringLiteral("sessionModel"), sessions);
    ctx->setContextProperty(QStringLiteral("keyboard"), &keyboard);
    ctx->setContextProperty(QStringLiteral("primaryScreen"), 0);
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.setTitle(QStringLiteral("Prévia da tela de login — Esc 3× fecha"));
    view.resize(size);
    Closer closer;
    view.installEventFilter(&closer);
    QObject::connect(view.engine(), &QQmlEngine::quit, &app, &QGuiApplication::quit);
    view.setSource(QUrl::fromLocalFile(theme.filePath(QStringLiteral("Main.qml"))));
    if (view.status() == QQuickView::Error) {
        for (const auto &e : view.errors()) qWarning("%s", qPrintable(e.toString()));
        return 2;
    }
    if (!shot.isEmpty()) {
        view.show();
        QTimer::singleShot(1600, [&] { view.grabWindow().save(shot); app.quit(); });
    } else {
        view.show();
    }
    return app.exec();
}
#include "main.moc"
