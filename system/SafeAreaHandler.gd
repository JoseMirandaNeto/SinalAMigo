extends MarginContainer
class_name SafeAreaHandler

func _ready() -> void:
	ajustar_area_segura()
	get_viewport().size_changed.connect(ajustar_area_segura)

func ajustar_area_segura() -> void:
	var os_name = OS.get_name()
	var base_top = 30
	var base_side = 16
	var base_bottom = 16

	if os_name != "Android" and os_name != "iOS":
		add_theme_constant_override("margin_left", base_side)
		add_theme_constant_override("margin_top", base_top)
		add_theme_constant_override("margin_right", base_side)
		add_theme_constant_override("margin_bottom", base_bottom)
		return

	var safe_area = DisplayServer.get_display_safe_area()
	var window_size = DisplayServer.window_get_size()

	var margem_esquerda = safe_area.position.x
	var margem_superior = safe_area.position.y
	var margem_direita = window_size.x - safe_area.end.x
	var margem_inferior = window_size.y - safe_area.end.y

	add_theme_constant_override("margin_left", margem_esquerda + base_side)
	add_theme_constant_override("margin_top", margem_superior + base_top)
	add_theme_constant_override("margin_right", margem_direita + base_side)
	add_theme_constant_override("margin_bottom", margem_inferior + base_bottom)
	
	print("SafeAreaHandler: Safe Area aplicada no dispositivo móvel. Margens: L:%d, T:%d, R:%d, B:%d" % [margem_esquerda + base_side, margem_superior + base_top, margem_direita + base_side, margem_inferior + base_bottom])
