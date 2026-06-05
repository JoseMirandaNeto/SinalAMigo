using Godot;
using System;

public partial class MainMenu : Control
{
	private Button _btnJogar;
	private Button _btnConfig;
	private Label _logo;
	
	public override void _Ready()
	{
		_btnJogar = GetNode<Button>("SafeContainer/MainLayout/CenterLayout/ButtonsContainer/BtnJogar");
		_btnConfig = GetNode<Button>("SafeContainer/MainLayout/CenterLayout/ButtonsContainer/BtnConfig");
		
		_btnJogar.Pressed += OnBtnJogarPressed;
		_btnConfig.Pressed += OnBtnConfigPressed;
		
		GD.Print("MainMenu: Interface de Libras carregada com sucesso!");
		
		_logo = GetNode<Label>("SafeContainer/MainLayout/CenterLayout/LogoContainer/Logo");

		// 1. Define a opacidade inicial como zero (invisível) para animação de fade-in
		_logo.Modulate = new Color(1, 1, 1, 0);

		// 2. Cria o Tween para efeito de entrada da logo
		Tween fadeTween = CreateTween().BindNode(this);
		fadeTween.TweenProperty(_logo, "modulate:a", 1.0f, 1.5f)
				 .SetTrans(Tween.TransitionType.Cubic)
				 .SetEase(Tween.EaseType.InOut);

		// 3. Atualiza as estatísticas do jogador na HUD do cabeçalho
		AtualizarStatsInterface();
	}

	private void AtualizarStatsInterface()
	{
		var labelName = GetNodeOrNull<Label>("SafeContainer/MainLayout/HeaderPanel/Margin/Header/PlayerStats/PlayerName");
		var labelLevel = GetNodeOrNull<Label>("SafeContainer/MainLayout/HeaderPanel/Margin/Header/PlayerStats/LevelInfo/LevelLabel");
		var expBar = GetNodeOrNull<ProgressBar>("SafeContainer/MainLayout/HeaderPanel/Margin/Header/PlayerStats/LevelInfo/ExperienceBar");

		var gameManager = GameManager.Instance;
		var levelManager = GetNodeOrNull<LevelManager>("/root/LevelManager");

		if (gameManager != null && levelManager != null)
		{
			// Sincroniza o nível baseado nos pontos reais totais salvos no savegame
			int totalXp = levelManager.PontuacaoTotal;
			int playerLevel = (totalXp / 500) + 1;
			int currentLevelXp = totalXp % 500;

			gameManager.NivelJogador = playerLevel;
			gameManager.ExpJogador = currentLevelXp;

			if (labelName != null)
			{
				labelName.Text = $"Olá, {gameManager.NomeJogador}";
			}
			if (labelLevel != null)
			{
				labelLevel.Text = $"Nível {playerLevel}";
			}
			if (expBar != null)
			{
				expBar.Value = (currentLevelXp / 500.0f) * 100.0f;
			}
		}
	}

	private void OnBtnJogarPressed()
	{
		string scenePath = "res://scenes/game_mode_selection.tscn";
		var error = GetTree().ChangeSceneToFile(scenePath);
		if (error != Error.Ok)
		{
			GD.PrintErr($"MainMenu: Erro ao trocar cena para {scenePath}: {error}");
		}
		else
		{
			GD.Print("MainMenu: Redirecionando para seleção de modo...");
		}
	}
	
	private void OnBtnConfigPressed()
	{
		GD.Print("MainMenu: Abrindo configurações (Não implementado)...");
		// Futura cena de configurações
	}
}
