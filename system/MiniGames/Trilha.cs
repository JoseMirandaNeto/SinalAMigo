using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public partial class Trilha : Node2D
{
	private Node2D _casasContainer;
	private Label _pontuacaoLabel;
	private Label _streakLabel;
	private ProgressBar _progressBar;
	private Sprite2D _playerSprite;
	private Line2D _caminhoLinha;
	private Line2D _caminhoLinhaBorda;
	private Camera2D _camera;
	private Button _btnVoltar;
	private Button _btnComecar;

	// Rastreia a fase ativa onde o jogador está parado
	private int _faseFocoNumero = 1;

	public override void _Ready()
	{
		_casasContainer = GetNode<Node2D>("CasasContainer");
		
		// Mapeamento dos nós da nova HUD superior
		_pontuacaoLabel = GetNode<Label>("CanvasUI/SafeContainer/MainLayout/HeaderPanel/Margin/Header/XPLabel");
		_streakLabel = GetNode<Label>("CanvasUI/SafeContainer/MainLayout/HeaderPanel/Margin/Header/StreakLabel");
		_progressBar = GetNode<ProgressBar>("CanvasUI/SafeContainer/MainLayout/ProgressBar");
		
		// Botão voltar do Header
		_btnVoltar = GetNode<Button>("CanvasUI/SafeContainer/MainLayout/HeaderPanel/Margin/Header/BtnVoltar");
		if (_btnVoltar != null)
		{
			_btnVoltar.Pressed += OnBtnVoltarPressed;
		}

		// Botão começar inferior flutuante
		_btnComecar = GetNode<Button>("CanvasUI/SafeContainer/MainLayout/BottomPanel/Margin/BtnComecar");
		if (_btnComecar != null)
		{
			_btnComecar.Pressed += OnBtnComecarPressed;
		}

		// Inicializa e configura a Camera2D dinamicamente
		CriarCameraSeguidora();

		// Tentativa de pegar o player de dentro do Caminho/PlayerFollow ou direto
		if (HasNode("Caminho/PlayerFollow/PlayerSprite"))
		{
			_playerSprite = GetNode<Sprite2D>("Caminho/PlayerFollow/PlayerSprite");
		}
		else if (HasNode("PlayerSprite"))
		{
			_playerSprite = GetNode<Sprite2D>("PlayerSprite");
		}

		// Configura o avatar padrão do Sinalito
		ConfigurarPlayerSprite();

		// Inicializa as duas linhas para formar a "pista" com borda (estilo tabuleiro)
		CriarLinhaConexao();

		// Ordena, posiciona e atualiza a interface
		AtualizarTrilha();
	}

	private void CriarCameraSeguidora()
	{
		_camera = new Camera2D();
		_camera.Name = "CameraTrilha";
		_camera.PositionSmoothingEnabled = true;
		_camera.PositionSmoothingSpeed = 4.0f;
		AddChild(_camera);
	}

	private void ConfigurarPlayerSprite()
	{
		if (_playerSprite == null) return;

		if (_playerSprite.Texture == null)
		{
			var texture = GD.Load<Texture2D>("res://ui/hud/Sinalito-avatar.png");
			if (texture != null)
			{
				_playerSprite.Texture = texture;
				float scale = 64.0f / texture.GetSize().X;
				_playerSprite.Scale = new Vector2(scale, scale);
				_playerSprite.Offset = new Vector2(0, -20);
				_playerSprite.ZIndex = 5; 
			}
		}
	}

	private void CriarLinhaConexao()
	{
		if (HasNode("LinhaTrilhaBorda")) GetNode("LinhaTrilhaBorda").QueueFree();
		if (HasNode("LinhaTrilha")) GetNode("LinhaTrilha").QueueFree();

		// 1. Linha inferior (borda do tabuleiro em azul Sinalito)
		_caminhoLinhaBorda = new Line2D();
		_caminhoLinhaBorda.Name = "LinhaTrilhaBorda";
		_caminhoLinhaBorda.Width = 32.0f;
		_caminhoLinhaBorda.DefaultColor = new Color("#1c75f0"); // Azul celeste da marca
		_caminhoLinhaBorda.ZIndex = -2;
		_caminhoLinhaBorda.JointMode = Line2D.LineJointMode.Round;
		_caminhoLinhaBorda.BeginCapMode = Line2D.LineCapMode.Round;
		_caminhoLinhaBorda.EndCapMode = Line2D.LineCapMode.Round;
		AddChild(_caminhoLinhaBorda);

		// 2. Linha interna (pista em branco puro)
		_caminhoLinha = new Line2D();
		_caminhoLinha.Name = "LinhaTrilha";
		_caminhoLinha.Width = 20.0f;
		_caminhoLinha.DefaultColor = new Color("#ffffff"); // Branco
		_caminhoLinha.ZIndex = -1;
		_caminhoLinha.JointMode = Line2D.LineJointMode.Round;
		_caminhoLinha.BeginCapMode = Line2D.LineCapMode.Round;
		_caminhoLinha.EndCapMode = Line2D.LineCapMode.Round;
		AddChild(_caminhoLinha);
	}

	private void ReposicionarCasasAutomaticamente(List<CasaTrilha> casas)
	{
		// Parâmetros da serpentina (Tabuleiro zigue-zague)
		float startX = 260f;
		float startY = 480f; // Posição vertical inicial (base)
		float dx = 320f;     // Distância horizontal entre casas
		float dy = 200f;     // Distância vertical entre linhas da serpentina
		int colunas = 3;     // 3 casas por linha de zigue-zague

		for (int i = 0; i < casas.Count; i++)
		{
			int row = i / colunas;
			int col = i % colunas;

			// Se for linha ímpar (1, 3, 5...), inverte a direção horizontal
			if (row % 2 == 1)
			{
				col = (colunas - 1) - col;
			}

			Vector2 localPos = new Vector2(startX + col * dx, startY - row * dy);
			casas[i].Position = localPos;
		}
	}

	private void AtualizarTrilha()
	{
		if (_casasContainer == null) return;

		var levelManager = GetNode<LevelManager>("/root/LevelManager");
		int nivelLiberado = (levelManager != null) ? levelManager.NivelAtual : 1;

		// Atualiza textos da HUD superior
		if (_pontuacaoLabel != null && levelManager != null)
		{
			_pontuacaoLabel.Text = $"XP: {levelManager.PontuacaoTotal}";
		}

		if (_progressBar != null && levelManager != null)
		{
			// Calcula progresso aproximado da unidade (13 fases totais)
			float pctProgresso = Mathf.Clamp((float)(nivelLiberado - 1) / 13f * 100f, 0f, 100f);
			_progressBar.Value = pctProgresso;
		}

		// 1. Coletar e indexar sequencialmente todas as casas filhas
		List<CasaTrilha> casas = new List<CasaTrilha>();
		int index = 1;
		
		foreach (Node filho in _casasContainer.GetChildren())
		{
			if (filho is CasaTrilha casa)
			{
				casa.NumeroFase = index;
				casas.Add(casa);
				index++;
			}
		}

		// Ordena
		casas = casas.OrderBy(c => c.NumeroFase).ToList();

		// 2. Reposiciona as casas no formato serpentina (Jogo da Vida)
		ReposicionarCasasAutomaticamente(casas);

		// 3. Atualizar os estados das casas e montar os pontos das linhas de pista
		_caminhoLinha.ClearPoints();
		_caminhoLinhaBorda.ClearPoints();
		CasaTrilha casaFoco = null;

		foreach (var casa in casas)
		{
			// Conecta clique
			if (!casa.IsConnected(CasaTrilha.SignalName.CasaPressionada, Callable.From<int>(OnCasaPressionada)))
			{
				casa.CasaPressionada += OnCasaPressionada;
			}

			// Define o estado (Bloqueada, Liberada ou Completada)
			if (casa.NumeroFase < nivelLiberado)
			{
				casa.DefinirEstado(CasaTrilha.EstadoCasa.Completada);
			}
			else if (casa.NumeroFase == nivelLiberado)
			{
				casa.DefinirEstado(CasaTrilha.EstadoCasa.Liberada);
				casaFoco = casa;
				_faseFocoNumero = casa.NumeroFase; // Guarda a fase atual ativa para o botão começar
			}
			else
			{
				casa.DefinirEstado(CasaTrilha.EstadoCasa.Bloqueada);
			}

			// Adiciona pontos em ambas as linhas
			Vector2 localPosBorda = _caminhoLinhaBorda.ToLocal(casa.GlobalPosition);
			_caminhoLinhaBorda.AddPoint(localPosBorda);

			Vector2 localPosPista = _caminhoLinha.ToLocal(casa.GlobalPosition);
			_caminhoLinha.AddPoint(localPosPista);
		}

		if (casaFoco == null && casas.Count > 0)
		{
			casaFoco = casas.Last();
			_faseFocoNumero = casaFoco.NumeroFase;
		}

		// 4. Posicionar o avatar do jogador e a câmera
		if (casaFoco != null)
		{
			if (_camera != null)
			{
				_camera.GlobalPosition = casaFoco.GlobalPosition;
			}

			if (_playerSprite != null)
			{
				if (_playerSprite.GetParent() is PathFollow2D followNode)
				{
					_playerSprite.Reparent(this); 
					followNode.QueueFree(); 
				}
				
				Tween tween = CreateTween().BindNode(this).SetTrans(Tween.TransitionType.Cubic).SetEase(Tween.EaseType.Out);
				tween.TweenProperty(_playerSprite, "global_position", casaFoco.GlobalPosition, 1.0f);
			}
		}
	}

	private void OnCasaPressionada(int numeroFase)
	{
		IniciarFase(numeroFase);
	}

	private void OnBtnComecarPressed()
	{
		IniciarFase(_faseFocoNumero);
	}

	private void IniciarFase(int numeroFase)
	{
		GD.Print($"Trilha: Iniciando lição da fase {numeroFase}...");
		
		var levelManager = GetNode<LevelManager>("/root/LevelManager");
		if (levelManager != null)
		{
			levelManager.CarregarFase(numeroFase);
		}
		else
		{
			GD.PrintErr("Trilha: LevelManager Autoload não encontrado!");
		}
	}

	private void OnBtnVoltarPressed()
	{
		string modeSelectionPath = "res://scenes/game_mode_selection.tscn";
		var error = GetTree().ChangeSceneToFile(modeSelectionPath);
		if (error != Error.Ok)
		{
			GD.PrintErr($"Trilha: Erro ao retornar para selecao de modo {modeSelectionPath}: {error}");
		}
	}
}
