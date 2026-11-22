# Mudanças

## v24 — 22/11/2026
- **Código e comandos em inglês** (a interface continua em português): `vidro-theme on|off`, `vidro-opacity`, `vidro-titlebar`, `vidro-config apply`, `vidro-update --check`, `vidro-profile`. Os nomes antigos continuam funcionando como atalhos, e as configurações antigas (`~/.config/vidrorc`) são migradas sozinhas (cópia em `vidrorc.pt-backup`). Repositório reorganizado: `install.sh`, `uninstall.sh`, `components/…`.
- **Instalador com janela:** escolha dos extras (animações, telas de bloqueio, barra sobreposta, clima, login, NotepadK), barra de progresso e resumo; também por terminal (`--all`, `--only=`, `--skip=`, `--no-gui`).
- **Animações** (aba nova): abrir, fechar, minimizar, maximizar e mostrar área de trabalho, cada uma com estilo e duração, curva (suave, ágil, mola) e a velocidade geral do KDE; exemplo animado no app.
- **Menus e pop-ups:** o menu iniciar, o relógio e a bandeja agora "sobem direto", opacos, sem a fase transparente estranha; menus de clique direito com estilo próprio; o desfoque acompanha a animação.
- **Correção importante:** as opções de animação (inclusive as dos menus) nunca eram lidas pelos efeitos — eles usavam sempre os padrões. Agora mudam na hora.
- **Estúdio de estilo dos aplicativos** (aba nova): botões (vidro, planos, contorno, preenchidos), campos, caixas de seleção, abas, seleção nas listas, foco, cantos e espaçamento.
- **Estúdio dos botões das janelas:** uma cor para cada botão, quando mostrar os símbolos, espessura dos símbolos e efeito ao passar o mouse (clarear, brilho em volta).
- **Perfis** (aba nova + `vidro-profile`): salvar, carregar, apagar, exportar e importar o visual inteiro; ao carregar, o visual atual é guardado antes.
- **NotepadK** (aba nova): fonte, tamanho, cores, espaçamento entre linhas, quebra de linha, transição do modo foco, faixa de arrastar e abrir no modo foco.
- **Ícone do "mostrar área de trabalho"** escolhível na aba da barra de tarefas.
- **Widget de clima do Vidro:** substitui o do KDE, que redesenhava a tela sem parar (o plasmashell caiu de ~17 % para ~1 % de CPU e a GPU de ~49 % para ~4 %).
- App de configurações com a lateral **agrupada e rolável** (Geral, Janelas, Aplicativos, Área de trabalho, Sistema).

## v23 — 21/11/2026
- **Correção:** as opções da aba "Menu iniciar e pop-ups" não mudavam nada: o Plasma usa a versão translúcida do fundo dos pop-ups e o Vidro só gravava a outra. Agora grava nas duas.
- **Menu iniciar: tipo e opções** (aba nova): Kickoff, menu clássico ou tela cheia (troca no mesmo lugar da barra, levando as opções); favoritos e apps em grade ou lista, itens compactos, categorias à direita, trocar categoria ao passar o mouse, botões do rodapé, nomes nos botões, formato do nome dos apps, ordem alfabética, ícone e texto do botão.
- **Barra de tarefas e relógio** (aba nova): altura, flutuante, posição, largura (tela toda ou estilo dock), alinhamento, esconder, fundo; vidro próprio da barra (cantos, opacidade, contorno, sombra, cor); ícones dos apps (espaço, agrupar, só da área atual/tela atual, som, prévias, realce, clique do meio, linhas); relógio (segundos, 12/24 h, data e formato, posição da data, negrito, tamanho).
- As abas de menu e barra mostram os valores que você já tem: nada muda até você mexer.
- **Botões das janelas** (aba nova): lado (esquerda/direita), ordem (macOS/Windows), botão de menu, 6 estilos (semáforo, com símbolos, grafite, contorno, só ícones, quadrados), tamanho, espaço, cor nos inativos e todos de uma cor.
- **Ícones de arquivos** (aba nova): papel escuro, claro, colorido pelo tipo ou plano; etiqueta da extensão; cores por tipo, únicas ou cinza; canto dobrado; cantos.
- **Ícones da lateral do Dolphin** (aba nova): linha, preenchido ou colorido por local; cor; espessura; tamanho na lateral do Dolphin.
- **EditorKden:** visual mais limpo (abas em pílula, botões planos, ferramenta ativa na cor de destaque, barra só com ícones), opções para esconder menu e barra de status, cores dos clipes e da forma de onda, fundo do monitor; a disposição dos painéis agora é separada da do Kdenlive normal.
- **Tela de login** (aba nova): fundo (Honeywave, seu papel de parede, outra imagem ou cor lisa), desfoque e força, escurecer, relógio (formato, segundos, tamanho, espessura, data), posição (centro/esquerda), cor de destaque, vidro dos campos, foto (mostrar, círculo ou quadrado), fonte. Botões "Testar" (abre numa janela) e "Aplicar na tela de login" (pede a senha de administrador).
- **Estúdio do cursor** (aba nova): gera um tema de cursores completo (47 formas + atalhos com os nomes do Breeze, em SVG e Xcursor): 4 formas de seta, cores de dentro/contorno/detalhes, espessura do contorno, cantos, sombra, tamanho; modelos prontos; área para testar cada cursor; desligar volta ao cursor que você usava.

## v22b — 21/11/2026
- Correção: o plugin da barra de rolagem não tinha ido para o pacote e a instalação parava no meio. O instalador agora compila ou pula essa parte se o arquivo faltar.

## v22 — 21/11/2026
- **Atualizador:** `vidro-atualizar` (e a aba **Atualizações** no app) procura as versões publicadas no GitHub, mostra as novidades e instala por cima, mantendo as configurações e o backup de antes do Vidro. Também instala uma versão específica (`--versao`), o que serve para voltar.
- O EditorKden só é criado se o Kdenlive (flatpak) estiver instalado.
- A opção de mexer no Zen Browser foi retirada: o Zen fica com o visual dele.

## v21 — 21/11/2026
- O app **Configurações do Vidro** virou uma janela de verdade: abas na lateral, cada uma com um **exemplo desenhado que muda na hora** e botão "Recarregar Plasma".
- Widget de transparência: clique esquerdo = controle rápido; **clique direito → "Configurações do Vidro…"**.
- A janela de configurações fica sempre opaca.

## v20 — 21/11/2026
- **Barra de rolagem por cima do conteúdo**, transparente de verdade, que some quando parada (plugin do Qt próprio; vale depois do próximo login). Ajustes de tempo para sumir e visibilidade quando parada.
- **Cores:** cor de destaque e cor da fonte personalizáveis (com força na seleção e texto secundário).

## v19 — 20/11/2026
- **Menus (clique direito):** cantos, opacidade, espaçamento, linhas separadoras, contorno, realce (vidro, destaque ou cor) e animação de abrir/fechar.
- **Menu iniciar e pop-ups do painel:** cantos, fundo (do tema ou cor), opacidade, contorno, sombra.
- **Cores das pastas:** grafite, escuro, cor de destaque ou qualquer cor, com brilho, relevo e saturação.
- Cor personalizada também para a barra de título e o fundo das listas.
- Janela de prévia para ver o estilo novo sem reabrir os apps.

## v18 — 20/11/2026
- Primeira versão do app **Configurações do Vidro** e do comando `vidro-config` (configurações em `~/.config/vidrorc`).
- **Barra de rolagem** fina com estilos vidro, neon fino ou cor escolhida (largura, opacidade, realce, arredondamento, trilho).
- **Dolphin** sem linhas de separação e com a área de arquivos na cor da interface.
- **Versão clara** (teste) e **EditorKden** (Kdenlive minimalista, com configuração própria).

## v17 — 20/11/2026
- **Sombras refeitas:** perfil gaussiano (o mesmo de um desfoque real), sombra maior e levemente caída para baixo. Acabou a faixa escura dura embaixo das janelas e as emendas nos cantos.
- **Transparência:** o máximo do controle agora é 75 % para a janela ativa e 60 % para as inativas (antes era 92 % e 80 %).
- **Login (SDDM):** o tema não cria mais um teclado virtual próprio, então só aparece o teclado de tela do sistema (antes subiam dois).
- **NotepadK** (antigo "Kate Vidro"):
  - no modo foco, a janela inteira vira um bloco de uma cor: sem barra de título, linha atual, bordas, rodapé ou barras de rolagem;
  - faixa no topo, da mesma cor, para arrastar a janela (clique duplo maximiza);
  - transição suave ao mostrar e esconder a interface;
  - o título da janela passa a ser "arquivo — NotepadK".
- Instalador, desinstalador e descrição para outras pessoas instalarem.

## v14 — 20/11/2026
- Minimizar: a janela viaja em linha reta até o ícone na barra de tarefas e encolhe até o tamanho dele.
- Maximizar: animação de tamanho e posição sem o "piscar" do desfoque.
- Atalho **Win+L** (com script opcional para o Bazzite).
- *(As tentativas v15 e v16 de deixar o maximizar ainda mais liso foram desfeitas.)*

## v13 — 20/11/2026
- Tema global "Vidro" (Configurações do sistema → Tema global) reunindo estilo, cores, ícones, decoração e cursor.
- Comando `vidro-tema ligar | desligar | estado` para comparar o antes e o depois.

## v12 — 20/11/2026
- Primeira versão do minimizar até o ícone; ícone próprio para o Dolphin.
- Tela de bloqueio: o fundo desfoca uma vez só e faz um crossfade, em vez de animar o desfoque.

## v11 — 20/11/2026
- Telas de bloqueio e de sair no estilo Vidro (pacote de shell próprio).
- Tema de login SDDM Vidro.

## v10 — 20/11/2026
- Ícones: os ícones de sistema que o Vidro não redesenha deixam de cair nos genéricos do Vidro (espelhamento do tema base).
- Kate Vidro (hoje NotepadK): Kate com modo foco.

## v8 e v9 — 20/11/2026
- Tema de ícones "Vidro": pastas e documentos escuros com desenho de linha, inclusive em tamanhos pequenos e em telas com escala.

## v7 — 20/11/2026
- Estilo de apps "vidro" para o Union.

## v5 e v6 — 19 e 20/11/2026
- Transparência das janelas por um efeito próprio do KWin, com animação ao trocar o nível.
- Correção parcial para janelas minimizadas que ficavam desenhadas como "fantasmas" (ainda acontece em alguns casos; veja Problemas conhecidos no README).

## v3 e v4 — 19/11/2026
- Efeitos próprios de maximizar, minimizar e popups.
- Estilo do Plasma "Vidro" (painel e diálogos translúcidos).
- Widget de transparência no painel.
- Cor da barra de título automática conforme o papel de parede.

## v1 e v2 — 19/11/2026
- Decoração de janelas Vidro: vidro escuro, cantos arredondados, botões no estilo semáforo à esquerda.
- Transparência das janelas, fades e painel translúcido.
