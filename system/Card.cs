using Godot;
using System;

public partial class Card : PanelContainer
{
	[Export] public string NomeDoModo = "";
	[Export] public string Titulo;
	[Export] public string Descricao;
	[Export] public Texture2D Preview;
	[Export] public bool Desativado;
	
	// Cores do Sinalito para o feedback visual
	private readonly Color _corNormal = new Color("#1c75f0"); // Fundo branco
	private readonly Color _corHover = new Color("#0056b3");  // Azul bem claro para o fundo no hover
	private readonly Color _corBorda = new Color("#0056b3");  // Azul Vibrante do corpo
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		// Garante que o card detecte o mouse
		MouseFilter = MouseFilterEnum.Stop;
		
		// Conecta os sinais nativos via código
		MouseEntered += OnMouseEntered;
		MouseExited += OnMouseExited;

		// Define o pivô para o centro para que a escala cresça para todos os lados
		PivotOffset = Size / 2;
		
		// Configuração dos Cards
		var TituloCard = GetNode<Label>("VBoxContainer/ModeTitle");
		var DescCard   = GetNode<Label>("VBoxContainer/ScrollContainer/Description");
		var IconeCard  = GetNode<TextureRect>("VBoxContainer/AvatarContainer/Icon");
		
		TituloCard.Text = Titulo;
		DescCard.Text = Descricao;
	
		if (Preview == null)
		{
			//GD.Print("Sem Imagem no Inspector, carregando padrão...");
			Preview = GD.Load<Texture2D>("res://ui/hud/_libras.png");
		}
		
		if (IconeCard != null)
		{
			IconeCard.Texture = Preview;
		}
		
		var botao = GetNode<Button>("VBoxContainer/SelectButton");
		if (botao != null)
		{
			if (Desativado)
			{
				botao.Disabled = Desativado;
			}
		}
		
		//GD.Print("Titulo: " + Titulo);
		//GD.Print("Desc: " + Descricao);
		//GD.Print("Preview: " + Preview);
	}
	
	private void OnBtnSelectPressed()
	{
		if (!IsInsideTree()) return;

		if (!string.IsNullOrEmpty(NomeDoModo))
		{
			string scenePath = $"res://scenes/minigames/{NomeDoModo}/{NomeDoModo}.tscn";
			if (ResourceLoader.Exists(scenePath))
			{
				var error = GetTree().ChangeSceneToFile(scenePath);
				if (error == Error.Ok)
					GD.Print($"Card: Cena trocada com sucesso para {NomeDoModo}");
				else
					GD.PrintErr($"Card: Erro ao trocar cena para {NomeDoModo}: {error}");
			}
			else
			{
				GD.PrintErr($"Card: Arquivo de cena nao encontrado em {scenePath}");
			}
		}
	}
	
	private void OnMouseEntered()
	{
		// Cria um Tween para animar escala e cor simultaneamente
		Tween tween = CreateTween().BindNode(this).SetParallel(true).SetTrans(Tween.TransitionType.Cubic).SetEase(Tween.EaseType.Out);
		
		// 1. Aumenta levemente o tamanho (1.05x)
		tween.TweenProperty(this, "scale", new Vector2(1.05f, 1.05f), 0.2f);
		
		// 2. Muda a cor de fundo ou adiciona brilho na borda
		StyleBoxFlat estilo = (StyleBoxFlat)GetThemeStylebox("panel").Duplicate();
		tween.TweenProperty(estilo, "bg_color", _corHover, 0.2f);
		//tween.TweenProperty(estilo, "border_width_all", 4, 0.1f);
		
		tween.TweenProperty(estilo, "border_width_left", 4, 0.1f);
		tween.TweenProperty(estilo, "border_width_top", 4, 0.1f);
		tween.TweenProperty(estilo, "border_width_right", 4, 0.1f);
		tween.TweenProperty(estilo, "border_width_bottom", 4, 0.1f);
		
		tween.TweenProperty(estilo, "border_color", _corBorda, 0.1f);
		
		AddThemeStyleboxOverride("panel", estilo);
	}

	private void OnMouseExited()
	{
		Tween tween = CreateTween().BindNode(this).SetParallel(true).SetTrans(Tween.TransitionType.Cubic).SetEase(Tween.EaseType.Out);
		
		// Retorna ao tamanho original
		tween.TweenProperty(this, "scale", new Vector2(1.0f, 1.0f), 0.2f);
		
		// Retorna ao estilo original (Branco puro do Sinalito)
		StyleBoxFlat estilo = (StyleBoxFlat)GetThemeStylebox("panel").Duplicate();
		tween.TweenProperty(estilo, "bg_color", _corNormal, 0.2f);
		//tween.TweenProperty(estilo, "border_width_all", 0, 0.1f);
		
		tween.TweenProperty(estilo, "border_width_left", 4, 0.1f);
		tween.TweenProperty(estilo, "border_width_top", 4, 0.1f);
		tween.TweenProperty(estilo, "border_width_right", 4, 0.1f);
		tween.TweenProperty(estilo, "border_width_bottom", 4, 0.1f);
		
		AddThemeStyleboxOverride("panel", estilo);
	}
}
