using Godot;
using System;
using System.Collections.Generic;

public partial class LevelManager : Node
{
	// Cores oficiais do Sinalito para usar via código
	public readonly Color CorAzulSinalito = new Color("#0056b3"); 
	public readonly Color CorVerdeSinalito = new Color("#8dc63f");
	public readonly Color CorBrancoSinalito = new Color("#ffffff");
	
	// Carregar as Letras do Alfabeto em Libras
	private string _caminhoAlfabeto = "res://Data/Sinais/Alfabeto/";
	public List<SinalLibras> AlfabetoCompleto = new List<SinalLibras>();

	// NivelAtual representa a última fase desbloqueada (por padrão a 1)
	public int NivelAtual { get; set; } = 1;
	public int PontuacaoTotal { get; set; } = 0;
	
	public enum TipoMiniGame { Memoria, Ataque, Soletra, Detetive }

	// Mapeamento estático de fases para minijogos na trilha
	private readonly Dictionary<int, TipoMiniGame> _fasesConfig = new Dictionary<int, TipoMiniGame>()
	{
		{ 1, TipoMiniGame.Memoria },
		{ 2, TipoMiniGame.Soletra },
		{ 3, TipoMiniGame.Memoria },
		{ 4, TipoMiniGame.Soletra },
		{ 5, TipoMiniGame.Memoria },
		{ 6, TipoMiniGame.Soletra },
		{ 7, TipoMiniGame.Memoria },
		{ 8, TipoMiniGame.Soletra },
		{ 9, TipoMiniGame.Memoria },
		{ 10, TipoMiniGame.Soletra },
		{ 11, TipoMiniGame.Memoria },
		{ 12, TipoMiniGame.Soletra },
		{ 13, TipoMiniGame.Memoria }
	};

	public override void _Ready()
	{
		GD.Print("LevelManager: Iniciado!");
		
		// Carrega o progresso salvo assim que o LevelManager inicializa
		CallDeferred(nameof(CarregarSaveInicial));
	}

	private void CarregarSaveInicial()
	{
		var saveManager = GetNode<SaveManager>("/root/SaveManager");
		if (saveManager != null)
		{
			saveManager.CarregarJogo();
		}
	}

	public void CarregarFase(int numeroCasa)
	{
		TipoMiniGame tipo = TipoMiniGame.Memoria; // Padrão
		if (_fasesConfig.ContainsKey(numeroCasa))
		{
			tipo = _fasesConfig[numeroCasa];
		}

		GD.Print($"LevelManager: Carregando casa {numeroCasa} (MiniGame: {tipo})...");

		// Salva temporariamente a casa que o jogador está jogando no GameManager
		var gameManager = GetNode<GameManager>("/root/GameManager");
		if (gameManager != null)
		{
			gameManager.NivelAtual = numeroCasa;
		}

		string scenePath = "";
		switch (tipo)
		{
			case TipoMiniGame.Memoria:
				scenePath = "res://scenes/minigames/libras_memory/libras_memory.tscn";
				break;
			case TipoMiniGame.Soletra:
				scenePath = "res://scenes/minigames/soletra/soletra.tscn";
				break;
			default:
				scenePath = "res://scenes/minigames/libras_memory/libras_memory.tscn";
				break;
		}

		if (!string.IsNullOrEmpty(scenePath))
		{
			var error = GetTree().ChangeSceneToFile(scenePath);
			if (error != Error.Ok)
			{
				GD.PrintErr($"LevelManager: Erro ao mudar para cena {scenePath}: {error}");
			}
		}
	}

	public void CompletarFaseAtual()
	{
		var gameManager = GetNode<GameManager>("/root/GameManager");
		if (gameManager == null) return;

		int faseJogada = gameManager.NivelAtual;
		GD.Print($"LevelManager: Fase {faseJogada} completada!");

		// Adiciona pontuação (XP)
		PontuacaoTotal += 100;

		// Atualiza o nível real e XP atual do jogador
		gameManager.NivelJogador = (PontuacaoTotal / 500) + 1;
		gameManager.ExpJogador = PontuacaoTotal % 500;

		// Se a fase que o jogador completou for igual à última fase desbloqueada (NivelAtual), desbloqueia a próxima
		if (faseJogada == NivelAtual)
		{
			NivelAtual++;
			GD.Print($"LevelManager: Nova fase desbloqueada! Nível máximo alcançado: {NivelAtual}");
		}

		// Salva o jogo imediatamente
		var saveManager = GetNode<SaveManager>("/root/SaveManager");
		if (saveManager != null)
		{
			saveManager.SalvarJogo();
		}
		else
		{
			GD.PrintErr("LevelManager: SaveManager não encontrado para salvar.");
		}
	}

	public void VoltarParaTrilha()
	{
		string path = "res://scenes/minigames/Trilha/Trilha.tscn";
		var error = GetTree().ChangeSceneToFile(path);
		if (error != Error.Ok)
		{
			GD.PrintErr($"LevelManager: Erro ao retornar para a trilha: {error}");
		}
	}
}
