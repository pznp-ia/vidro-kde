// Vidro preview window: shows the scrollbar, right-click menu, folder icons and common controls
// with the CURRENT style (KDE apps only read the style when they start; this window starts fresh each time).
//   vidro-preview                      open the window
//   vidro-preview --screenshot FILE    render without showing anything and save a PNG (used for tests)
//   vidro-preview --menu               open the context menu after 1.2 s (X11/XWayland only)
#include <QApplication>
#include <QCheckBox>
#include <QComboBox>
#include <QHBoxLayout>
#include <QIcon>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QMainWindow>
#include <QMenu>
#include <QPlainTextEdit>
#include <QProgressBar>
#include <QPushButton>
#include <QRadioButton>
#include <QSlider>
#include <QSpinBox>
#include <QTabWidget>
#include <QTimer>
#include <QToolButton>
#include <QVBoxLayout>

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    app.setDesktopFileName(QStringLiteral("vidro-preview"));
    QMainWindow w;
    w.setWindowTitle(QStringLiteral("Prévia do Vidro"));
    auto *central = new QWidget;
    auto *v = new QVBoxLayout(central);
    auto *hint = new QLabel(QStringLiteral("Clique com o botão direito em qualquer lugar para ver o menu."));
    hint->setWordWrap(true);
    v->addWidget(hint);

    // tool bar row
    auto *tools = new QHBoxLayout;
    for (const char *icon : {"document-new", "document-open", "document-save", "edit-undo", "edit-redo"}) {
        auto *b = new QToolButton;
        b->setIcon(QIcon::fromTheme(QString::fromLatin1(icon)));
        b->setAutoRaise(true);
        tools->addWidget(b);
    }
    auto *checkedTool = new QToolButton;
    checkedTool->setIcon(QIcon::fromTheme(QStringLiteral("view-list-icons")));
    checkedTool->setCheckable(true);
    checkedTool->setChecked(true);
    checkedTool->setAutoRaise(true);
    tools->addWidget(checkedTool);
    tools->addStretch(1);
    auto *search = new QLineEdit;
    search->setPlaceholderText(QStringLiteral("Pesquisar…"));
    search->setClearButtonEnabled(true);
    tools->addWidget(search);
    v->addLayout(tools);

    auto *tabs = new QTabWidget;
    // tab 1: folders + long text (scrollbar)
    auto *page1 = new QWidget;
    auto *h = new QHBoxLayout(page1);
    auto *folders = new QListWidget;
    folders->setViewMode(QListView::IconMode);
    folders->setIconSize(QSize(48, 48));
    folders->setGridSize(QSize(96, 84));
    folders->setResizeMode(QListView::Adjust);
    folders->setMovement(QListView::Static);
    const char *names[][2] = {{"folder", "Pasta"}, {"folder-documents", "Documentos"}, {"folder-download", "Downloads"},
                              {"folder-pictures", "Imagens"}, {"folder-music", "Músicas"}, {"folder-videos", "Vídeos"},
                              {"user-home", "Início"}, {"folder-open", "Aberta"}};
    for (auto &n : names)
        folders->addItem(new QListWidgetItem(QIcon::fromTheme(QString::fromLatin1(n[0])), QString::fromUtf8(n[1])));
    folders->setCurrentRow(1);
    h->addWidget(folders, 3);
    auto *text = new QPlainTextEdit;
    QString t;
    for (int i = 1; i <= 200; ++i)
        t += QStringLiteral("Linha %1 — role para ver a barra de rolagem do Vidro.\n").arg(i);
    text->setPlainText(t);
    text->setReadOnly(true);
    h->addWidget(text, 2);
    tabs->addTab(page1, QIcon::fromTheme(QStringLiteral("folder")), QStringLiteral("Arquivos"));
    // tab 2: list with a selection
    auto *list = new QListWidget;
    for (const char *s : {"Documentos", "Imagens", "Projetos", "Músicas", "Vídeos"})
        list->addItem(QString::fromUtf8(s));
    list->setCurrentRow(2);
    tabs->addTab(list, QIcon::fromTheme(QStringLiteral("view-list-details")), QStringLiteral("Lista"));
    tabs->addTab(new QWidget, QStringLiteral("Outra aba"));
    v->addWidget(tabs, 1);

    // controls row
    auto *ctl = new QHBoxLayout;
    ctl->addWidget(new QPushButton(QIcon::fromTheme(QStringLiteral("dialog-ok")), QStringLiteral("Botão")));
    auto *def = new QPushButton(QStringLiteral("Padrão"));
    def->setDefault(true);
    ctl->addWidget(def);
    auto *check = new QCheckBox(QStringLiteral("Opção"));
    check->setChecked(true);
    ctl->addWidget(check);
    ctl->addWidget(new QCheckBox(QStringLiteral("Outra")));
    auto *radio = new QRadioButton(QStringLiteral("Um"));
    radio->setChecked(true);
    ctl->addWidget(radio);
    ctl->addWidget(new QRadioButton(QStringLiteral("Dois")));
    auto *spin = new QSpinBox;
    spin->setValue(42);
    ctl->addWidget(spin);
    auto *combo = new QComboBox;
    combo->addItems({QStringLiteral("Lista"), QStringLiteral("Item 2")});
    ctl->addWidget(combo);
    v->addLayout(ctl);
    auto *bars = new QHBoxLayout;
    auto *slider = new QSlider(Qt::Horizontal);
    slider->setValue(60);
    bars->addWidget(slider, 1);
    auto *progress = new QProgressBar;
    progress->setValue(40);
    bars->addWidget(progress, 1);
    v->addLayout(bars);
    w.setCentralWidget(central);
    w.resize(900, 600);

    QMenu *m = new QMenu(&w);
    m->addAction(QIcon::fromTheme(QStringLiteral("document-open")), QStringLiteral("Abrir"));
    m->addAction(QIcon::fromTheme(QStringLiteral("edit-copy")), QStringLiteral("Copiar"));
    m->addAction(QIcon::fromTheme(QStringLiteral("edit-paste")), QStringLiteral("Colar"));
    m->addSeparator();
    QMenu *sub = m->addMenu(QIcon::fromTheme(QStringLiteral("document-share")), QStringLiteral("Compartilhar"));
    sub->addAction(QStringLiteral("E-mail"));
    sub->addAction(QStringLiteral("Bluetooth"));
    m->addAction(QIcon::fromTheme(QStringLiteral("edit-rename")), QStringLiteral("Renomear…"));
    m->addSeparator();
    m->addAction(QIcon::fromTheme(QStringLiteral("edit-delete")), QStringLiteral("Mover para a lixeira"));
    for (QWidget *wd : {static_cast<QWidget *>(central), static_cast<QWidget *>(folders), static_cast<QWidget *>(text),
                        static_cast<QWidget *>(hint)}) {
        wd->setContextMenuPolicy(Qt::CustomContextMenu);
        QObject::connect(wd, &QWidget::customContextMenuRequested, [m, wd](const QPoint &p) { m->popup(wd->mapToGlobal(p)); });
    }

    const QStringList args = app.arguments();
    const int shot = args.indexOf(QStringLiteral("--screenshot"));
    if (shot >= 0 && shot + 1 < args.size()) {
        // render off screen: never shown, just painted into an image
        w.setAttribute(Qt::WA_DontShowOnScreen);
        w.show();
        QTimer::singleShot(600, [&] {
            w.grab().save(args.at(shot + 1));
            app.quit();
        });
        return app.exec();
    }
    w.show();
    if (args.contains(QStringLiteral("--menu")))
        QTimer::singleShot(1200, [&] { m->popup(w.mapToGlobal(QPoint(160, 120))); });
    return app.exec();
}
