extends MarginContainer
class_name SafeAreaHandler

func _ready() -> void:
	ajustar_area_segura()
	get_viewport().size_changed.connect(ajustar_area_segura)

func ajustar_area_segura() -> void:
	var os_name = OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		add_theme_constant_override("margin_left", 0)
		add_theme_constant_override("margin_top", 0)
		add_theme_constant_override("margin_right", 0)
		add_theme_constant_override("margin_bottom", 0)
		return

	var safe_area = DisplayServer.get_display_safe_area()
	var window_size = DisplayServer.window_get_size()

	var margem_esquerda = safe_area.position.x
	var margem_superior = safe_area.position.y
	var margem_direita = window_size.x - safe_area.end.x
	var margem_inferior = window_size.y - safe_area.end.y

	var compensacao_extra = 20 

	add_theme_constant_override("margin_left", margem_esquerda + compensacao_extra)
	add_theme_constant_override("margin_top", margem_superior + compensacao_extra)
	add_theme_constant_override("margin_right", margem_direita + compensacao_extra)
	add_theme_constant_override("margin_bottom", margem_inferior + compensacao_extra)
	
	print("SafeAreaHandler: Safe Area aplicada no dispositivo móvel. Margens: L:%d, T:%d, R:%d, B:%d" % [margem_esquerda, margem_superior, margem_direita, margem_inferior])
