extends Node2D
class_name CasaTrilha

signal casa_pressionada(numero_fase: int)

@export var numero_fase: int = 1:
	set(value):
		numero_fase = value
		if is_inside_tree():
			atualizar_texto_label()

var _botao_base: PanelContainer
var _numero_label: Label
var _badge_status: PanelContainer
var _icone_cadeado: TextureRect
var _check_label: Label
var _icone_fase: TextureRect

var _cor_fundo_bloqueada: Color = Color("#e0e0e0")
var _cor_fundo_liberada: Color = Color("#ffffff")
var _cor_fundo_completada: Color = Color("#d4edda")

var _cor_borda_bloqueada: Color = Color("#bdbdbd")
var _cor_borda_liberada: Color = Color("#f0a500")
var _cor_borda_completada: Color = Color("#8dc63f")

var _cor_badge_bloqueado: Color = Color("#9e9e9e")
var _cor_badge_completo: Color = Color("#8dc63f")

enum EstadoCasa { BLOQUEADA, LIBERADA, COMPLETADA }
var estado: int = EstadoCasa.BLOQUEADA

func _ready() -> void:
	_botao_base = get_node_or_null("BotaoBase") as PanelContainer
	_numero_label = get_node_or_null("NumeroLabel") as Label
	_badge_status = get_node_or_null("BadgeStatus") as PanelContainer
	_icone_cadeado = get_node_or_null("BadgeStatus/IconeCadeado") as TextureRect
	_check_label = get_node_or_null("BadgeStatus/CheckLabel") as Label
	_icone_fase = get_node_or_null("BotaoBase/MarginContainer/IconeFase") as TextureRect

	atualizar_texto_label()
	configurar_icone_fase()

	if _botao_base:
		_botao_base.mouse_filter = Control.MOUSE_FILTER_STOP
		_botao_base.gui_input.connect(_on_botao_base_gui_input)
		_botao_base.mouse_entered.connect(_on_mouse_entered)
		_botao_base.mouse_exited.connect(_on_mouse_exited)

	atualizar_estado_visual()

func configurar_icone_fase() -> void:
	if _icone_fase == null: return

	var path_icone = "res://ui/hud/libras-avatar.png"

	match numero_fase:
		1:
			path_icone = "res://ui/hud/libras-avatar.png"
		2:
			path_icone = "res://ui/hud/Sinalito-avatar.png"
		_:
			path_icone = "res://ui/hud/_libras.png"

	var texture = load(path_icone) as Texture2D
	if texture:
		_icone_fase.texture = texture

func atualizar_texto_label() -> void:
	if _numero_label:
		_numero_label.text = "Módulo " + str(numero_fase)

func definir_estado(novo_estado: int) -> void:
	estado = novo_estado
	atualizar_estado_visual()

func atualizar_estado_visual() -> void:
	if _botao_base == null or _badge_status == null or _icone_cadeado == null or _check_label == null or _numero_label == null: return

	var estilo_base = _botao_base.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	var estilo_badge = _badge_status.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

	atualizar_texto_label()

	match estado:
		EstadoCasa.BLOQUEADA:
			estilo_base.bg_color = _cor_fundo_bloqueada
			estilo_base.border_color = _cor_borda_bloqueada
			estilo_base.border_width_bottom = 4
			if _icone_fase: _icone_fase.modulate = Color(1, 1, 1, 0.3)
			_numero_label.modulate = Color(0.5, 0.5, 0.5, 0.6)

			_badge_status.visible = true
			estilo_badge.bg_color = _cor_badge_bloqueado
			_icone_cadeado.visible = true
			_check_label.visible = false

		EstadoCasa.LIBERADA:
			estilo_base.bg_color = _cor_fundo_liberada
			estilo_base.border_color = _cor_borda_liberada
			estilo_base.border_width_bottom = 6
			if _icone_fase: _icone_fase.modulate = Color(1, 1, 1, 1)
			_numero_label.modulate = Color(0.1, 0.45, 0.85, 1)

			_badge_status.visible = false

			if not _botao_base.is_connected("draw", _animar_pulsacao):
				_animar_pulsacao()

		EstadoCasa.COMPLETADA:
			estilo_base.bg_color = _cor_fundo_completada
			estilo_base.border_color = _cor_borda_completada
			estilo_base.border_width_bottom = 4
			if _icone_fase: _icone_fase.modulate = Color(1, 1, 1, 0.9)
			_numero_label.modulate = Color(0.15, 0.55, 0.25, 1)

			_badge_status.visible = true
			estilo_badge.bg_color = _cor_badge_completo
			_icone_cadeado.visible = false
			_check_label.visible = true

	_botao_base.add_theme_stylebox_override("panel", estilo_base)
	_badge_status.add_theme_stylebox_override("panel", estilo_badge)

func _animar_pulsacao() -> void:
	if estado != EstadoCasa.LIBERADA: return
	var tween = create_tween().bind_node(self).set_loops()
	tween.tween_property(_botao_base, "scale", Vector2(1.05, 1.05), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_botao_base, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_botao_base_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if estado != EstadoCasa.BLOQUEADA:
				print("CasaTrilha: Iniciando lição da casa %d!" % numero_fase)
				casa_pressionada.emit(numero_fase)
				animar_clique()
			else:
				print("CasaTrilha: Nível %d trancado." % numero_fase)
				animar_erro()

func animar_clique() -> void:
	var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_botao_base.pivot_offset = _botao_base.size / 2.0
	tween.tween_property(_botao_base, "scale", Vector2(0.9, 0.9), 0.08)
	tween.tween_property(_botao_base, "scale", Vector2(1.0, 1.0), 0.12)

func animar_erro() -> void:
	var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_botao_base.pivot_offset = _botao_base.size / 2.0
	tween.tween_property(_botao_base, "position:x", _botao_base.position.x - 6, 0.05)
	tween.tween_property(_botao_base, "position:x", _botao_base.position.x + 6, 0.05)
	tween.tween_property(_botao_base, "position:x", _botao_base.position.x - 3, 0.05)
	tween.tween_property(_botao_base, "position:x", _botao_base.position.x, 0.05)

func _on_mouse_entered() -> void:
	if estado != EstadoCasa.BLOQUEADA:
		var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_botao_base.pivot_offset = _botao_base.size / 2.0
		tween.tween_property(_botao_base, "scale", Vector2(1.1, 1.1), 0.15)

func _on_mouse_exited() -> void:
	if estado != EstadoCasa.BLOQUEADA:
		var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_botao_base.pivot_offset = _botao_base.size / 2.0
		tween.tween_property(_botao_base, "scale", Vector2(1.0, 1.0), 0.15)
