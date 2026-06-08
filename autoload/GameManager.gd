extends Node

var nome_jogador: String = "José"
var nivel_atual: int = 1
var exp_atual: int = 0
var nivel_jogador: int = 1
var exp_jogador: int = 0

var _console_layer: CanvasLayer
var _rich_text_label: RichTextLabel
var _line_edit: LineEdit
var _btn_close: Button

var _command_history: Array[String] = []
var _history_index: int = -1

var _dedos_ativos: Dictionary = {}
var _pode_alternar: bool = true

func _ready() -> void:
	var cena_console = load("res://ui/hud/gm_layer.tscn") as PackedScene
	if cena_console != null:
		_console_layer = cena_console.instantiate() as CanvasLayer
		add_child(_console_layer)
		
		_console_layer.visible = false
		
		_rich_text_label = _console_layer.get_node("SafeContainer/PanelContainer/VBoxContainer/ScrollContainer/RichTextLabel") as RichTextLabel
		_line_edit = _console_layer.get_node("SafeContainer/PanelContainer/VBoxContainer/LineEdit") as LineEdit
		_btn_close = _console_layer.get_node("SafeContainer/PanelContainer/VBoxContainer/Header/Button") as Button
		
		if _line_edit != null:
			_line_edit.text_submitted.connect(on_command_submitted)
			_line_edit.gui_input.connect(on_line_edit_gui_input)
		if _btn_close != null:
			_btn_close.pressed.connect(toggle_console)
			
		log_system("Console GM carregado e pronto! Digite /help para a lista de comandos.", "green")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_dedos_ativos[event.index] = true
			if _dedos_ativos.size() >= 3 and _pode_alternar:
				toggle_console()
				_pode_alternar = false
		else:
			_dedos_ativos.erase(event.index)
			if _dedos_ativos.size() == 0:
				_pode_alternar = true

	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		toggle_console()

func on_line_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			if _command_history.size() > 0:
				if _history_index == -1:
					_history_index = _command_history.size() - 1
				elif _history_index > 0:
					_history_index -= 1
				_line_edit.text = _command_history[_history_index]
				_line_edit.call_deferred("set_caret_column", _line_edit.text.length())
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			if _command_history.size() > 0:
				if _history_index != -1 and _history_index < _command_history.size() - 1:
					_history_index += 1
					_line_edit.text = _command_history[_history_index]
					_line_edit.call_deferred("set_caret_column", _line_edit.text.length())
				else:
					_history_index = -1
					_line_edit.text = ""
				get_viewport().set_input_as_handled()

func toggle_console() -> void:
	if _console_layer == null: return
	
	_console_layer.visible = !_console_layer.visible
	if _console_layer.visible:
		print("GameManager: Modo GM Ativado!")
		if _line_edit != null:
			_line_edit.grab_focus()

func log_system(message: String, color: String = "white") -> void:
	if _rich_text_label == null: return
	
	var timestamp = Time.get_time_string_from_system()
	_rich_text_label.append_text("[%s] [color=%s]%s[/color]\n" % [timestamp, color, message])
	
	var scroll_container = _console_layer.get_node_or_null("SafeContainer/PanelContainer/VBoxContainer/ScrollContainer") as ScrollContainer
	if scroll_container != null:
		scroll_container.call_deferred("set_v_scroll", scroll_container.get_v_scroll_bar().max_value)

func on_command_submitted(text: String) -> void:
	if _line_edit == null or text.strip_edges() == "": return
	
	_line_edit.clear()
	log_system("> " + text, "yellow")
	
	if _command_history.size() == 0 or _command_history[_command_history.size() - 1] != text:
		_command_history.append(text)
	_history_index = -1
	
	parse_command(text.strip_edges())

func parse_command(command_line: String) -> void:
	var parts = command_line.split(" ", false)
	if parts.size() == 0: return
	
	var cmd = parts[0].to_lower()
	
	match cmd:
		"/help":
			log_system("=== COMANDOS GM DISPONÍVEIS ===", "cyan")
			log_system("/unlock <fase>  - Desbloqueia as fases na trilha até o número especificado.", "cyan")
			log_system("/fase <fase>    - Atalho para desbloquear fases.", "cyan")
			log_system("/score <pontos> - Adiciona pontuação ao placar do jogador.", "cyan")
			log_system("/xp <pontos>    - Atalho para adicionar XP.", "cyan")
			log_system("/setname <nome> - Altera o nome do jogador.", "cyan")
			log_system("/reset          - Apaga o savegame local e reinicia o progresso.", "cyan")
			log_system("/clear          - Limpa o histórico de mensagens da tela.", "cyan")
			log_system("/reload         - Recarrega a cena atual.", "cyan")
			log_system("/mainmenu       - Retorna para o menu principal.", "cyan")
			log_system("/help           - Mostra esta lista de ajuda.", "cyan")
		"/unlock", "/fase":
			if parts.size() < 2 or not parts[1].is_valid_int():
				log_system("Erro: Use /unlock <numero_da_fase> ou /fase <numero_da_fase>", "red")
				return
			var fase = parts[1].to_int()
			var level_manager = get_node_or_null("/root/LevelManager")
			if level_manager != null:
				level_manager.nivel_atual = fase
				log_system("Sucesso: Fases liberadas até a Fase %d!" % fase, "green")
				
				var save_manager = get_node_or_null("/root/SaveManager")
				if save_manager: save_manager.salvar_jogo()
				
				var current_scene = get_tree().current_scene
				if current_scene != null and current_scene.has_method("atualizar_trilha"):
					current_scene.call("atualizar_trilha")
		"/score", "/xp":
			if parts.size() < 2 or not parts[1].is_valid_int():
				log_system("Erro: Use /score <quantidade> ou /xp <quantidade>", "red")
				return
			var pontos = parts[1].to_int()
			var lm = get_node_or_null("/root/LevelManager")
			if lm != null:
				lm.pontuacao_total += pontos
				log_system("Sucesso: Adicionados %d pontos de XP! Total: %d" % [pontos, lm.pontuacao_total], "green")
				var save_manager = get_node_or_null("/root/SaveManager")
				if save_manager: save_manager.salvar_jogo()
				
				var current_scene = get_tree().current_scene
				if current_scene != null and current_scene.has_method("atualizar_trilha"):
					current_scene.call("atualizar_trilha")
		"/setname":
			if parts.size() < 2:
				log_system("Erro: Use /setname <nome_do_jogador>", "red")
				return
			var novo_nome = ""
			for i in range(1, parts.size()):
				novo_nome += parts[i] + " "
			novo_nome = novo_nome.strip_edges()
			nome_jogador = novo_nome
			log_system("Sucesso: Nome alterado para '%s'!" % novo_nome, "green")
			var save_manager = get_node_or_null("/root/SaveManager")
			if save_manager: save_manager.salvar_jogo()
		"/reset":
			var reset_lm = get_node_or_null("/root/LevelManager")
			if reset_lm != null:
				reset_lm.nivel_atual = 1
				reset_lm.pontuacao_total = 0
				nome_jogador = "José"
				var save_manager = get_node_or_null("/root/SaveManager")
				if save_manager: save_manager.salvar_jogo()
				log_system("Sucesso: Progresso de jogo completamente resetado!", "green")
				get_tree().reload_current_scene()
		"/clear":
			if _rich_text_label != null:
				_rich_text_label.clear()
				log_system("Console limpo.", "green")
		"/reload":
			log_system("Recarregando cena atual...", "yellow")
			get_tree().reload_current_scene()
		"/mainmenu":
			log_system("Retornando para o menu principal...", "yellow")
			get_tree().change_scene_to_file("res://ui/main_menu.tscn")
		_:
			log_system("Comando '%s' desconhecido. Digite /help para ajuda." % cmd, "red")
