extends Node2D
class_name CasaTrilha

signal casa_pressionada(numero_fase: int)

@export var numero_fase: int = 1:
	set(value):
		numero_fase = value
		if is_inside_tree():
			atualizar_texto_label()

var _botao: PanelContainer
var _icon_label: Label
var _fase_label: Label
var _vbox: VBoxContainer
var _circulo: StyleBoxFlat
var _tween_pulso: Tween

enum EstadoCasa { BLOQUEADA, LIBERADA, COMPLETADA }
var estado: int = EstadoCasa.BLOQUEADA

func _ready() -> void:
	_botao = get_node_or_null("Botao") as PanelContainer
	_vbox = get_node_or_null("Botao/Centro/VBox") as VBoxContainer
	_icon_label = get_node_or_null("Botao/Centro/VBox/IconLabel") as Label
	_fase_label = get_node_or_null("Botao/Centro/VBox/FaseLabel") as Label

	var centro = get_node_or_null("Botao/Centro") as Control
	if centro:
		centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _vbox:
		_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _icon_label:
		_icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _fase_label:
		_fase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	atualizar_texto_label()
	if _botao:
		_circulo = _botao.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		_botao.mouse_filter = Control.MOUSE_FILTER_STOP
		_botao.gui_input.connect(_on_gui_input)

	atualizar_estado_visual()

func atualizar_texto_label() -> void:
	if _fase_label:
		_fase_label.text = "FASE " + str(numero_fase)

func definir_estado(novo_estado: int) -> void:
	estado = novo_estado
	if _tween_pulso and _tween_pulso.is_valid():
		_tween_pulso.kill()
		_tween_pulso = null
	atualizar_estado_visual()

func atualizar_estado_visual() -> void:
	if not _botao or not _circulo: return

	# Clean up any existing ClockDrawer instance
	if _vbox:
		for child in _vbox.get_children():
			if child is ClockDrawer:
				child.queue_free()

	match estado:
		EstadoCasa.COMPLETADA:
			_circulo.bg_color = Color("#8dc63f") # Verde Sinalito official
			_circulo.border_color = Color("#5F81FF") # Trail connection blue
			_circulo.border_width_left = 6
			_circulo.border_width_top = 6
			_circulo.border_width_right = 6
			_circulo.border_width_bottom = 6
			
			if _icon_label:
				_icon_label.text = "✓"
				_icon_label.add_theme_font_size_override("font_size", 38)
				_icon_label.modulate = Color("#151515")
				_icon_label.visible = true
			if _fase_label:
				_fase_label.text = "FASE " + str(numero_fase)
				_fase_label.add_theme_font_size_override("font_size", 14)
				_fase_label.modulate = Color("#151515")
				_fase_label.visible = true
			scale = Vector2(1.0, 1.0)

		EstadoCasa.LIBERADA:
			_circulo.bg_color = Color("#FFC107") # Yellow
			_circulo.border_color = Color("#5F81FF") # Trail connection blue
			_circulo.border_width_left = 6
			_circulo.border_width_top = 6
			_circulo.border_width_right = 6
			_circulo.border_width_bottom = 6
			
			if _icon_label:
				_icon_label.visible = false
			if _fase_label:
				_fase_label.visible = false
			
			# Add clock drawer dynamically to keep the clean vector clock centered
			var clock = ClockDrawer.new()
			_vbox.add_child(clock)
			_vbox.move_child(clock, 0) # Put on top / centered
			
			scale = Vector2(1.1, 1.1)
			animar_pulso()

		EstadoCasa.BLOQUEADA:
			_circulo.bg_color = Color("#1468EE") # Blue
			_circulo.border_color = Color("#5F81FF") # Light blue border
			_circulo.border_width_left = 6
			_circulo.border_width_top = 6
			_circulo.border_width_right = 6
			_circulo.border_width_bottom = 6
			
			if _icon_label:
				_icon_label.visible = false
			if _fase_label:
				_fase_label.text = "FASE " + str(numero_fase)
				_fase_label.add_theme_font_size_override("font_size", 18)
				_fase_label.modulate = Color("#151515")
				_fase_label.visible = true
			scale = Vector2(0.95, 0.95)

	_botao.add_theme_stylebox_override("panel", _circulo)

func animar_pulso() -> void:
	_tween_pulso = create_tween().bind_node(self).set_loops()
	_tween_pulso.tween_property(self, "scale", Vector2(1.15, 1.15), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween_pulso.tween_property(self, "scale", Vector2(1.1, 1.1), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if estado != EstadoCasa.BLOQUEADA:
			casa_pressionada.emit(numero_fase)
			animar_clique()
		else:
			animar_erro()

func animar_clique() -> void:
	if not _botao: return
	var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_botao, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(_botao, "scale", Vector2(1.0, 1.0), 0.12)

func animar_erro() -> void:
	if not _botao: return
	var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var px = _botao.position.x
	tween.tween_property(_botao, "position:x", px - 6, 0.05)
	tween.tween_property(_botao, "position:x", px + 6, 0.05)
	tween.tween_property(_botao, "position:x", px - 3, 0.05)
	tween.tween_property(_botao, "position:x", px, 0.05)
