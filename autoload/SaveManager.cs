using Godot;
using System;
using Godot.Collections;

public partial class SaveManager : Node
{
	private const string SavePath = "user://savegame.json";

	public static SaveManager Instance { get; private set; }

	public override void _Ready()
	{
		Instance = this;
	}

	public void SalvarJogo()
	{
		var data = new Dictionary<string, Variant>();
		
		var gameManager = GetNode<GameManager>("/root/GameManager");
		var levelManager = GetNode<LevelManager>("/root/LevelManager");
		
		if (gameManager != null)
		{
			data["NomeJogador"] = gameManager.NomeJogador;
			data["NivelAtual"] = gameManager.NivelJogador; // Salva o nível real do jogador
			data["ExpAtual"] = gameManager.ExpJogador;     // Salva o progresso de XP do jogador
		}

		if (levelManager != null)
		{
			data["FaseLiberada"] = levelManager.NivelAtual; // NivelAtual aqui representa a casa liberada
			data["PontuacaoTotal"] = levelManager.PontuacaoTotal;
		}

		string jsonString = Json.Stringify(data);
		
		using var file = FileAccess.Open(SavePath, FileAccess.ModeFlags.Write);
		if (file != null)
		{
			file.StoreString(jsonString);
			GD.Print("SaveManager: Jogo salvo com sucesso em " + SavePath);
		}
		else
		{
			GD.PrintErr("SaveManager: Falha ao abrir o arquivo para salvar em " + SavePath);
		}
	}

	public void CarregarJogo()
	{
		if (!FileAccess.FileExists(SavePath))
		{
			GD.Print("SaveManager: Nenhum arquivo de save encontrado. Usando dados iniciais.");
			return;
		}

		using var file = FileAccess.Open(SavePath, FileAccess.ModeFlags.Read);
		if (file == null)
		{
			GD.PrintErr("SaveManager: Falha ao abrir o arquivo de save para leitura.");
			return;
		}

		string jsonString = file.GetAsText();
		var json = new Json();
		
		if (json.Parse(jsonString) == Error.Ok)
		{
			var data = json.Data.AsGodotDictionary();
			
			var gameManager = GetNode<GameManager>("/root/GameManager");
			var levelManager = GetNode<LevelManager>("/root/LevelManager");

			if (gameManager != null)
			{
				if (data.ContainsKey("NomeJogador"))
					gameManager.NomeJogador = data["NomeJogador"].AsString();
				if (data.ContainsKey("NivelAtual"))
					gameManager.NivelJogador = data["NivelAtual"].AsInt32(); // Carrega no nível real
				if (data.ContainsKey("ExpAtual"))
					gameManager.ExpJogador = data["ExpAtual"].AsInt32();     // Carrega no XP real
			}

			if (levelManager != null)
			{
				if (data.ContainsKey("FaseLiberada"))
					levelManager.NivelAtual = data["FaseLiberada"].AsInt32();
				if (data.ContainsKey("PontuacaoTotal"))
					levelManager.PontuacaoTotal = data["PontuacaoTotal"].AsInt32();
			}

			GD.Print("SaveManager: Progresso carregado com sucesso!");
		}
		else
		{
			GD.PrintErr($"SaveManager: Erro ao parsear o JSON: {json.GetErrorMessage()} na linha {json.GetErrorLine()}");
		}
	}
}
