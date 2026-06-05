extends TextureButton
class_name Carta

@export var id: int = 0
var virada: bool = false
var combinada: bool = false

var _background: Panel
var _conteudo: TextureRect
var _label_texto: Label
var _estilo_normal: StyleBoxFlat

var _temp_imagem: Texture2D
var _temp_texto: String
var _temp_mostrar_imagem: bool = false
var _configurado: bool = false

var _cor_verso: Color = Color("#0056b3")
var _cor_frente: Color = Color("#ffffff")
var _cor_acerto: Color = Color("#8dc63f")

func _ready() -> void:
	_background = get_node_or_null("Background") as Panel
	_conteudo = get_node_or_null("MarginContainer/Conteudo") as TextureRect
	_label_texto = get_node_or_null("MarginContainer/LabelTexto") as Label
	
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)

	if _conteudo: _conteudo.visible = false
	if _label_texto: _label_texto.visible = false
	
	_estilo_normal = StyleBoxFlat.new()
	_estilo_normal.bg_color = _cor_verso
	_estilo_normal.corner_radius_top_left = 20
	_estilo_normal.corner_radius_top_right = 20
	_estilo_normal.corner_radius_bottom_left = 20
	_estilo_normal.corner_radius_bottom_right = 20
	_estilo_normal.border_width_bottom = 4
	_estilo_normal.border_color = Color(0, 0.2, 0.5)
	
	add_theme_stylebox_override("normal", _estilo_normal)

	if _configurado:
		aplicar_configuracao()

func configurar_carta(imagem: Texture2D, texto: String, mostrar_imagem: bool) -> void:
	_temp_imagem = imagem
	_temp_texto = texto
	_temp_mostrar_imagem = mostrar_imagem
	_configurado = true

	if is_inside_tree():
		aplicar_configuracao()

func aplicar_configuracao() -> void:
	if _temp_mostrar_imagem:
		if _conteudo:
			_conteudo.texture = _temp_imagem
			_conteudo.visible = false
		if _label_texto:
			_label_texto.visible = false
	else:
		if _conteudo:
			_conteudo.visible = false
			_conteudo.texture = null
		if _label_texto:
			_label_texto.text = _temp_texto
			_label_texto.visible = false

func aplicar_estilo_acerto() -> void:
	if _background == null: return

	var estilo_acerto = _background.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if estilo_acerto:
		estilo_acerto.border_width_bottom = 6
		estilo_acerto.border_color = _cor_acerto
		estilo_acerto.bg_color = Color("#e2f0d9")
		_background.add_theme_stylebox_override("panel", estilo_acerto)

func virar(mostrar: bool) -> void:
	if virada == mostrar: return
	virada = mostrar

	var tween = create_tween().bind_node(self).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale:x", 0.0, 0.15)
	
	tween.tween_callback(func():
		if _conteudo and _conteudo.texture:
			_conteudo.visible = mostrar
		
		if _label_texto:
			_label_texto.visible = mostrar

		if _background:
			var estilo = _background.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if estilo:
				if mostrar:
					estilo.bg_color = _cor_frente
					estilo.border_color = Color(0.8, 0.8, 0.8)
				else:
					estilo.bg_color = _cor_verso
					estilo.border_color = Color(0, 0.2, 0.5)
				_background.add_theme_stylebox_override("panel", estilo)
	)

	tween.tween_property(self, "scale:x", 1.0, 0.15)
