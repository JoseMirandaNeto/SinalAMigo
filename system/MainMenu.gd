extends Control
class_name MainMenu

var _btn_jogar: Button
var _btn_config: Button
var _logo: Label
var _sinalito: TextureRect

var _popup_layer: CanvasLayer
var _nome_input: LineEdit
var _btn_confirmar: Button
var _safe_container: MarginContainer

const SAVE_PATH = "user://savegame.json"

func _ready() -> void:
	_btn_jogar = get_node_or_null("SafeContainer/MainLayout/ContentLayout/LeftSection/RecomendadaCard/VBox/Content/Right/HBoxBtn/BtnIniciar") as Button
	_btn_config = get_node_or_null("SafeContainer/MainLayout/Header/BtnMenu") as Button
	_safe_container = get_node_or_null("SafeContainer") as MarginContainer

	if _btn_jogar: _btn_jogar.pressed.connect(_on_btn_jogar_pressed)
	if _btn_config: _btn_config.pressed.connect(_on_btn_config_pressed)

	print("MainMenu: Interface de Libras carregada com sucesso!")

	_logo = get_node_or_null("SafeContainer/MainLayout/Header/Title") as Label
	_sinalito = get_node_or_null("SafeContainer/MainLayout/Header/Mascot") as TextureRect

	if _logo:
		_logo.modulate = Color(1, 1, 1, 0)
		var fade_tween = create_tween().bind_node(self)
		fade_tween.tween_property(_logo, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	if _sinalito:
		_sinalito.modulate = Color(1, 1, 1, 0)
		var fade_mascote = create_tween().bind_node(self)
		fade_mascote.tween_property(_sinalito, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.5)

	verificar_nome_jogador()

func verificar_nome_jogador() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("MainMenu: Nenhum save encontrado, exibindo popup.")
		mostrar_popup_nome()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		print("MainMenu: Erro ao ler save, exibindo popup.")
		mostrar_popup_nome()
		return

	var json_string = file.get_as_text()
	var json = JSON.new()

	if json.parse(json_string) != OK:
		print("MainMenu: JSON inválido, exibindo popup.")
		mostrar_popup_nome()
		return

	var data = json.data as Dictionary
	var nome_salvado = str(data.get("NomeJogador", ""))

	if nome_salvado != "" and nome_salvado != "José":
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			game_manager.nome_jogador = nome_salvado
		var save_manager = get_node_or_null("/root/SaveManager")
		if save_manager:
			save_manager.carregar_jogo()
		atualizar_stats_interface()
		print("MainMenu: Nome '%s' carregado do save." % nome_salvado)
		return

	print("MainMenu: Nome padrão no save, exibindo popup.")
	mostrar_popup_nome()

func mostrar_popup_nome() -> void:
	_popup_layer = get_node_or_null("PopupLayer") as CanvasLayer
	_nome_input = get_node_or_null("PopupLayer/PopupContainer/PopupPanel/Margin/PopupLayout/NomeInput") as LineEdit
	_btn_confirmar = get_node_or_null("PopupLayer/PopupContainer/PopupPanel/Margin/PopupLayout/BtnConfirmar") as Button
	var overlay = get_node_or_null("PopupLayer/Overlay") as ColorRect
	var popup_panel = get_node_or_null("PopupLayer/PopupContainer/PopupPanel") as PanelContainer

	if _popup_layer:
		_popup_layer.visible = true

	if _safe_container:
		_safe_container.visible = false

	if overlay:
		overlay.color = Color(0, 0, 0, 0)
		var tween = create_tween().bind_node(self)
		tween.tween_property(overlay, "color", Color(0, 0, 0, 0.5), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if popup_panel:
		popup_panel.modulate = Color(1, 1, 1, 0)
		popup_panel.scale = Vector2(0.8, 0.8)
		popup_panel.pivot_offset = popup_panel.size / 2.0
		var tween_panel = create_tween().bind_node(self)
		tween_panel.tween_property(popup_panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween_panel.parallel().tween_property(popup_panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _nome_input:
		_nome_input.text = ""
		_nome_input.grab_focus()

	if _btn_confirmar and not _btn_confirmar.pressed.is_connected(_on_btn_confirmar_pressed):
		_btn_confirmar.pressed.connect(_on_btn_confirmar_pressed)

func _on_btn_confirmar_pressed() -> void:
	if _nome_input == null: return

	var nome = _nome_input.text.strip_edges()
	if nome == "":
		_nome_input.placeholder_text = "Por favor, digite um nome!"
		return

	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.nome_jogador = nome

	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager:
		save_manager.salvar_jogo()

	var overlay = get_node_or_null("PopupLayer/Overlay") as ColorRect
	var popup_panel = get_node_or_null("PopupLayer/PopupContainer/PopupPanel") as PanelContainer

	var tween = create_tween().bind_node(self)
	if popup_panel:
		tween.tween_property(popup_panel, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(popup_panel, "scale", Vector2(0.8, 0.8), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if overlay:
		tween.parallel().tween_property(overlay, "color", Color(0, 0, 0, 0), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween.tween_callback(func():
		if _popup_layer:
			_popup_layer.visible = false
		if _safe_container:
			_safe_container.visible = true
	)

	atualizar_stats_interface()
	print("MainMenu: Nome do jogador definido como '%s'" % nome)

func atualizar_stats_interface() -> void:
	var label_name = get_node_or_null("SafeContainer/MainLayout/ContentLayout/LeftSection/ProfileCard/Right/PlayerName") as Label
	var label_level = get_node_or_null("SafeContainer/MainLayout/ContentLayout/LeftSection/ProfileCard/Left/LvlCapsule/LevelLabel") as Label
	var exp_bar = get_node_or_null("SafeContainer/MainLayout/ContentLayout/LeftSection/ProfileCard/Right/XPContainer/XPBar") as ProgressBar
	var xp_info = get_node_or_null("SafeContainer/MainLayout/ContentLayout/LeftSection/ProfileCard/Right/XPContainer/XPInfo") as Label

	var game_manager = get_node_or_null("/root/GameManager")
	var level_manager = get_node_or_null("/root/LevelManager")

	if game_manager != null and level_manager != null:
		var total_xp = level_manager.pontuacao_total
		var player_level = (total_xp / 500) + 4
		var current_level_xp = total_xp % 500

		game_manager.nivel_jogador = player_level
		game_manager.exp_jogador = current_level_xp

		if label_name:
			label_name.text = "Olá, " + game_manager.nome_jogador + "!"
		if label_level:
			label_level.text = "Lvl " + str(player_level)
		if exp_bar:
			exp_bar.value = (float(current_level_xp) / 500.0) * 100.0
		if xp_info:
			xp_info.text = str(current_level_xp) + " / 500 XP"

func _on_btn_jogar_pressed() -> void:
	var scene_path = "res://scenes/game_mode_selection.tscn"
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		printerr("MainMenu: Erro ao trocar cena para %s: %d" % [scene_path, error])
	else:
		print("MainMenu: Redirecionando para seleção de modo...")

func _on_btn_config_pressed() -> void:
	print("MainMenu: Abrindo configurações (Não implementado)...")
