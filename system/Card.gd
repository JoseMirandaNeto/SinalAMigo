extends PanelContainer
class_name Card

@export var nome_do_modo: String = ""
@export var titulo: String = ""
@export var descricao: String = ""
@export var preview: Texture2D
@export var desativado: bool = false

var _cor_normal: Color = Color("#1c75f0")
var _cor_hover: Color = Color("#0056b3")
var _cor_borda: Color = Color("#0056b3")

# Lista de minijogos disponíveis para seleção aleatória (apenas libras_memory e soletra)
var _minigames_disponiveis: Array[String] = ["libras_memory", "soletra"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	pivot_offset = size / 2.0
	
	# Encontra os nodes filhos com segurança
	var titulo_card = get_node_or_null("Margin/VBoxContainer/ModeTitle") as Label
	var desc_card = get_node_or_null("Margin/VBoxContainer/Description") as Label
	var icone_card = get_node_or_null("Margin/VBoxContainer/AvatarContainer/Icon") as TextureRect
	
	# Define texto dos labels
	if titulo_card != null:
		titulo_card.text = titulo
	if desc_card != null:
		desc_card.text = descricao
	
	# Define imagem
	if preview == null:
		preview = load("res://ui/hud/_libras.png") as Texture2D
		
	if icone_card != null:
		icone_card.texture = preview
	
	# Configura o botão
	var botao = get_node_or_null("Margin/VBoxContainer/SelectButton") as Button
	if botao != null:
		botao.disabled = desativado
		if not botao.pressed.is_connected(_on_btn_select_pressed):
			botao.pressed.connect(_on_btn_select_pressed)

func _on_btn_select_pressed() -> void:
	if not is_inside_tree(): 
		return
	
	# Se nome_do_modo está vazio, escolhe aleatoriamente
	var modo_selecionado = nome_do_modo
	if modo_selecionado == "":
		modo_selecionado = _minigames_disponiveis[randi() % _minigames_disponiveis.size()]
	
	if modo_selecionado != "":
		# Define a origem como "modo_selecao" para o minigame saber onde retornar
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			game_manager.minigame_origem = "modo_selecao"
		
		var scene_path = "res://scenes/minigames/" + modo_selecionado + "/" + modo_selecionado + ".tscn"
		if ResourceLoader.exists(scene_path):
			var error = get_tree().change_scene_to_file(scene_path)
			if error == OK:
				print("Card: Cena trocada com sucesso para " + modo_selecionado)
			else:
				printerr("Card: Erro ao trocar cena para " + modo_selecionado + ": " + str(error))
		else:
			printerr("Card: Arquivo de cena nao encontrado em " + scene_path)

func _on_mouse_entered() -> void:
	var tween = create_tween().bind_node(self).set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2)
	
	var estilo = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if estilo:
		tween.tween_property(estilo, "bg_color", _cor_hover, 0.2)
		tween.tween_property(estilo, "border_width_left", 4, 0.1)
		tween.tween_property(estilo, "border_width_top", 4, 0.1)
		tween.tween_property(estilo, "border_width_right", 4, 0.1)
		tween.tween_property(estilo, "border_width_bottom", 4, 0.1)
		tween.tween_property(estilo, "border_color", _cor_borda, 0.1)
		add_theme_stylebox_override("panel", estilo)

func _on_mouse_exited() -> void:
	var tween = create_tween().bind_node(self).set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	var estilo = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if estilo:
		tween.tween_property(estilo, "bg_color", _cor_normal, 0.2)
		tween.tween_property(estilo, "border_width_left", 4, 0.1)
		tween.tween_property(estilo, "border_width_top", 4, 0.1)
		tween.tween_property(estilo, "border_width_right", 4, 0.1)
		tween.tween_property(estilo, "border_width_bottom", 4, 0.1)
		add_theme_stylebox_override("panel", estilo)
