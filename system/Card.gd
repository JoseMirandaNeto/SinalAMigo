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

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	pivot_offset = size / 2.0
	
	var titulo_card = get_node_or_null("VBoxContainer/ModeTitle") as Label
	var desc_card = get_node_or_null("VBoxContainer/ScrollContainer/Description") as Label
	var icone_card = get_node_or_null("VBoxContainer/AvatarContainer/Icon") as TextureRect
	
	if titulo_card: titulo_card.text = titulo
	if desc_card: desc_card.text = descricao
	
	if preview == null:
		preview = load("res://ui/hud/_libras.png") as Texture2D
		
	if icone_card: icone_card.texture = preview
	
	var botao = get_node_or_null("VBoxContainer/SelectButton") as Button
	if botao:
		botao.disabled = desativado
		if not botao.pressed.is_connected(_on_btn_select_pressed):
			botao.pressed.connect(_on_btn_select_pressed)

func _on_btn_select_pressed() -> void:
	if not is_inside_tree(): return
	
	if nome_do_modo != "":
		var scene_path = "res://scenes/minigames/" + nome_do_modo + "/" + nome_do_modo + ".tscn"
		if ResourceLoader.exists(scene_path):
			var error = get_tree().change_scene_to_file(scene_path)
			if error == OK:
				print("Card: Cena trocada com sucesso para " + nome_do_modo)
			else:
				printerr("Card: Erro ao trocar cena para " + nome_do_modo + ": " + str(error))
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
