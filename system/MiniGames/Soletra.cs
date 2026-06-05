using Godot;
using System;
using System.Collections.Generic;

public partial class Soletra : Control
{
	private HBoxContainer _wordContainer;
	private GridContainer _keyboardGrid;
	private Label _instructionLabel;
	private Label _titleLabel;
	private Button _btnVoltar;
	
	// Lista de palavras do banco de dados
	private readonly string[] _palavrasDb = { 
		"LIBRAS", "AMIGO", "SINAL", "AMOR", "OI", 
		"BOM", "DIA", "LICAO", "PARABENS", "ESTUDAR" 
	};
	
	private string _palavraAlvo = "";
	private int _letraAtualIndex = 0;
	private int _faseNumero = 1;
	
	// Dicionário de caixas de letras (nós visuais)
	private List<PanelContainer> _letterBoxes = new List<PanelContainer>();
	
	private Texture2D _atlasTexturaCompleta;

	public override void _Ready()
	{
		// Carrega referências
		_wordContainer = GetNode<HBoxContainer>("SafeContainer/MainLayout/WordArea/WordContainer");
		_keyboardGrid = GetNode<GridContainer>("SafeContainer/MainLayout/KeyboardArea/KeyboardGrid");
		_instructionLabel = GetNode<Label>("SafeContainer/MainLayout/InstructionLabel");
		_titleLabel = GetNode<Label>("SafeContainer/MainLayout/HeaderPanel/Margin/Header/TitleLabel");
		_btnVoltar = GetNode<Button>("SafeContainer/MainLayout/HeaderPanel/Margin/Header/BtnVoltar");

		if (_btnVoltar != null)
		{
			_btnVoltar.Pressed += OnBtnVoltarPressed;
		}

		// Carrega a textura do alfabeto
		_atlasTexturaCompleta = GD.Load<Texture2D>("res://ui/palavras/alfabeto.png");

		// Identifica qual a fase atual pela Trilha/LevelManager
		var levelManager = GetNodeOrNull<LevelManager>("/root/LevelManager");
		if (levelManager != null)
		{
			_faseNumero = levelManager.NivelAtual;
		}

		// Escolhe a palavra com base no número da fase
		_palavraAlvo = _palavrasDb[(_faseNumero - 1) % _palavrasDb.Length].ToUpper();
		_letraAtualIndex = 0;

		if (_titleLabel != null)
		{
			_titleLabel.Text = $"PALAVRA {_faseNumero}";
		}

		AtualizarInstrucao();
		GerarCaixasPalavra();
		GerarTecladoVisual();
	}

	private void AtualizarInstrucao()
	{
		if (_instructionLabel != null && _letraAtualIndex < _palavraAlvo.Length)
		{
			char letraEsperada = _palavraAlvo[_letraAtualIndex];
			_instructionLabel.Text = $"Clique sobre os sinais do alfabeto manual para traduzir a palavra acima, começando pela letra ({letraEsperada}):";
		}
	}

	private void GerarCaixasPalavra()
	{
		// Limpa caixas antigas
		foreach (Node child in _wordContainer.GetChildren())
		{
			child.QueueFree();
		}
		_letterBoxes.Clear();

		// Estilo padrão escuro para caixas não traduzidas
		var estiloEscuro = new StyleBoxFlat();
		estiloEscuro.BgColor = new Color("#2c2c2c");
		estiloEscuro.CornerRadiusTopLeft = 12;
		estiloEscuro.CornerRadiusTopRight = 12;
		estiloEscuro.CornerRadiusBottomLeft = 12;
		estiloEscuro.CornerRadiusBottomRight = 12;
		estiloEscuro.BorderWidthBottom = 4;
		estiloEscuro.BorderColor = new Color("#1e1e1e");

		// Cria uma caixa para cada letra da palavra
		for (int i = 0; i < _palavraAlvo.Length; i++)
		{
			char letra = _palavraAlvo[i];
			
			var box = new PanelContainer();
			box.CustomMinimumSize = new Vector2(90, 90);
			box.AddThemeStyleboxOverride("panel", estiloEscuro);
			
			// Container interno
			var margin = new MarginContainer();
			margin.AddThemeConstantOverride("margin_left", 8);
			margin.AddThemeConstantOverride("margin_right", 8);
			margin.AddThemeConstantOverride("margin_top", 8);
			margin.AddThemeConstantOverride("margin_bottom", 8);
			box.AddChild(margin);

			// Label exibindo a letra inicialmente
			var label = new Label();
			label.Text = letra.ToString();
			label.HorizontalAlignment = HorizontalAlignment.Center;
			label.VerticalAlignment = VerticalAlignment.Center;
			label.AddThemeFontSizeOverride("font_size", 36);
			label.Name = "LetraLabel";
			margin.AddChild(label);

			// TextureRect oculto que mostrará a imagem do sinal depois
			var textureRect = new TextureRect();
			textureRect.ExpandMode = TextureRect.ExpandModeEnum.IgnoreSize;
			textureRect.StretchMode = TextureRect.StretchModeEnum.KeepAspectCentered;
			textureRect.Visible = false;
			textureRect.Name = "SinalImage";
			margin.AddChild(textureRect);

			_wordContainer.AddChild(box);
			_letterBoxes.Add(box);
		}
	}

	private void GerarTecladoVisual()
	{
		// Limpa teclado antigo
		foreach (Node child in _keyboardGrid.GetChildren())
		{
			child.QueueFree();
		}

		// Estilo dos botões do teclado
		var estiloBotao = new StyleBoxFlat();
		estiloBotao.BgColor = new Color("#1e1e2d");
		estiloBotao.CornerRadiusTopLeft = 8;
		estiloBotao.CornerRadiusTopRight = 8;
		estiloBotao.CornerRadiusBottomLeft = 8;
		estiloBotao.CornerRadiusBottomRight = 8;
		estiloBotao.BorderWidthBottom = 3;
		estiloBotao.BorderColor = new Color("#0f0f15");

		// Cria botões de A a Z
		for (char c = 'A'; c <= 'Z'; c++)
		{
			char letraTeclado = c;
			
			var btn = new Button();
			btn.CustomMinimumSize = new Vector2(80, 80);
			btn.SizeFlagsHorizontal = SizeFlags.ExpandFill;
			btn.SizeFlagsVertical = SizeFlags.ExpandFill;
			btn.AddThemeStyleboxOverride("normal", estiloBotao);
			btn.AddThemeStyleboxOverride("hover", estiloBotao);
			
			// Recorta a imagem da mão correspondente
			if (_atlasTexturaCompleta != null)
			{
				var atlas = SlicarMaoDoTeclado(letraTeclado);
				if (atlas != null)
				{
					btn.Icon = atlas;
					btn.ExpandIcon = true;
				}
			}
			else
			{
				btn.Text = letraTeclado.ToString();
			}

			btn.Pressed += () => OnTeclaTecladoPressionada(letraTeclado, btn);
			_keyboardGrid.AddChild(btn);
		}
	}

	private AtlasTexture SlicarMaoDoTeclado(char letra)
	{
		int index = char.ToUpper(letra) - 'A';
		if (index < 0 || index >= 26) return null;

		int col = index % 5;
		int row = index / 5;
		
		float cellW = 250.8f;
		float cellH = 209.0f;

		// Recorta apenas a metade direita do grid 5x6 (para tirar o texto da letra guia)
		var atlas = new AtlasTexture();
		atlas.Atlas = _atlasTexturaCompleta;
		atlas.Region = new Rect2(col * cellW + 110, row * cellH, cellW - 110, cellH);
		return atlas;
	}

	private AtlasTexture SlicarCartaCompleta(char letra)
	{
		int index = char.ToUpper(letra) - 'A';
		if (index < 0 || index >= 26) return null;

		int col = index % 5;
		int row = index / 5;
		
		float cellW = 250.8f;
		float cellH = 209.0f;

		var atlas = new AtlasTexture();
		atlas.Atlas = _atlasTexturaCompleta;
		atlas.Region = new Rect2(col * cellW, row * cellH, cellW, cellH);
		return atlas;
	}

	private void OnTeclaTecladoPressionada(char letraClicada, Button botao)
	{
		if (_letraAtualIndex >= _palavraAlvo.Length) return;

		char letraEsperada = _palavraAlvo[_letraAtualIndex];

		if (letraClicada == letraEsperada)
		{
			RevelarLetraAtual();
			_letraAtualIndex++;

			if (_letraAtualIndex >= _palavraAlvo.Length)
			{
				ConcluirMiniGame();
			}
			else
			{
				AtualizarInstrucao();
			}
		}
		else
		{
			AnimarErro(botao);
		}
	}

	private void RevelarLetraAtual()
	{
		if (_letraAtualIndex >= _letterBoxes.Count) return;

		var box = _letterBoxes[_letraAtualIndex];
		
		// Altera cor de fundo para verde de acerto
		var estiloVerde = new StyleBoxFlat();
		estiloVerde.BgColor = new Color("#8dc63f");
		estiloVerde.CornerRadiusTopLeft = 12;
		estiloVerde.CornerRadiusTopRight = 12;
		estiloVerde.CornerRadiusBottomLeft = 12;
		estiloVerde.CornerRadiusBottomRight = 12;
		estiloVerde.BorderWidthBottom = 4;
		estiloVerde.BorderColor = new Color("#6ea12a");
		box.AddThemeStyleboxOverride("panel", estiloVerde);

		// Oculta Label de Texto
		var label = box.GetNode<Label>("MarginContainer/LetraLabel");
		if (label != null)
		{
			label.Visible = false;
		}

		// Mostra a Imagem do Sinal
		var textureRect = box.GetNode<TextureRect>("MarginContainer/SinalImage");
		if (textureRect != null)
		{
			char letra = _palavraAlvo[_letraAtualIndex];
			textureRect.Texture = SlicarCartaCompleta(letra);
			textureRect.Visible = true;
		}

		// Animação de pop/escala
		box.PivotOffset = box.CustomMinimumSize / 2;
		Tween tween = CreateTween().BindNode(this).SetTrans(Tween.TransitionType.Cubic).SetEase(Tween.EaseType.Out);
		tween.TweenProperty(box, "scale", new Vector2(1.15f, 1.15f), 0.1f);
		tween.TweenProperty(box, "scale", new Vector2(1.0f, 1.0f), 0.15f);
	}

	private void AnimarErro(Button btn)
	{
		// Animação de vibração horizontal (shake) do botão clicado incorretamente
		btn.PivotOffset = btn.CustomMinimumSize / 2;
		Vector2 originalPos = btn.Position;

		Tween tween = CreateTween().BindNode(this).SetTrans(Tween.TransitionType.Linear);
		tween.TweenProperty(btn, "position:x", originalPos.X - 8, 0.05f);
		tween.TweenProperty(btn, "position:x", originalPos.X + 8, 0.05f);
		tween.TweenProperty(btn, "position:x", originalPos.X - 4, 0.05f);
		tween.TweenProperty(btn, "position:x", originalPos.X, 0.05f);
	}

	private async void ConcluirMiniGame()
	{
		if (_instructionLabel != null)
		{
			_instructionLabel.Text = "Excelente! Você traduziu a palavra com sucesso!";
			_instructionLabel.AddThemeColorOverride("font_color", new Color("#8dc63f"));
		}

		// Anima todas as caixas juntas pulando
		for (int i = 0; i < _letterBoxes.Count; i++)
		{
			var box = _letterBoxes[i];
			box.PivotOffset = box.CustomMinimumSize / 2;
			
			Tween tween = CreateTween().BindNode(this).SetTrans(Tween.TransitionType.Cubic).SetEase(Tween.EaseType.Out);
			tween.TweenInterval(i * 0.05f); // Pequeno atraso sequencial
			tween.TweenProperty(box, "position:y", box.Position.Y - 15, 0.15f);
			tween.TweenProperty(box, "position:y", box.Position.Y, 0.15f);
		}

		await ToSignal(GetTree().CreateTimer(1.5f), "timeout");

		// Notifica LevelManager de sucesso
		var levelManager = GetNodeOrNull<LevelManager>("/root/LevelManager");
		if (levelManager != null)
		{
			levelManager.CompletarFaseAtual();
			levelManager.VoltarParaTrilha();
		}
		else
		{
			GetTree().ChangeSceneToFile("res://scenes/minigames/Trilha/Trilha.tscn");
		}
	}

	private void OnBtnVoltarPressed()
	{
		var levelManager = GetNodeOrNull<LevelManager>("/root/LevelManager");
		if (levelManager != null)
		{
			levelManager.VoltarParaTrilha();
		}
		else
		{
			GetTree().ChangeSceneToFile("res://scenes/minigames/Trilha/Trilha.tscn");
		}
	}
}
