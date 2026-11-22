"""Migration of ~/.config/vidrorc from the Portuguese names (up to v23) to English (v24+).
Called by vidro-config before reading the file; keeps a copy in vidrorc.pt-backup."""
import configparser, os, shutil

# old group: (new group, {old key: new key}, {new key: {old value: new value}})
GROUPS = {
    'Janelas': ('Windows', {'transparencia': 'opacity', 'barra': 'titlebar', 'cor_barra': 'titlebar_color'},
                {'titlebar': {'tema': 'theme', 'cor': 'custom'}}),
    'Botoes': ('Buttons', {'posicao': 'side', 'ordem': 'order', 'menu': 'menu', 'estilo': 'style', 'tamanho': 'size',
                           'espaco': 'spacing', 'inativos': 'inactive', 'cor': 'color_mode', 'cor_unica': 'single_color'},
               {'side': {'esquerda': 'left', 'direita': 'right'},
                'style': {'semaforo': 'traffic', 'simbolos': 'symbols', 'grafite': 'graphite', 'contorno': 'outline',
                          'icones': 'icons', 'quadrado': 'square'},
                'inactive': {'cinza': 'gray', 'cor': 'color'}, 'color_mode': {'semaforo': 'traffic', 'unica': 'single'}}),
    'Barra': ('Scrollbar', {'ativo': 'enabled', 'modo': 'mode', 'largura': 'width', 'opacidade': 'opacity',
                            'realce': 'highlight', 'arredondamento': 'roundness', 'trilho': 'track', 'cor': 'color',
                            'sobreposta': 'overlay', 'some': 'autohide', 'espera': 'delay', 'minima': 'min_opacity'},
              {'mode': {'vidro': 'glass', 'neon-fino': 'thin-neon', 'cor': 'color'}}),
    'Menus': ('Menus', {'ativo': 'enabled', 'raio': 'radius', 'opacidade': 'opacity', 'espaco': 'padding',
                        'separadores': 'separators', 'realce': 'highlight', 'cor_realce': 'highlight_color',
                        'fundo': 'background', 'cor_fundo': 'background_color', 'intensidade': 'intensity',
                        'borda': 'border', 'animacao': 'animation', 'entrada': 'open_ms', 'saida': 'close_ms',
                        'escala': 'scale', 'deslize': 'slide'},
              {'highlight': {'vidro': 'glass', 'destaque': 'accent', 'cor': 'custom'},
               'background': {'tema': 'theme', 'cor': 'custom'}}),
    'Lancador': ('Launcher', {'tipo': 'type', 'favoritos': 'favorites', 'aplicativos': 'applications', 'compacto': 'compact',
                              'lateral_direita': 'sidebar_right', 'passar_mouse': 'switch_on_hover', 'rodape': 'footer',
                              'legendas': 'captions', 'nomes': 'name_format', 'alfabetica': 'alphabetical',
                              'novos': 'highlight_new', 'icone': 'icon', 'texto': 'label'},
                 {'type': {'classico': 'classic', 'telacheia': 'fullscreen'}}),
    'MenuIniciar': ('Popups', {'ativo': 'enabled', 'raio': 'radius', 'fundo': 'background', 'cor_vidro': 'glass_color',
                               'opacidade': 'opacity', 'borda': 'border', 'linhas': 'lines', 'cabecalho': 'header',
                               'sombra': 'shadow', 'tamanho': 'shadow_size'},
                    {'background': {'tema': 'theme', 'cor': 'custom'}}),
    'Icones': ('Icons', {'ativo': 'enabled', 'modo': 'folder_mode', 'cor': 'folder_color', 'brilho': 'brightness',
                         'relevo': 'relief', 'saturacao': 'saturation', 'doc_estilo': 'file_style', 'doc_rotulo': 'file_label',
                         'doc_cores': 'file_colors', 'doc_cor': 'file_color', 'doc_dobra': 'file_fold', 'doc_raio': 'file_radius',
                         'lado_estilo': 'sidebar_style', 'lado_cor': 'sidebar_color', 'lado_traco': 'sidebar_stroke',
                         'lado_tamanho': 'sidebar_size'},
               {'folder_mode': {'escuro': 'dark', 'grafite': 'graphite', 'destaque': 'accent', 'cor': 'custom'},
                'file_style': {'escuro': 'dark', 'claro': 'light', 'colorido': 'colored', 'plano': 'flat'},
                'file_colors': {'tipo': 'type', 'unica': 'single', 'cinza': 'gray'},
                'sidebar_style': {'linha': 'line', 'preenchido': 'filled', 'colorido': 'colored'}}),
    'Cores': ('Colors', {'destaque': 'accent', 'cor_destaque': 'accent_color', 'forca': 'strength', 'fonte': 'text',
                         'cor_fonte': 'text_color', 'secundario': 'secondary'},
              {'accent': {'tema': 'theme', 'cor': 'custom'}, 'text': {'tema': 'theme', 'cor': 'custom'}}),
    'Painel': ('Panel', {'altura': 'height', 'flutuante': 'floating', 'opacidade': 'opacity', 'ocultar': 'hiding',
                         'largura': 'length', 'alinhamento': 'alignment', 'posicao': 'location',
                         'espaco_icones': 'icon_spacing', 'agrupar': 'grouping', 'so_area_atual': 'current_desktop_only',
                         'so_tela_atual': 'current_screen_only', 'audio': 'audio_indicator', 'dicas': 'tooltips',
                         'efeito_mouse': 'hover_effect', 'destacar_janelas': 'highlight_windows', 'clique_meio': 'middle_click',
                         'linhas': 'rows', 'segundos': 'clock_seconds', 'data': 'clock_date', 'formato_data': 'date_format',
                         'data_personalizada': 'custom_date', 'posicao_data': 'date_position', 'horas': 'hour_format',
                         'negrito': 'clock_bold', 'fonte_auto': 'clock_auto_font', 'tamanho_fonte': 'clock_font_size',
                         'vidro_ativo': 'glass_enabled', 'vidro_raio': 'glass_radius', 'vidro_opacidade': 'glass_opacity',
                         'vidro_contorno': 'glass_border', 'vidro_sombra': 'glass_shadow', 'vidro_fundo': 'glass_background',
                         'vidro_cor': 'glass_color'},
               {'glass_background': {'tema': 'theme', 'cor': 'custom'}}),
    'Pastas': ('Dolphin', {'ativo': 'enabled', 'linhas': 'separators', 'unificar': 'unify', 'cor': 'background',
                           'cor_fundo': 'background_color', 'escuro': 'darken', 'espaco': 'spacing'},
               {'background': {'cor': 'custom'}}),
    'Claro': ('Light', {'ativo': 'enabled', 'vidro': 'glass'}, {}),
    'EditorKden': ('EditorKden', {'ativo': 'enabled', 'cor': 'accent', 'fundo': 'darkness', 'contraste': 'contrast',
                                  'arredondamento': 'radius', 'fonte': 'font_size', 'titulos': 'dock_titles',
                                  'boasvindas': 'welcome', 'estilo': 'style', 'rotulos': 'toolbar_labels',
                                  'menu': 'menubar', 'status': 'statusbar', 'clips': 'clips', 'onda': 'waveform',
                                  'monitor': 'monitor'},
                   {'style': {'pilula': 'pill', 'padrao': 'default'}, 'clips': {'suaves': 'soft', 'destaque': 'accent', 'tema': 'theme'},
                    'waveform': {'padrao': 'default', 'destaque': 'accent'}, 'monitor': {'grafite': 'graphite', 'preto': 'black'}}),
    'Login': ('Login', {'fundo': 'background', 'arquivo': 'file', 'cor_fundo': 'background_color', 'desfoque': 'blur',
                        'forca': 'blur_strength', 'escurecer': 'dim', 'relogio': 'clock_format', 'segundos': 'clock_seconds',
                        'tamanho': 'clock_size', 'peso': 'clock_weight', 'data': 'show_date', 'mostrar_relogio': 'show_clock',
                        'destaque': 'accent', 'vidro': 'glass', 'posicao': 'layout', 'avatar': 'avatar',
                        'forma_avatar': 'avatar_shape', 'fonte': 'font'},
              {'background': {'papel': 'wallpaper', 'arquivo': 'file', 'cor': 'color'},
               'layout': {'centro': 'center', 'esquerda': 'left'}, 'avatar_shape': {'circulo': 'circle', 'quadrado': 'square'}}),
    'Cursor': ('Cursor', {'ativo': 'enabled', 'forma': 'shape', 'fundo': 'fill', 'contorno': 'outline', 'destaque': 'accent',
                          'borda': 'outline_width', 'cantos': 'roundness', 'sombra': 'shadow', 'tamanho': 'size'},
               {'shape': {'classica': 'classic', 'moderna': 'modern', 'minima': 'minimal', 'triangulo': 'triangle'}}),
}


def migrate(path):
    """Rewrite `path` with English names if it still has Portuguese groups. Returns True if it changed."""
    old = configparser.RawConfigParser(); old.optionxform = str
    old.read(path)
    if not any(g in GROUPS and (g != GROUPS[g][0] or any(k in GROUPS[g][1] and GROUPS[g][1][k] != k for k in old[g]))
               for g in old.sections()):
        return False
    shutil.copy2(path, path + '.pt-backup')
    new = configparser.RawConfigParser(); new.optionxform = str
    for g in old.sections():
        ng, keys, values = GROUPS.get(g, (g, {}, {}))
        if not new.has_section(ng):
            new.add_section(ng)
        for k, v in old[g].items():
            nk = keys.get(k, k)
            new.set(ng, nk, values.get(nk, {}).get(v, v))
    tmp = path + '.tmp'
    with open(tmp, 'w') as f:
        new.write(f)
    os.replace(tmp, path)
    return True
