extends Node

var cor_azul_sinalito: Color = Color("#0056b3")
var cor_verde_sinalito: Color = Color("#8dc63f")
var cor_branco_sinalito: Color = Color("#ffffff")

var _caminho_alfabeto: String = "res://Data/Sinais/Alfabeto/"
var alfabeto_completo: Array = []

var nivel_atual: int = 1
var pontuacao_total: int = 0

enum TipoMiniGame { MEMORIA, ATAQUE, SOLETRA, DETETIVE }

var _fases_config: Dictionary = {
	1: TipoMiniGame.MEMORIA,
	2: TipoMiniGame.SOLETRA,
	3: TipoMiniGame.MEMORIA,
	4: TipoMiniGame.SOLETRA,
	5: TipoMiniGame.MEMORIA,
	6: TipoMiniGame.SOLETRA,
	7: TipoMiniGame.MEMORIA,
	8: TipoMiniGame.SOLETRA,
	9: TipoMiniGame.MEMORIA,
	10: TipoMiniGame.SOLETRA,
	11: TipoMiniGame.MEMORIA,
	12: TipoMiniGame.SOLETRA,
	13: TipoMiniGame.MEMORIA
}

func _ready() -> void:
	print("LevelManager: Iniciado!")
	call_deferred("carregar_save_inicial")

func carregar_save_inicial() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.carregar_jogo()

func carregar_fase(numero_casa: int) -> void:
	var tipo = TipoMiniGame.MEMORIA
	if _fases_config.has(numero_casa):
		tipo = _fases_config[numero_casa]

	print("LevelManager: Carregando casa %d (MiniGame: %d)..." % [numero_casa, tipo])

	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager != null:
		game_manager.nivel_atual = numero_casa

	var scene_path: String = ""
	match tipo:
		TipoMiniGame.MEMORIA:
			scene_path = "res://scenes/minigames/libras_memory/libras_memory.tscn"
		TipoMiniGame.SOLETRA:
			scene_path = "res://scenes/minigames/soletra/soletra.tscn"
		_:
			scene_path = "res://scenes/minigames/libras_memory/libras_memory.tscn"

	if scene_path != "":
		var error = get_tree().change_scene_to_file(scene_path)
		if error != OK:
			printerr("LevelManager: Erro ao mudar para cena %s: %d" % [scene_path, error])

func completar_fase_atual() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager == null: return

	var fase_jogada = game_manager.nivel_atual
	print("LevelManager: Fase %d completada!" % fase_jogada)

	pontuacao_total += 100

	game_manager.nivel_jogador = (pontuacao_total / 500) + 1
	game_manager.exp_jogador = pontuacao_total % 500

	if fase_jogada == nivel_atual:
		nivel_atual += 1
		print("LevelManager: Nova fase desbloqueada! Nível máximo alcançado: %d" % nivel_atual)

	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.salvar_jogo()
	else:
		printerr("LevelManager: SaveManager não encontrado para salvar.")

func voltar_para_trilha() -> void:
	var path = "res://scenes/minigames/Trilha/Trilha.tscn"
	var error = get_tree().change_scene_to_file(path)
	if error != OK:
		printerr("LevelManager: Erro ao retornar para a trilha: %d" % error)
