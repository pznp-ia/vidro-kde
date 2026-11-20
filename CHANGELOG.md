# Mudanças

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
