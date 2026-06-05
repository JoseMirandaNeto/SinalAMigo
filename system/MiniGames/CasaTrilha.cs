using Godot;
using System;

public partial class CasaTrilha : Node2D
{
	[Signal]
	public delegate void CasaPressionadaEventHandler(int numeroFase);

	[Export] public int NumeroFase { get; set; } = 1;

	private PanelContainer _botaoBase;
	private Label _numeroLabel;
	private PanelContainer _badgeStatus;
	private TextureRect _iconeCadeado;
	private Label _checkLabel;
	private TextureRect _iconeFase;

	// Cores temáticas para as bolhas da trilha (Sinal Amigo)
	private readonly Color _corFundoBloqueada = new Color("#e9ecef");   // Cinza neutro
	private readonly Color _corFundoLiberada = new Color("#ffffff");    // Branco em destaque
	private readonly Color _corFundoCompletada = new Color("#e2f0d9");  // Verde claro suave

	private readonly Color _corBordaBloqueada = new Color("#adb5bd");   // Borda cinza escuro
	private readonly Color _corBordaLiberada = new Color("#f0a500");    // Borda amarela/dourada ativa
	private readonly Color _corBordaCompletada = new Color("#8dc63f");   // Borda verde Sinalito completa

	private readonly Color _corBadgeBloqueado = new Color("#6c757d");    // Badge cinza cadeado
	private readonly Color _corBadgeCompleto = new Color("#8dc63f");     // Badge verde checkmark

	public enum EstadoCasa { Bloqueada, Liberada, Completada }
	public EstadoCasa Estado { get; private set; } = EstadoCasa.Bloqueada;

	public override void _Ready()
	{
		_botaoBase = GetNode<PanelContainer>("BotaoBase");
		_numeroLabel = GetNode<Label>("NumeroLabel");
		_badgeStatus = GetNode<PanelContainer>("BadgeStatus");
		_iconeCadeado = GetNode<TextureRect>("BadgeStatus/IconeCadeado");
		_checkLabel = GetNode<Label>("BadgeStatus/CheckLabel");
		_iconeFase = GetNode<TextureRect>("BotaoBase/MarginContainer/IconeFase");

		// Configura o rótulo da fase
		AtualizarTextoLabel();

		// Configura ícones e texturas dinâmicos baseados no tipo de fase
		ConfigurarIconeFase();

		// Vincula cliques e efeitos
		if (_botaoBase != null)
		{
			_botaoBase.MouseFilter = Control.MouseFilterEnum.Stop;
			_botaoBase.GuiInput += OnBotaoBaseGuiInput;
			_botaoBase.MouseEntered += OnMouseEntered;
			_botaoBase.MouseExited += OnMouseExited;
		}

		AtualizarEstadoVisual();
	}

	private void ConfigurarIconeFase()
	{
		if (_iconeFase == null) return;

		// Atribui ícones temáticos diferentes dependendo do número do nível para ficar visualmente rico
		string pathIcone = "res://ui/hud/libras-avatar.png"; // Padrão
		
		switch (NumeroFase)
		{
			case 1:
				pathIcone = "res://ui/hud/libras-avatar.png"; // Saudações
				break;
			case 2:
				pathIcone = "res://ui/hud/Sinalito-avatar.png"; // Sinalito mascote
				break;
			default:
				pathIcone = "res://ui/hud/_libras.png"; // Outro ícone
				break;
		}

		var texture = GD.Load<Texture2D>(pathIcone);
		if (texture != null)
		{
			_iconeFase.Texture = texture;
		}
	}

	private void AtualizarTextoLabel()
	{
		if (_numeroLabel != null)
		{
			_numeroLabel.Text = $"Fase {NumeroFase}";
		}
	}

	public void DefinirEstado(EstadoCasa novoEstado)
	{
		Estado = novoEstado;
		AtualizarEstadoVisual();
	}

	private void AtualizarEstadoVisual()
	{
		if (_botaoBase == null || _badgeStatus == null || _iconeCadeado == null || _checkLabel == null || _numeroLabel == null) return;

		StyleBoxFlat estiloBase = (StyleBoxFlat)_botaoBase.GetThemeStylebox("panel").Duplicate();
		StyleBoxFlat estiloBadge = (StyleBoxFlat)_badgeStatus.GetThemeStylebox("panel").Duplicate();

		// Atualiza rótulo
		System.Diagnostics.Debug.Assert(_numeroLabel != null, "_numeroLabel != null");
		AtualizarTextoLabel();

		switch (Estado)
		{
			case EstadoCasa.Bloqueada:
				// Base
				estiloBase.BgColor = _corFundoBloqueada;
				estiloBase.BorderColor = _corBordaBloqueada;
				_iconeFase.Modulate = new Color(1, 1, 1, 0.4f); // Ícone desbotado
				_numeroLabel.Modulate = new Color(0.3f, 0.3f, 0.3f, 0.6f);

				// Badge
				_badgeStatus.Visible = true;
				estiloBadge.BgColor = _corBadgeBloqueado;
				_iconeCadeado.Visible = true;
				_checkLabel.Visible = false;
				break;

			case EstadoCasa.Liberada:
				// Base
				estiloBase.BgColor = _corFundoLiberada;
				estiloBase.BorderColor = _corBordaLiberada;
				_iconeFase.Modulate = new Color(1, 1, 1, 1);
				_numeroLabel.Modulate = new Color(0.1f, 0.5f, 0.9f, 1); // Texto azul ativo

				// Badge (invisível para a fase ativa jogar)
				_badgeStatus.Visible = false;
				break;

			case EstadoCasa.Completada:
				// Base
				estiloBase.BgColor = _corFundoCompletada;
				estiloBase.BorderColor = _corBordaCompletada;
				_iconeFase.Modulate = new Color(1, 1, 1, 0.9f);
				_numeroLabel.Modulate = new Color(0.15f, 0.55f, 0.25f, 1); // Texto verde completo

				// Badge (Marca de check verde de conclusão)
				_badgeStatus.Visible = true;
				estiloBadge.BgColor = _corBadgeCompleto;
				_iconeCadeado.Visible = false;
				_checkLabel.Visible = true;
				break;
		}

		_botaoBase.AddThemeStyleboxOverride("panel", estiloBase);
		_badgeStatus.AddThemeStyleboxOverride("panel", estiloBadge);
	}

	private void OnBotaoBaseGuiInput(InputEvent @event)
	{
		if (@event is InputEventMouseButton mouseEvent)
		{
			if (mouseEvent.ButtonIndex == MouseButton.Left && mouseEvent.Pressed)
			{
				if (Estado != EstadoCasa.Bloqueada)
				{
					GD.Print($"CasaTrilha: Iniciando lição da casa {NumeroFase}!");
					EmitSignal(SignalName.CasaPressionada, NumeroFase);
					AnimarClique();
				}
				else
				{
					GD.Print($"CasaTrilha: Nível {NumeroFase} trancado.");
					AnimarErro();
				}
			}
		}
	}

	private void AnimarClique()
	{
		Tween tween = CreateTween().BindNode(this).SetTrans(Tween.TransitionType.Cubic).SetEase(Tween.EaseType.Out);
		_botaoBase.PivotOffset = _botaoBase.Size / 2;
		tween.TweenProperty(_botaoBase, "scale", new Vector2(0.9f, 0.9f), 0.08f);
		tween.TweenProperty(_botaoBase, "scale", new Vector2(1.0f, 1.0f), 0.12f);
	}

	private void AnimarErro()
	{
		Tween tween = CreateTween().BindNode(this).SetTrans(Tween.TransitionType.Elastic).SetEase(Tween.EaseType.Out);
		_botaoBase.PivotOffset = _botaoBase.Size / 2;
		tween.TweenProperty(_botaoBase, "position:x", _botaoBase.Position.X - 6, 0.05f);
		tween.TweenProperty(_botaoBase, "position:x", _botaoBase.Position.X + 6, 0.05f);
		tween.TweenProperty(_botaoBase, "position:x", _botaoBase.Position.X - 3, 0.05f);
		tween.TweenProperty(_botaoBase, "position:x", _botaoBase.Position.X, 0.05f);
	}

	private void OnMouseEntered()
	{
		if (Estado != EstadoCasa.Bloqueada)
		{
			Tween tween = CreateTween().BindNode(this).SetTrans(Tween.TransitionType.Cubic).SetEase(Tween.EaseType.Out);
			_botaoBase.PivotOffset = _botaoBase.Size / 2;
			tween.TweenProperty(_botaoBase, "scale", new Vector2(1.1f, 1.1f), 0.15f);
		}
	}

	private void OnMouseExited()
	{
		if (Estado != EstadoCasa.Bloqueada)
		{
			Tween tween = CreateTween().BindNode(this).SetTrans(Tween.TransitionType.Cubic).SetEase(Tween.EaseType.Out);
			_botaoBase.PivotOffset = _botaoBase.Size / 2;
			tween.TweenProperty(_botaoBase, "scale", new Vector2(1.0f, 1.0f), 0.15f);
		}
	}
}
