extends Node2D
class_name Trilha

var _casas_container: Node2D
var _btn_menu: Button
var _user_label: Label
var _level_label: Label
var _modulo_titulo: Label
var _progress_bg: PanelContainer
var _progress_fill: PanelContainer
var _posicionado: bool = false

const _licoes: Array = [
	{"nome": "SAUDAÇÕES", "descricao": "Aprenda saudações básicas em Libras", "fases_por_licao": 12},
	{"nome": "ALFABETO", "descricao": "Aprenda as letras do alfabeto em Libras", "fases_por_licao": 12},
	{"nome": "NÚMEROS", "descricao": "Aprenda os números em Libras", "fases_por_licao": 12},
]

func _ready() -> void:
	_casas_container = get_node_or_null("CasasContainer") as Node2D

	_btn_menu = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header/BtnMenu") as Button
	if _btn_menu:
		_btn_menu.pressed.connect(voltar_menu)

	_user_label = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header/BadgeCenter/UserBadge/HB/VBox/NomeLabel") as Label
	_level_label = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header/BadgeCenter/UserBadge/HB/VBox/LevelRow/LevelLabel") as Label
	_modulo_titulo = get_node_or_null("CanvasUI/SafeContainer/MainLayout/ModuloLabel") as Label
	_progress_bg = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header/BadgeCenter/UserBadge/HB/VBox/LevelRow/ProgressBg") as PanelContainer
	_progress_fill = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header/BadgeCenter/UserBadge/HB/VBox/LevelRow/ProgressBg/ProgressFill") as PanelContainer

	_ajustar_para_android()
	criar_linha_conexao()
	atualizar_trilha()

	# Configura filtros de mouse para permitir que cliques passem da camada de UI (CanvasLayer) para o mundo 2D
	var safe_container = get_node_or_null("CanvasUI/SafeContainer") as Control
	if safe_container:
		safe_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var main_layout = get_node_or_null("CanvasUI/SafeContainer/MainLayout") as Control
	if main_layout:
		main_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	var spacer = get_node_or_null("CanvasUI/SafeContainer/MainLayout/SpacerMiddle") as Control
	if spacer:
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var level_manager = get_node_or_null("/root/LevelManager")
	if level_manager:
		if not level_manager.save_carregado.is_connected(_on_save_carregado):
			level_manager.save_carregado.connect(_on_save_carregado)

func _process(_delta: float) -> void:
	if not _posicionado and _modulo_titulo and _modulo_titulo.visible and _modulo_titulo.global_position.y > 0:
		_posicionado = true
		reposicionar_casas_do_array()

var _casas_cache: Array = []

func _ajustar_para_android() -> void:
	if _btn_menu:
		_btn_menu.size = Vector2(56, 56)
		_btn_menu.add_theme_font_size_override("font_size", 30)

	var header = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header") as Control
	if header:
		header.custom_minimum_size = Vector2(0, 90)

	var badge = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header/BadgeCenter/UserBadge") as PanelContainer
	if badge:
		badge.custom_minimum_size = Vector2(320, 90)

	var avatar = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header/BadgeCenter/UserBadge/HB/Avatar") as TextureRect
	if avatar:
		avatar.custom_minimum_size = Vector2(64, 64)

	var hb = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header/BadgeCenter/UserBadge/HB") as HBoxContainer
	if hb:
		hb.add_theme_constant_override("separation", 16)

	var progress_bg = get_node_or_null("CanvasUI/SafeContainer/MainLayout/Header/BadgeCenter/UserBadge/HB/VBox/LevelRow/ProgressBg") as PanelContainer
	if progress_bg:
		progress_bg.custom_minimum_size = Vector2(120, 18)

	if _user_label:
		_user_label.add_theme_font_size_override("font_size", 28)
	if _level_label:
		_level_label.add_theme_font_size_override("font_size", 22)

func atualizar_barra_progresso(fase_atual: int, total_fases: int) -> void:
	if not _progress_bg or not _progress_fill:
		return
	var pct: float = float(fase_atual) / float(total_fases)
	_progress_fill.anchor_right = pct
	_progress_fill.visible = pct > 0.0

func criar_linha_conexao() -> void:
	for child in get_children():
		if child is Line2D:
			child.queue_free()

	var linha = Line2D.new()
	linha.name = "LinhaTrilha"
	linha.width = 12.0
	linha.default_color = Color("#5F81FF")
	linha.z_index = -1
	linha.joint_mode = Line2D.LINE_JOINT_ROUND
	linha.begin_cap_mode = Line2D.LINE_CAP_ROUND
	linha.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(linha)

func reposicionar_casas_do_array() -> void:
	if _casas_cache.size() == 0: return
	reposicionar_casas(_casas_cache)

func reposicionar_casas(casas: Array) -> void:
	var colunas = 3
	var espaco_x = 200.0
	var espaco_y = 160.0
	var grid_width = (colunas - 1) * espaco_x
	var start_x = (get_viewport_rect().size.x - grid_width) / 2.0
	var start_y = 140.0

	if _modulo_titulo and _modulo_titulo.visible and _modulo_titulo.size.y > 0:
		start_y = _modulo_titulo.global_position.y + _modulo_titulo.size.y + 10.0 + 55.0
		var content_center = _modulo_titulo.global_position.x + _modulo_titulo.size.x / 2.0
		start_x = content_center - grid_width / 2.0

	for i in range(casas.size()):
		var row = i / colunas
		var col = i % colunas
		var x: float
		if row % 2 == 0:
			x = start_x + col * espaco_x
		else:
			x = start_x + (colunas - 1 - col) * espaco_x
		var y = start_y + row * espaco_y
		casas[i].position = Vector2(x, y)

	var linha = get_node_or_null("LinhaTrilha") as Line2D
	if linha:
		linha.clear_points()
		for casa in casas:
			var pt = linha.to_local(casa.global_position)
			linha.add_point(pt)

func atualizar_trilha() -> void:
	if _casas_container == null: return

	var level_manager = get_node_or_null("/root/LevelManager")
	var game_manager = get_node_or_null("/root/GameManager")
	var nivel_liberado = level_manager.nivel_atual if level_manager else 1

	if _user_label and game_manager:
		_user_label.text = "Olá, " + game_manager.nome_jogador + "!"
	if _level_label and game_manager:
		_level_label.text = "LVL " + str(game_manager.nivel_jogador)

	if _modulo_titulo:
		var licao_info = obter_licao_da_fase(nivel_liberado)
		_modulo_titulo.text = "MÓDULO " + str(licao_info.indice + 1) + ": " + licao_info.nome.to_upper()
		atualizar_barra_progresso(licao_info.fase_na_licao, licao_info.total_fases)

	var casas: Array = []
	var index = 1
	for filho in _casas_container.get_children():
		if filho.has_method("definir_estado"):
			filho.numero_fase = index
			filho.atualizar_texto_label()
			casas.append(filho)
			index += 1

	casas.sort_custom(func(a, b): return a.numero_fase < b.numero_fase)
	_casas_cache = casas

	for casa in casas:
		if not casa.is_connected("casa_pressionada", _on_casa_pressionada):
			casa.casa_pressionada.connect(_on_casa_pressionada)

		if casa.numero_fase < nivel_liberado:
			casa.definir_estado(CasaTrilha.EstadoCasa.COMPLETADA)
		elif casa.numero_fase == nivel_liberado:
			casa.definir_estado(CasaTrilha.EstadoCasa.LIBERADA)
		else:
			casa.definir_estado(CasaTrilha.EstadoCasa.BLOQUEADA)

func _on_casa_pressionada(numero_fase: int) -> void:
	iniciar_fase(numero_fase)

func _on_save_carregado() -> void:
	atualizar_trilha()

func iniciar_fase(numero_fase: int) -> void:
	# Define origem como "trilha" para saber para onde voltar
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.minigame_origem = "trilha"
	
	var level_manager = get_node_or_null("/root/LevelManager")
	if level_manager:
		level_manager.carregar_fase(numero_fase)

func voltar_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/game_mode_selection.tscn")

func obter_licao_da_fase(numero_fase: int) -> Dictionary:
	var fases_acumuladas := 0
	for i in range(_licoes.size()):
		var licao = _licoes[i]
		var fases_por_licao = licao.fases_por_licao
		var inicio = fases_acumuladas + 1
		var fim = fases_acumuladas + fases_por_licao
		if numero_fase >= inicio and numero_fase <= fim:
			return {
				"indice": i,
				"nome": licao.nome,
				"descricao": licao.descricao,
				"fases_por_licao": fases_por_licao,
				"fase_na_licao": numero_fase - fases_acumuladas,
				"total_fases": fases_por_licao,
			}
		fases_acumuladas += fases_por_licao
	return {"indice": 0, "nome": _licoes[0].nome, "descricao": _licoes[0].descricao, "fases_por_licao": 3, "fase_na_licao": 1, "total_fases": 3}
