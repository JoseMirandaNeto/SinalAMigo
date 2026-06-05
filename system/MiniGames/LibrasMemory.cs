using Godot;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

public partial class LibrasMemory : Control
{
	[Export] public SinalLibras SinalDaFase;
	
	// Arraste a cena da Carta.tscn para este campo no Inspector
	[Export] public PackedScene CartaPrefab;

	private GridContainer _cardGrid;
	private Label _labelPontos;
	private Label _labelTempo;
	private Label _dicaLabel;
	
	private List<Carta> _selecionadas = new List<Carta>();
	private int _paresEncontrados = 0;
	private int _totalPares = 4; // Grid 2x4 (8 cartas) para ser rápido e dinâmico

	private float _tempoDecorrido = 0f;
	private bool _jogoAtivo = true;

	// Banco de dados em memória para caso a pasta de Resources esteja vazia
	private readonly string[] _letrasMock = { "A", "B", "C", "D", "E", "F" };

	public override void _Ready()
	{
		_cardGrid = GetNode<GridContainer>("SafeContainer/MainLayout/GameArea/CardGrid");
		_labelPontos = GetNode<Label>("SafeContainer/MainLayout/HeaderPanel/Margin/Header/LabelPontos");
		_labelTempo = GetNode<Label>("SafeContainer/MainLayout/HeaderPanel/Margin/Header/LabelTempo");
		_dicaLabel = GetNode<Label>("SafeContainer/MainLayout/Footer/DicaLabel");

		var btnVoltar = GetNode<Button>("SafeContainer/MainLayout/HeaderPanel/Margin/Header/BtnVoltar");
		if (btnVoltar != null)
		{
			btnVoltar.Pressed += OnBtnVoltarPressed;
		}

		PrepararFase();
		GerarTabuleiro();
	}

	public override void _Process(double delta)
	{
		if (_jogoAtivo)
		{
			_tempoDecorrido += (float)delta;
			int minutos = (int)(_tempoDecorrido / 60);
			int segundos = (int)(_tempoDecorrido % 60);
			if (_labelTempo != null)
			{
				_labelTempo.Text = $"Tempo: {minutos:00}:{segundos:00}";
			}
		}
	}

	private void PrepararFase()
	{
		var levelManager = GetNode<LevelManager>("/root/LevelManager");
		int faseAtual = 1;
		if (levelManager != null)
		{
			faseAtual = levelManager.NivelAtual;
		}

		// Ajusta a quantidade de pares dependendo da fase (máximo 6 pares = 12 cartas)
		_totalPares = Mathf.Clamp(3 + (faseAtual / 2), 3, 6);
		
		if (_labelPontos != null)
		{
			_labelPontos.Text = $"Pares: 0/{_totalPares}";
		}

		if (_dicaLabel != null)
		{
			_dicaLabel.Text = $"Fase {faseAtual}: Associe a letra em Libras ao texto!";
		}
	}

	private void GerarTabuleiro()
	{
		// 1. Coleta os sinais para o jogo
		List<SinalLibras> listaSinais = ObterSinaisParaPartida();
		
		// Estrutura para criar os pares
		// Para cada par, teremos duas entradas na lista: 
		// uma exibe a imagem (Libras) e a outra exibe o texto da palavra (Significado)
		List<Tuple<int, SinalLibras, bool>> cartasInfo = new List<Tuple<int, SinalLibras, bool>>();

		for (int i = 0; i < _totalPares; i++)
		{
			SinalLibras sinal = listaSinais[i % listaSinais.Count];
			
			// Adiciona a carta de Sinal (Imagem)
			cartasInfo.Add(new Tuple<int, SinalLibras, bool>(i, sinal, true));
			// Adiciona a carta de Significado (Texto)
			cartasInfo.Add(new Tuple<int, SinalLibras, bool>(i, sinal, false));
		}

		// Embaralhar as cartas (Fisher-Yates)
		Random rng = new Random();
		int n = cartasInfo.Count;
		while (n > 1)
		{
			n--;
			int k = rng.Next(n + 1);
			var value = cartasInfo[k];
			cartasInfo[k] = cartasInfo[n];
			cartasInfo[n] = value;
		}

		// Limpa o grid
		foreach (Node child in _cardGrid.GetChildren())
		{
			child.QueueFree();
		}

		// Ajusta colunas do grid
		if (cartasInfo.Count <= 8)
			_cardGrid.Columns = 4;
		else
			_cardGrid.Columns = 4; // Layout 3x4 para 12 cartas

		// Instancia no grid
		foreach (var info in cartasInfo)
		{
			Carta novaCarta = CartaPrefab.Instantiate<Carta>();
			
			// Configura os dados
			novaCarta.ID = info.Item1;
			
			Texture2D img = null;
			bool mostrarImagem = false;
			string txt = info.Item2.NomeDaPalavra;

			if (info.Item3) // Primeira carta do par: Mostra o sinal em Libras
			{
				img = info.Item2.Ilustracao;
				mostrarImagem = true;
			}
			else // Segunda carta do par: Mostra o significado (ImagemSignificado ou texto)
			{
				if (info.Item2.ImagemSignificado != null)
				{
					img = info.Item2.ImagemSignificado;
					mostrarImagem = true;
				}
				else
				{
					mostrarImagem = false; // Fallback para texto
				}
			}

			if (mostrarImagem && img == null)
			{
				// Carrega uma textura padrão se não tiver imagem válida
				img = GD.Load<Texture2D>("res://ui/hud/libras-avatar.png");
			}

			// Define se a carta vai exibir Imagem ou Texto
			novaCarta.ConfigurarCarta(img, txt, mostrarImagem);

			// Conecta clique
			novaCarta.Pressed += () => OnCartaPressionada(novaCarta);
			
			_cardGrid.AddChild(novaCarta);
		}
	}

	private List<SinalLibras> ObterSinaisParaPartida()
	{
		List<SinalLibras> lista = new List<SinalLibras>();
		
		// Tenta carregar do LevelManager se tiver itens carregados
		var levelManager = GetNode<LevelManager>("/root/LevelManager");
		if (levelManager != null && levelManager.AlfabetoCompleto.Count > 0)
		{
			foreach (var sinal in levelManager.AlfabetoCompleto)
			{
				lista.Add(sinal);
			}
		}

		// Se não tiver sinais cadastrados ou se o alfabeto estiver vazio, criamos dinamicamente usando a imagem alfabeto.png
		if (lista.Count == 0)
		{
			var pathAlfabetoImg = "res://ui/palavras/alfabeto.png";
			Texture2D atlasTex = null;
			
			try
			{
				// Tenta carregar diretamente via GD.Load, que funciona em todas as plataformas (incluindo Android exportado)
				atlasTex = GD.Load<Texture2D>(pathAlfabetoImg);
			}
			catch (Exception e)
			{
				GD.PrintErr($"LibrasMemory: Erro ao carregar alfabeto: {e.Message}");
			}

			if (GameManager.Instance != null)
			{
				GameManager.Instance.LogSystem($"LibrasMemory: Carregando alfabeto.png. Sucesso? {atlasTex != null}", atlasTex != null ? "green" : "red");
			}

			// Gerar lista de todas as letras de A a Z
			List<string> todasLetras = new List<string>();
			for (char c = 'A'; c <= 'Z'; c++)
			{
				todasLetras.Add(c.ToString());
			}

			// Embaralhar as letras para pegar um subconjunto aleatório
			Random rng = new Random();
			int n = todasLetras.Count;
			while (n > 1)
			{
				n--;
				int k = rng.Next(n + 1);
				string val = todasLetras[k];
				todasLetras[k] = todasLetras[n];
				todasLetras[n] = val;
			}

			// Pega a quantidade de letras necessárias para a partida
			int letrasNecessarias = Math.Min(_totalPares, todasLetras.Count);
			for (int i = 0; i < letrasNecessarias; i++)
			{
				string letra = todasLetras[i];
				SinalLibras mockSinal = new SinalLibras();
				mockSinal.NomeDaPalavra = letra;
				
				if (atlasTex != null)
				{
					mockSinal.Ilustracao = CriarAtlasLetraComTextura(letra[0], atlasTex);
				}
				else
				{
					mockSinal.Ilustracao = GD.Load<Texture2D>("res://ui/hud/libras-avatar.png");
				}
				lista.Add(mockSinal);
			}
		}

		return lista;
	}

	private AtlasTexture CriarAtlasLetraComTextura(char letra, Texture2D atlasTex)
	{
		int index = char.ToUpper(letra) - 'A';
		if (index < 0 || index >= 26) return null;

		int col = index % 5;
		int row = index / 5;
		
		float cellW = 250.8f;
		float cellH = 209.0f;

		AtlasTexture atlas = new AtlasTexture();
		atlas.Atlas = atlasTex;
		// Recorta o quadrado correspondente do grid 5x6 (250.8x209 pixels)
		atlas.Region = new Rect2(col * cellW, row * cellH, cellW, cellH);
		return atlas;
	}

	private async void OnCartaPressionada(Carta carta)
	{
		// Impede cliques inválidos
		if (carta.Virada || carta.Combinada || _selecionadas.Count >= 2 || !_jogoAtivo) return;

		carta.Virar(true);
		_selecionadas.Add(carta);

		if (_selecionadas.Count == 2)
		{
			await ProcessarCombinacao();
		}
	}

	private async Task ProcessarCombinacao()
	{
		Carta c1 = _selecionadas[0];
		Carta c2 = _selecionadas[1];

		// Pequena pausa para ver a carta
		await ToSignal(GetTree().CreateTimer(0.8f), "timeout");

		if (c1.ID == c2.ID)
		{
			// ACERTOU!
			c1.Combinada = c2.Combinada = true;
			c1.AplicarEstiloAcerto();
			c2.AplicarEstiloAcerto();

			_paresEncontrados++;
			
			if (_labelPontos != null)
			{
				_labelPontos.Text = $"Pares: {_paresEncontrados}/{_totalPares}";
			}

			if (_dicaLabel != null)
			{
				_dicaLabel.Text = "Excelente! Você encontrou um par.";
			}
		}
		else
		{
			// ERROU!
			c1.Virar(false);
			c2.Virar(false);

			if (_dicaLabel != null)
			{
				_dicaLabel.Text = "Tente novamente! Os sinais não correspondem.";
			}
		}

		_selecionadas.Clear();

		// Vitória
		if (_paresEncontrados == _totalPares)
		{
			_jogoAtivo = false;
			GD.Print("Vitória! Jogo da Memória completo.");

			if (_dicaLabel != null)
			{
				_dicaLabel.Text = "Parabéns! Você completou a lição.";
			}

			// Aguarda 1.5 segundos para mostrar feedback de vitória
			await ToSignal(GetTree().CreateTimer(1.5f), "timeout");

			// Atualiza progresso e volta para a trilha
			var levelManager = GetNode<LevelManager>("/root/LevelManager");
			if (levelManager != null)
			{
				levelManager.CompletarFaseAtual();
				levelManager.VoltarParaTrilha();
			}
		}
	}

	private void OnBtnVoltarPressed()
	{
		var levelManager = GetNode<LevelManager>("/root/LevelManager");
		if (levelManager != null)
		{
			levelManager.VoltarParaTrilha();
		}
	}
}
