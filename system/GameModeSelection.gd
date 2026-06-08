extends Control
class_name GameModeSelection

var _btn_voltar: Button

func _ready() -> void:
	_btn_voltar = get_node_or_null("Button") as Button

func _on_btn_voltar_pressed() -> void:
	var menu_path = "res://ui/main_menu.tscn"
	var error = get_tree().change_scene_to_file(menu_path)
	if error != OK:
		printerr("GameModeSelection: Erro ao retornar para o menu %s: %d" % [menu_path, error])
	else:
		print("GameModeSelection: Retornando ao menu principal...")
