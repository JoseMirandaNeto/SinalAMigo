extends Control
class_name MainMenu

var _btn_jogar: Button
var _btn_config: Button
var _logo: Label

func _ready() -> void:
	_btn_jogar = get_node_or_null("SafeContainer/MainLayout/CenterLayout/ButtonsContainer/BtnJogar") as Button
	_btn_config = get_node_or_null("SafeContainer/MainLayout/CenterLayout/ButtonsContainer/BtnConfig") as Button
	
	if _btn_jogar: _btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	if _btn_config: _btn_config.pressed.connect(_on_btn_config_pressed)
	
	print("MainMenu: Interface de Libras carregada com sucesso!")
	
	_logo = get_node_or_null("SafeContainer/MainLayout/CenterLayout/LogoContainer/Logo") as Label

	if _logo:
		_logo.modulate = Color(1, 1, 1, 0)
		var fade_tween = create_tween().bind_node(self)
		fade_tween.tween_property(_logo, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	atualizar_stats_interface()

func atualizar_stats_interface() -> void:
	var label_name = get_node_or_null("SafeContainer/MainLayout/HeaderPanel/Margin/Header/PlayerStats/PlayerName") as Label
	var label_level = get_node_or_null("SafeContainer/MainLayout/HeaderPanel/Margin/Header/PlayerStats/LevelInfo/LevelLabel") as Label
	var exp_bar = get_node_or_null("SafeContainer/MainLayout/HeaderPanel/Margin/Header/PlayerStats/LevelInfo/ExperienceBar") as ProgressBar

	var game_manager = get_node_or_null("/root/GameManager")
	var level_manager = get_node_or_null("/root/LevelManager")

	if game_manager != null and level_manager != null:
		var total_xp = level_manager.pontuacao_total
		var player_level = (total_xp / 500) + 1
		var current_level_xp = total_xp % 500

		game_manager.nivel_jogador = player_level
		game_manager.exp_jogador = current_level_xp

		if label_name:
			label_name.text = "Olá, " + game_manager.nome_jogador
		if label_level:
			label_level.text = "Nível " + str(player_level)
		if exp_bar:
			exp_bar.value = (float(current_level_xp) / 500.0) * 100.0

func _on_btn_jogar_pressed() -> void:
	var scene_path = "res://scenes/game_mode_selection.tscn"
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		printerr("MainMenu: Erro ao trocar cena para %s: %d" % [scene_path, error])
	else:
		print("MainMenu: Redirecionando para seleção de modo...")

func _on_btn_config_pressed() -> void:
	print("MainMenu: Abrindo configurações (Não implementado)...")
