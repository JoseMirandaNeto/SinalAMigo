extends Control
class_name LibrasMemory

@export var sinal_da_fase: SinalLibras
@export var carta_prefab: PackedScene

var _card_grid: GridContainer
var _label_pontos: Label
var _label_tempo: Label
var _dica_label: Label

var _selecionadas: Array = []
var _pares_encontrados: int = 0
var _total_pares: int = 4

var _tempo_decorrido: float = 0.0
var _jogo_ativo: bool = true

func _ready() -> void:
	_card_grid = get_node_or_null("SafeContainer/MainLayout/GameArea/CardGrid") as GridContainer
	_label_pontos = get_node_or_null("SafeContainer/MainLayout/HeaderPanel/Margin/Header/LabelPontos") as Label
	_label_tempo = get_node_or_null("SafeContainer/MainLayout/HeaderPanel/Margin/Header/LabelTempo") as Label
	_dica_label = get_node_or_null("SafeContainer/MainLayout/Footer/DicaLabel") as Label

	var btn_voltar = get_node_or_null("SafeContainer/MainLayout/HeaderPanel/Margin/Header/BtnVoltar") as Button
	if btn_voltar:
		btn_voltar.pressed.connect(_on_btn_voltar_pressed)

	preparar_fase()
	gerar_tabuleiro()

func _process(delta: float) -> void:
	if _jogo_ativo:
		_tempo_decorrido += delta
		var minutos = int(_tempo_decorrido) / 60
		var segundos = int(_tempo_decorrido) % 60
		if _label_tempo:
			_label_tempo.text = "Tempo: %02d:%02d" % [minutos, segundos]

func preparar_fase() -> void:
	var level_manager = get_node_or_null("/root/LevelManager")
	var fase_atual = 1
	if level_manager:
		fase_atual = level_manager.nivel_atual

	_total_pares = clampi(3 + (fase_atual / 2), 3, 6)
	
	if _label_pontos:
		_label_pontos.text = "Pares: 0/%d" % _total_pares

	if _dica_label:
		_dica_label.text = "Módulo %d: Associe a letra em Libras ao texto!" % fase_atual

func gerar_tabuleiro() -> void:
	var lista_sinais = obter_sinais_para_partida()
	var cartas_info: Array = []

	for i in range(_total_pares):
		var sinal = lista_sinais[i % lista_sinais.size()]
		cartas_info.append({"id": i, "sinal": sinal, "eh_imagem": true})
		cartas_info.append({"id": i, "sinal": sinal, "eh_imagem": false})

	cartas_info.shuffle()

	if _card_grid:
		for child in _card_grid.get_children():
			child.queue_free()

		if cartas_info.size() <= 8:
			_card_grid.columns = 4
		else:
			_card_grid.columns = 4

		for info in cartas_info:
			var nova_carta = carta_prefab.instantiate()
			nova_carta.id = info.id
			
			var img: Texture2D = null
			var mostrar_imagem = false
			var txt = ""
			if "NomeDaPalavra" in info.sinal:
				txt = info.sinal.NomeDaPalavra
			else:
				txt = info.sinal.nome_da_palavra

			if info.eh_imagem:
				if "Ilustracao" in info.sinal:
					img = info.sinal.Ilustracao
				else:
					img = info.sinal.ilustracao
				mostrar_imagem = true
			else:
				var img_sig = null
				if "ImagemSignificado" in info.sinal:
					img_sig = info.sinal.ImagemSignificado
				else:
					img_sig = info.sinal.imagem_significado
				
				if img_sig != null:
					img = img_sig
					mostrar_imagem = true
				else:
					mostrar_imagem = false

			if mostrar_imagem and img == null:
				img = load("res://ui/hud/libras-avatar.png") as Texture2D

			nova_carta.configurar_carta(img, txt, mostrar_imagem)
			nova_carta.pressed.connect(func(): _on_carta_pressionada(nova_carta))
			
			_card_grid.add_child(nova_carta)

func obter_sinais_para_partida() -> Array[SinalLibras]:
	var lista: Array[SinalLibras] = []
	var level_manager = get_node_or_null("/root/LevelManager")
	
	if level_manager and level_manager.alfabeto_completo.size() > 0:
		for sinal in level_manager.alfabeto_completo:
			lista.append(sinal)

	if lista.size() == 0:
		var path_alfabeto_img = "res://assets/alfabetolibras.png"
		var atlas_tex = load(path_alfabeto_img) as Texture2D

		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			var color = "green" if atlas_tex else "red"
			game_manager.log_system("LibrasMemory: Carregando alfabeto.png. Sucesso? " + str(atlas_tex != null), color)

		var todas_letras: Array[String] = []
		for i in range(65, 91): # A to Z
			todas_letras.append(char(i))

		todas_letras.shuffle()

		var letras_necessarias = mini(_total_pares, todas_letras.size())
		for i in range(letras_necessarias):
			var letra = todas_letras[i]
			var mock_sinal = SinalLibras.new()
			
			if "NomeDaPalavra" in mock_sinal:
				mock_sinal.NomeDaPalavra = letra
			else:
				mock_sinal.nome_da_palavra = letra
			
			var ilust = null
			if atlas_tex:
				ilust = criar_atlas_letra_com_textura(letra, atlas_tex)
			else:
				ilust = load("res://ui/hud/libras-avatar.png") as Texture2D
				
			if "Ilustracao" in mock_sinal:
				mock_sinal.Ilustracao = ilust
			else:
				mock_sinal.ilustracao = ilust
			lista.append(mock_sinal)

	return lista

func criar_atlas_letra_com_textura(letra: String, atlas_tex: Texture2D) -> AtlasTexture:
	var index = letra.to_upper().unicode_at(0) - 65
	if index < 0 or index >= 26: return null

	var colunas = 5
	var cell_w = atlas_tex.get_width() / colunas
	var cell_h = atlas_tex.get_height() / 6.0
	var col = index % colunas
	var row = index / colunas

	var margem_esquerda = cell_w * 0.38

	var atlas = AtlasTexture.new()
	atlas.atlas = atlas_tex
	atlas.region = Rect2(col * cell_w + margem_esquerda, row * cell_h, cell_w - margem_esquerda, cell_h)
	return atlas

func _on_carta_pressionada(carta) -> void:
	if carta.virada or carta.combinada or _selecionadas.size() >= 2 or not _jogo_ativo: return

	carta.virar(true)
	_selecionadas.append(carta)

	if _selecionadas.size() == 2:
		processar_combinacao()

func processar_combinacao() -> void:
	var c1 = _selecionadas[0]
	var c2 = _selecionadas[1]

	await get_tree().create_timer(0.8).timeout

	if c1.id == c2.id:
		c1.combinada = true
		c2.combinada = true
		c1.aplicar_estilo_acerto()
		c2.aplicar_estilo_acerto()

		_pares_encontrados += 1
		
		if _label_pontos:
			_label_pontos.text = "Pares: %d/%d" % [_pares_encontrados, _total_pares]

		if _dica_label:
			_dica_label.text = "Excelente! Você encontrou um par."
	else:
		c1.virar(false)
		c2.virar(false)

		if _dica_label:
			_dica_label.text = "Tente novamente! Os sinais não correspondem."

	_selecionadas.clear()

	if _pares_encontrados == _total_pares:
		_jogo_ativo = false
		print("Vitória! Jogo da Memória completo.")

		if _dica_label:
			_dica_label.text = "Parabéns! Você completou a lição."

		await get_tree().create_timer(1.5).timeout

		var level_manager = get_node_or_null("/root/LevelManager")
		if level_manager:
			level_manager.completar_fase_atual()
			level_manager.voltar_para_trilha()

func _on_btn_voltar_pressed() -> void:
	var level_manager = get_node_or_null("/root/LevelManager")
	if level_manager:
		level_manager.voltar_para_trilha()
