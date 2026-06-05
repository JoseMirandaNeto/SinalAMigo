extends Control
class_name Soletra

var _word_container: HBoxContainer
var _keyboard_grid: GridContainer
var _instruction_label: Label
var _title_label: Label
var _btn_voltar: Button

var _palavras_db: Array[String] = [
	"LIBRAS", "AMIGO", "SINAL", "AMOR", "OI", 
	"BOM", "DIA", "LICAO", "PARABENS", "ESTUDAR" 
]

var _palavra_alvo: String = ""
var _letra_atual_index: int = 0
var _fase_numero: int = 1

var _letter_boxes: Array[PanelContainer] = []
var _atlas_textura_completa: Texture2D

func _ready() -> void:
	_word_container = get_node_or_null("SafeContainer/MainLayout/WordArea/WordContainer") as HBoxContainer
	_keyboard_grid = get_node_or_null("SafeContainer/MainLayout/KeyboardArea/KeyboardGrid") as GridContainer
	_instruction_label = get_node_or_null("SafeContainer/MainLayout/InstructionLabel") as Label
	_title_label = get_node_or_null("SafeContainer/MainLayout/HeaderPanel/Margin/Header/TitleLabel") as Label
	_btn_voltar = get_node_or_null("SafeContainer/MainLayout/HeaderPanel/Margin/Header/BtnVoltar") as Button

	if _btn_voltar:
		_btn_voltar.pressed.connect(_on_btn_voltar_pressed)

	_atlas_textura_completa = load("res://ui/palavras/alfabeto.png") as Texture2D

	var level_manager = get_node_or_null("/root/LevelManager")
	if level_manager:
		_fase_numero = level_manager.nivel_atual

	_palavra_alvo = _palavras_db[(_fase_numero - 1) % _palavras_db.size()].to_upper()
	_letra_atual_index = 0

	if _title_label:
		_title_label.text = "PALAVRA %d" % _fase_numero

	atualizar_instrucao()
	gerar_caixas_palavra()
	gerar_teclado_visual()

func atualizar_instrucao() -> void:
	if _instruction_label and _letra_atual_index < _palavra_alvo.length():
		var letra_esperada = _palavra_alvo[_letra_atual_index]
		_instruction_label.text = "Clique sobre os sinais do alfabeto manual para traduzir a palavra acima, começando pela letra (%s):" % letra_esperada

func gerar_caixas_palavra() -> void:
	if not _word_container: return
	for child in _word_container.get_children():
		child.queue_free()
	_letter_boxes.clear()

	var estilo_escuro = StyleBoxFlat.new()
	estilo_escuro.bg_color = Color("#2c2c2c")
	estilo_escuro.corner_radius_top_left = 12
	estilo_escuro.corner_radius_top_right = 12
	estilo_escuro.corner_radius_bottom_left = 12
	estilo_escuro.corner_radius_bottom_right = 12
	estilo_escuro.border_width_bottom = 4
	estilo_escuro.border_color = Color("#1e1e1e")

	for i in range(_palavra_alvo.length()):
		var letra = _palavra_alvo[i]
		
		var box = PanelContainer.new()
		box.custom_minimum_size = Vector2(90, 90)
		box.add_theme_stylebox_override("panel", estilo_escuro)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		box.add_child(margin)

		var label = Label.new()
		label.text = letra
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 36)
		label.name = "LetraLabel"
		margin.add_child(label)

		var texture_rect = TextureRect.new()
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.visible = false
		texture_rect.name = "SinalImage"
		margin.add_child(texture_rect)

		_word_container.add_child(box)
		_letter_boxes.append(box)

func gerar_teclado_visual() -> void:
	if not _keyboard_grid: return
	for child in _keyboard_grid.get_children():
		child.queue_free()

	var estilo_botao = StyleBoxFlat.new()
	estilo_botao.bg_color = Color("#1e1e2d")
	estilo_botao.corner_radius_top_left = 8
	estilo_botao.corner_radius_top_right = 8
	estilo_botao.corner_radius_bottom_left = 8
	estilo_botao.corner_radius_bottom_right = 8
	estilo_botao.border_width_bottom = 3
	estilo_botao.border_color = Color("#0f0f15")

	for i in range(65, 91):
		var letra_teclado = char(i)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.add_theme_stylebox_override("normal", estilo_botao)
		btn.add_theme_stylebox_override("hover", estilo_botao)
		
		if _atlas_textura_completa:
			var atlas = slicar_mao_do_teclado(letra_teclado)
			if atlas:
				btn.icon = atlas
				btn.expand_icon = true
		else:
			btn.text = letra_teclado

		btn.pressed.connect(func(): _on_tecla_teclado_pressionada(letra_teclado, btn))
		_keyboard_grid.add_child(btn)

func slicar_mao_do_teclado(letra: String) -> AtlasTexture:
	var index = letra.to_upper().unicode_at(0) - 65
	if index < 0 or index >= 26: return null

	var col = index % 5
	var row = index / 5
	
	var cell_w = 250.8
	var cell_h = 209.0

	var atlas = AtlasTexture.new()
	atlas.atlas = _atlas_textura_completa
	atlas.region = Rect2(col * cell_w + 110, row * cell_h, cell_w - 110, cell_h)
	return atlas

func slicar_carta_completa(letra: String) -> AtlasTexture:
	var index = letra.to_upper().unicode_at(0) - 65
	if index < 0 or index >= 26: return null

	var col = index % 5
	var row = index / 5
	
	var cell_w = 250.8
	var cell_h = 209.0

	var atlas = AtlasTexture.new()
	atlas.atlas = _atlas_textura_completa
	atlas.region = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)
	return atlas

func _on_tecla_teclado_pressionada(letra_clicada: String, botao: Button) -> void:
	if _letra_atual_index >= _palavra_alvo.length(): return

	var letra_esperada = _palavra_alvo[_letra_atual_index]

	if letra_clicada == letra_esperada:
		revelar_letra_atual()
		_letra_atual_index += 1

		if _letra_atual_index >= _palavra_alvo.length():
			concluir_minigame()
		else:
			atualizar_instrucao()
	else:
		animar_erro(botao)

func revelar_letra_atual() -> void:
	if _letra_atual_index >= _letter_boxes.size(): return

	var box = _letter_boxes[_letra_atual_index]
	
	var estilo_verde = StyleBoxFlat.new()
	estilo_verde.bg_color = Color("#8dc63f")
	estilo_verde.corner_radius_top_left = 12
	estilo_verde.corner_radius_top_right = 12
	estilo_verde.corner_radius_bottom_left = 12
	estilo_verde.corner_radius_bottom_right = 12
	estilo_verde.border_width_bottom = 4
	estilo_verde.border_color = Color("#6ea12a")
	box.add_theme_stylebox_override("panel", estilo_verde)

	var label = box.get_node_or_null("MarginContainer/LetraLabel") as Label
	if label:
		label.visible = false

	var texture_rect = box.get_node_or_null("MarginContainer/SinalImage") as TextureRect
	if texture_rect:
		var letra = _palavra_alvo[_letra_atual_index]
		texture_rect.texture = slicar_carta_completa(letra)
		texture_rect.visible = true

	box.pivot_offset = box.custom_minimum_size / 2.0
	var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(box, "scale", Vector2(1.15, 1.15), 0.1)
	tween.tween_property(box, "scale", Vector2(1.0, 1.0), 0.15)

func animar_erro(btn: Button) -> void:
	btn.pivot_offset = btn.custom_minimum_size / 2.0
	var original_pos = btn.position

	var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(btn, "position:x", original_pos.x - 8, 0.05)
	tween.tween_property(btn, "position:x", original_pos.x + 8, 0.05)
	tween.tween_property(btn, "position:x", original_pos.x - 4, 0.05)
	tween.tween_property(btn, "position:x", original_pos.x, 0.05)

func concluir_minigame() -> void:
	if _instruction_label:
		_instruction_label.text = "Excelente! Você traduziu a palavra com sucesso!"
		_instruction_label.add_theme_color_override("font_color", Color("#8dc63f"))

	for i in range(_letter_boxes.size()):
		var box = _letter_boxes[i]
		box.pivot_offset = box.custom_minimum_size / 2.0
		
		var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_interval(i * 0.05)
		tween.tween_property(box, "position:y", box.position.y - 15, 0.15)
		tween.tween_property(box, "position:y", box.position.y, 0.15)

	await get_tree().create_timer(1.5).timeout

	var level_manager = get_node_or_null("/root/LevelManager")
	if level_manager:
		level_manager.completar_fase_atual()
		level_manager.voltar_para_trilha()
	else:
		get_tree().change_scene_to_file("res://scenes/minigames/Trilha/Trilha.tscn")

func _on_btn_voltar_pressed() -> void:
	var level_manager = get_node_or_null("/root/LevelManager")
	if level_manager:
		level_manager.voltar_para_trilha()
	else:
		get_tree().change_scene_to_file("res://scenes/minigames/Trilha/Trilha.tscn")
