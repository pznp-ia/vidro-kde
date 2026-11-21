// Vidro — janela de prévia: mostra barra de rolagem, menu de clique direito, ícones de pastas e controles
// com o estilo ATUAL (apps do KDE só leem o estilo ao abrir; esta janela abre nova a cada clique).
#include <QApplication>
#include <QMainWindow>
#include <QMenu>
#include <QTimer>
#include <QLabel>
#include <QIcon>
#include <QListWidget>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QCheckBox>
#include <QSlider>
#include <QComboBox>
int main(int argc, char **argv) {
    QApplication app(argc, argv);
    app.setDesktopFileName(QStringLiteral("vidro-previa"));
    QMainWindow w; w.setWindowTitle(QStringLiteral("Prévia do Vidro"));
    auto *central = new QWidget; auto *v = new QVBoxLayout(central);
    auto *dica = new QLabel(QStringLiteral("Clique com o botão direito em qualquer lugar para ver o menu."));
    dica->setWordWrap(true); v->addWidget(dica);
    auto *h = new QHBoxLayout;
    auto *pastas = new QListWidget; pastas->setViewMode(QListView::IconMode); pastas->setIconSize(QSize(48, 48));
    pastas->setGridSize(QSize(96, 84)); pastas->setResizeMode(QListView::Adjust); pastas->setMovement(QListView::Static);
    const char *nomes[][2] = {{"folder", "Pasta"}, {"folder-documents", "Documentos"}, {"folder-download", "Downloads"},
                              {"folder-pictures", "Imagens"}, {"folder-music", "Músicas"}, {"folder-videos", "Vídeos"},
                              {"user-home", "Início"}, {"folder-open", "Aberta"}};
    for (auto &n : nomes) pastas->addItem(new QListWidgetItem(QIcon::fromTheme(QString::fromLatin1(n[0])), QString::fromUtf8(n[1])));
    h->addWidget(pastas, 3);
    auto *texto = new QPlainTextEdit; QString t;
    for (int i = 1; i <= 200; ++i) t += QStringLiteral("Linha %1 — role para ver a barra de rolagem do Vidro.\n").arg(i);
    texto->setPlainText(t); texto->setReadOnly(true); h->addWidget(texto, 2);
    v->addLayout(h, 1);
    auto *ctl = new QHBoxLayout;
    ctl->addWidget(new QPushButton(QStringLiteral("Botão"))); auto *c = new QCheckBox(QStringLiteral("Opção")); c->setChecked(true); ctl->addWidget(c);
    auto *s = new QSlider(Qt::Horizontal); s->setValue(60); ctl->addWidget(s, 1);
    auto *cb = new QComboBox; cb->addItems({QStringLiteral("Lista"), QStringLiteral("Item 2")}); ctl->addWidget(cb);
    v->addLayout(ctl);
    w.setCentralWidget(central); w.resize(860, 560); w.show();

    QMenu *m = new QMenu(&w);
    m->addAction(QIcon::fromTheme(QStringLiteral("document-open")), QStringLiteral("Abrir"));
    m->addAction(QIcon::fromTheme(QStringLiteral("edit-copy")), QStringLiteral("Copiar"));
    m->addAction(QIcon::fromTheme(QStringLiteral("edit-paste")), QStringLiteral("Colar"));
    m->addSeparator();
    QMenu *sub = m->addMenu(QIcon::fromTheme(QStringLiteral("document-share")), QStringLiteral("Compartilhar"));
    sub->addAction(QStringLiteral("E-mail")); sub->addAction(QStringLiteral("Bluetooth"));
    m->addAction(QIcon::fromTheme(QStringLiteral("edit-rename")), QStringLiteral("Renomear…"));
    m->addSeparator();
    m->addAction(QIcon::fromTheme(QStringLiteral("edit-delete")), QStringLiteral("Mover para a lixeira"));
    for (QWidget *wd : {static_cast<QWidget *>(central), static_cast<QWidget *>(pastas), static_cast<QWidget *>(texto), static_cast<QWidget *>(dica)}) {
        wd->setContextMenuPolicy(Qt::CustomContextMenu);
        QObject::connect(wd, &QWidget::customContextMenuRequested, [m, wd](const QPoint &p) { m->popup(wd->mapToGlobal(p)); });
    }
    if (app.arguments().contains(QStringLiteral("--menu")))  // usado nos testes (só funciona em X11/XWayland)
        QTimer::singleShot(1200, [&] { m->popup(w.mapToGlobal(QPoint(160, 120))); });
    return app.exec();
}
