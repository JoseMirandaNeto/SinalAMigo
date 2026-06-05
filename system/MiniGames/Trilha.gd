extends Node2D
class_name Trilha

var _casas_container: Node2D
var _pontuacao_label: Label
var _streak_label: Label
var _progress_bar: ProgressBar
var _player_sprite: Sprite2D
var _caminho_linha: Line2D
var _caminho_linha_borda: Line2D
var _camera: Camera2D
var _btn_voltar: Button
var _btn_comecar: Button

var _fase_foco_numero: int = 1

func _ready() -> void:
	_casas_container = get_node_or_null("CasasContainer") as Node2D
	
	_pontuacao_label = get_node_or_null("CanvasUI/SafeContainer/MainLayout/HeaderPanel/Margin/Header/XPLabel") as Label
	_streak_label = get_node_or_null("CanvasUI/SafeContainer/MainLayout/HeaderPanel/Margin/Header/StreakLabel") as Label
	_progress_bar = get_node_or_null("CanvasUI/SafeContainer/MainLayout/ProgressBar") as ProgressBar
	
	_btn_voltar = get_node_or_null("CanvasUI/SafeContainer/MainLayout/HeaderPanel/Margin/Header/BtnVoltar") as Button
	if _btn_voltar:
		_btn_voltar.pressed.connect(_on_btn_voltar_pressed)

	_btn_comecar = get_node_or_null("CanvasUI/SafeContainer/MainLayout/BottomPanel/Margin/BtnComecar") as Button
	if _btn_comecar:
		_btn_comecar.pressed.connect(_on_btn_comecar_pressed)

	criar_camera_seguidora()

	if has_node("Caminho/PlayerFollow/PlayerSprite"):
		_player_sprite = get_node("Caminho/PlayerFollow/PlayerSprite") as Sprite2D
	elif has_node("PlayerSprite"):
		_player_sprite = get_node("PlayerSprite") as Sprite2D

	configurar_player_sprite()
	criar_linha_conexao()
	atualizar_trilha()

func criar_camera_seguidora() -> void:
	_camera = Camera2D.new()
	_camera.name = "CameraTrilha"
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 4.0
	add_child(_camera)

func configurar_player_sprite() -> void:
	if _player_sprite == null: return

	if _player_sprite.texture == null:
		var texture = load("res://ui/hud/Sinalito-avatar.png") as Texture2D
		if texture:
			_player_sprite.texture = texture
			var scale_val = 64.0 / texture.get_size().x
			_player_sprite.scale = Vector2(scale_val, scale_val)
			_player_sprite.offset = Vector2(0, -20)
			_player_sprite.z_index = 5 

func criar_linha_conexao() -> void:
	if has_node("LinhaTrilhaBorda"): get_node("LinhaTrilhaBorda").queue_free()
	if has_node("LinhaTrilha"): get_node("LinhaTrilha").queue_free()

	_caminho_linha_borda = Line2D.new()
	_caminho_linha_borda.name = "LinhaTrilhaBorda"
	_caminho_linha_borda.width = 32.0
	_caminho_linha_borda.default_color = Color("#1c75f0")
	_caminho_linha_borda.z_index = -2
	_caminho_linha_borda.joint_mode = Line2D.LINE_JOINT_ROUND
	_caminho_linha_borda.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_caminho_linha_borda.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_caminho_linha_borda)

	_caminho_linha = Line2D.new()
	_caminho_linha.name = "LinhaTrilha"
	_caminho_linha.width = 20.0
	_caminho_linha.default_color = Color("#ffffff")
	_caminho_linha.z_index = -1
	_caminho_linha.joint_mode = Line2D.LINE_JOINT_ROUND
	_caminho_linha.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_caminho_linha.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_caminho_linha)

func reposicionar_casas_automaticamente(casas: Array) -> void:
	var start_x = 260.0
	var start_y = 480.0
	var dx = 320.0
	var dy = 200.0
	var colunas = 3

	for i in range(casas.size()):
		var row = i / colunas
		var col = i % colunas

		if row % 2 == 1:
			col = (colunas - 1) - col

		var local_pos = Vector2(start_x + col * dx, start_y - row * dy)
		casas[i].position = local_pos

func atualizar_trilha() -> void:
	if _casas_container == null: return

	var level_manager = get_node_or_null("/root/LevelManager")
	var nivel_liberado = level_manager.nivel_atual if level_manager else 1

	if _pontuacao_label and level_manager:
		_pontuacao_label.text = "XP: " + str(level_manager.pontuacao_total)

	if _progress_bar and level_manager:
		var pct_progresso = clampf(float(nivel_liberado - 1) / 13.0 * 100.0, 0.0, 100.0)
		_progress_bar.value = pct_progresso

	var casas: Array = []
	var index = 1
	
	for filho in _casas_container.get_children():
		if filho is CasaTrilha:
			filho.numero_fase = index
			casas.append(filho)
			index += 1

	casas.sort_custom(func(a, b): return a.numero_fase < b.numero_fase)

	reposicionar_casas_automaticamente(casas)

	_caminho_linha.clear_points()
	_caminho_linha_borda.clear_points()
	var casa_foco: CasaTrilha = null

	for casa in casas:
		if not casa.is_connected("casa_pressionada", _on_casa_pressionada):
			casa.casa_pressionada.connect(_on_casa_pressionada)

		if casa.numero_fase < nivel_liberado:
			casa.definir_estado(CasaTrilha.EstadoCasa.COMPLETADA)
		elif casa.numero_fase == nivel_liberado:
			casa.definir_estado(CasaTrilha.EstadoCasa.LIBERADA)
			casa_foco = casa
			_fase_foco_numero = casa.numero_fase
		else:
			casa.definir_estado(CasaTrilha.EstadoCasa.BLOQUEADA)

		var local_pos_borda = _caminho_linha_borda.to_local(casa.global_position)
		_caminho_linha_borda.add_point(local_pos_borda)

		var local_pos_pista = _caminho_linha.to_local(casa.global_position)
		_caminho_linha.add_point(local_pos_pista)

	if casa_foco == null and casas.size() > 0:
		casa_foco = casas.back()
		_fase_foco_numero = casa_foco.numero_fase

	if casa_foco != null:
		if _camera != null:
			_camera.global_position = casa_foco.global_position

		if _player_sprite != null:
			var parent = _player_sprite.get_parent()
			if parent is PathFollow2D:
				_player_sprite.reparent(self)
				parent.queue_free()
			
			var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(_player_sprite, "global_position", casa_foco.global_position, 1.0)

func _on_casa_pressionada(numero_fase: int) -> void:
	iniciar_fase(numero_fase)

func _on_btn_comecar_pressed() -> void:
	iniciar_fase(_fase_foco_numero)

func iniciar_fase(numero_fase: int) -> void:
	print("Trilha: Iniciando lição da fase %d..." % numero_fase)
	
	var level_manager = get_node_or_null("/root/LevelManager")
	if level_manager:
		level_manager.carregar_fase(numero_fase)
	else:
		printerr("Trilha: LevelManager Autoload não encontrado!")

func _on_btn_voltar_pressed() -> void:
	var mode_selection_path = "res://scenes/game_mode_selection.tscn"
	var error = get_tree().change_scene_to_file(mode_selection_path)
	if error != OK:
		printerr("Trilha: Erro ao retornar para selecao de modo %s: %d" % [mode_selection_path, error])
