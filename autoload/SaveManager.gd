extends Node
class_name SaveManager2

const SAVE_PATH = "user://savegame.json"

func _ready() -> void:
	pass

func salvar_jogo() -> void:
	var data: Dictionary = {}
	
	var game_manager = get_node_or_null("/root/GameManager")
	var level_manager = get_node_or_null("/root/LevelManager")
	
	if game_manager != null:
		data["NomeJogador"] = game_manager.nome_jogador
		data["NivelAtual"] = game_manager.nivel_jogador
		data["ExpAtual"] = game_manager.exp_jogador

	if level_manager != null:
		data["FaseLiberada"] = level_manager.nivel_atual
		data["PontuacaoTotal"] = level_manager.pontuacao_total

	var json_string = JSON.stringify(data)
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(json_string)
		print("SaveManager: Jogo salvo com sucesso em " + SAVE_PATH)
	else:
		printerr("SaveManager: Falha ao abrir o arquivo para salvar em " + SAVE_PATH)

func carregar_jogo() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("SaveManager: Nenhum arquivo de save encontrado. Usando dados iniciais.")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		printerr("SaveManager: Falha ao abrir o arquivo de save para leitura.")
		return

	var json_string = file.get_as_text()
	var json = JSON.new()
	
	if json.parse(json_string) == OK:
		var data = json.data as Dictionary
		
		var game_manager = get_node_or_null("/root/GameManager")
		var level_manager = get_node_or_null("/root/LevelManager")

		if game_manager != null:
			if data.has("NomeJogador"):
				game_manager.nome_jogador = str(data["NomeJogador"])
			if data.has("NivelAtual"):
				game_manager.nivel_jogador = int(data["NivelAtual"])
			if data.has("ExpAtual"):
				game_manager.exp_jogador = int(data["ExpAtual"])

		if level_manager != null:
			if data.has("FaseLiberada"):
				level_manager.nivel_atual = int(data["FaseLiberada"])
			if data.has("PontuacaoTotal"):
				level_manager.pontuacao_total = int(data["PontuacaoTotal"])

		print("SaveManager: Progresso carregado com sucesso!")
	else:
		printerr("SaveManager: Erro ao parsear o JSON: %s na linha %d" % [json.get_error_message(), json.get_error_line()])
