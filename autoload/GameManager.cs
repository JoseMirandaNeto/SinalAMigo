using Godot;
using System;
using System.Collections.Generic;

public partial class GameManager : Node
{
	public string NomeJogador { get; set; } = "José";
	public int NivelAtual { get; set; } = 1; // Rastreia a fase sendo jogada ativamente
	public int ExpAtual { get; set; } = 0;  // Mantido por compatibilidade
	
	public int NivelJogador { get; set; } = 1; // Nível RPG real do jogador
	public int ExpJogador { get; set; } = 0;   // XP do nível atual do jogador

	private CanvasLayer _consoleLayer;
	private RichTextLabel _richTextLabel;
	private LineEdit _lineEdit;
	private Button _btnClose;
	
	// Histórico de comandos
	private List<string> _commandHistory = new List<string>();
	private int _historyIndex = -1;

	// Rastreador de dedos para alternar o console GM com toque de 3 dedos no mobile
	private HashSet<int> _dedosAtivos = new HashSet<int>();
	private bool _podeAlternar = true;

	public static GameManager Instance { get; private set; }

	public override void _Ready()
	{
		Instance = this;

		// Instancia o console de depuração GM
		var cenaConsole = GD.Load<PackedScene>("res://ui/hud/gm_layer.tscn");
		if (cenaConsole != null)
		{
			_consoleLayer = cenaConsole.Instantiate<CanvasLayer>();
			AddChild(_consoleLayer);
			
			// Inicia invisível
			_consoleLayer.Visible = false;

			// Mapeia os elementos do console
			_richTextLabel = _consoleLayer.GetNode<RichTextLabel>("SafeContainer/PanelContainer/VBoxContainer/ScrollContainer/RichTextLabel");
			_lineEdit = _consoleLayer.GetNode<LineEdit>("SafeContainer/PanelContainer/VBoxContainer/LineEdit");
			_btnClose = _consoleLayer.GetNode<Button>("SafeContainer/PanelContainer/VBoxContainer/Header/Button");

			// Conecta os sinais
			if (_lineEdit != null)
			{
				_lineEdit.TextSubmitted += OnCommandSubmitted;
				_lineEdit.GuiInput += OnLineEditGuiInput;
			}
			if (_btnClose != null)
			{
				_btnClose.Pressed += ToggleConsole;
			}

			LogSystem("Console GM carregado e pronto! Digite /help para a lista de comandos.", "green");
		}
	}

	public override void _Input(InputEvent @event)
	{
		// 3 dedos na tela alternam o console GM
		if (@event is InputEventScreenTouch touchEvent)
		{
			if (touchEvent.Pressed)
			{
				_dedosAtivos.Add(touchEvent.Index);

				if (_dedosAtivos.Count >= 3 && _podeAlternar)
				{
					ToggleConsole();
					_podeAlternar = false; 
				}
			}
			else
			{
				_dedosAtivos.Remove(touchEvent.Index);
				if (_dedosAtivos.Count == 0)
				{
					_podeAlternar = true;
				}
			}
		}
		
		// Tecla F12 no PC alterna o console GM
		if (@event is InputEventKey keyEvent && keyEvent.Pressed && keyEvent.Keycode == Key.F12)
		{
			ToggleConsole();
		}
	}

	private void OnLineEditGuiInput(InputEvent @event)
	{
		if (@event is InputEventKey keyEvent && keyEvent.Pressed)
		{
			if (keyEvent.Keycode == Key.Up)
			{
				if (_commandHistory.Count > 0)
				{
					if (_historyIndex == -1)
					{
						_historyIndex = _commandHistory.Count - 1;
					}
					else if (_historyIndex > 0)
					{
						_historyIndex--;
					}
					_lineEdit.Text = _commandHistory[_historyIndex];
					_lineEdit.CallDeferred("set_caret_column", _lineEdit.Text.Length);
					GetViewport().SetInputAsHandled();
				}
			}
			else if (keyEvent.Keycode == Key.Down)
			{
				if (_commandHistory.Count > 0)
				{
					if (_historyIndex != -1 && _historyIndex < _commandHistory.Count - 1)
					{
						_historyIndex++;
						_lineEdit.Text = _commandHistory[_historyIndex];
						_lineEdit.CallDeferred("set_caret_column", _lineEdit.Text.Length);
					}
					else
					{
						_historyIndex = -1;
						_lineEdit.Text = "";
					}
					GetViewport().SetInputAsHandled();
				}
			}
		}
	}

	public void ToggleConsole()
	{
		if (_consoleLayer == null) return;

		_consoleLayer.Visible = !_consoleLayer.Visible;
		
		if (_consoleLayer.Visible)
		{
			GD.Print("GameManager: Modo GM Ativado!");
			if (_lineEdit != null)
			{
				_lineEdit.GrabFocus(); // Foca na caixa de digitação automaticamente
			}
		}
	}

	// Adiciona uma mensagem de sistema ao console de depuração
	public void LogSystem(string message, string color = "white")
	{
		if (_richTextLabel == null) return;
		
		string timestamp = Time.GetTimeStringFromSystem();
		_richTextLabel.AppendText($"[{timestamp}] [color={color}]{message}[/color]\n");

		// Rolagem automática para o final
		var scrollContainer = _consoleLayer?.GetNodeOrNull<ScrollContainer>("SafeContainer/PanelContainer/VBoxContainer/ScrollContainer");
		if (scrollContainer != null)
		{
			scrollContainer.CallDeferred("set_v_scroll", (int)scrollContainer.GetVScrollBar().MaxValue);
		}
	}

	private void OnCommandSubmitted(string text)
	{
		if (_lineEdit == null || string.IsNullOrWhiteSpace(text)) return;

		_lineEdit.Clear(); // Limpa caixa de digitação
		LogSystem($"> {text}", "yellow"); // Loga o comando digitado

		// Adiciona ao histórico se for diferente do último comando digitado
		if (_commandHistory.Count == 0 || _commandHistory[_commandHistory.Count - 1] != text)
		{
			_commandHistory.Add(text);
		}
		_historyIndex = -1;

		ParseCommand(text.Trim());
	}

	private void ParseCommand(string commandLine)
	{
		string[] parts = commandLine.Split(' ', StringSplitOptions.RemoveEmptyEntries);
		if (parts.Length == 0) return;

		string cmd = parts[0].ToLower();

		switch (cmd)
		{
			case "/help":
				LogSystem("=== COMANDOS GM DISPONÍVEIS ===", "cyan");
				LogSystem("/unlock <fase>  - Desbloqueia as fases na trilha até o número especificado.", "cyan");
				LogSystem("/fase <fase>    - Atalho para desbloquear fases.", "cyan");
				LogSystem("/score <pontos> - Adiciona pontuação ao placar do jogador.", "cyan");
				LogSystem("/xp <pontos>    - Atalho para adicionar XP.", "cyan");
				LogSystem("/setname <nome> - Altera o nome do jogador.", "cyan");
				LogSystem("/reset          - Apaga o savegame local e reinicia o progresso.", "cyan");
				LogSystem("/clear          - Limpa o histórico de mensagens da tela.", "cyan");
				LogSystem("/reload         - Recarrega a cena atual.", "cyan");
				LogSystem("/mainmenu       - Retorna para o menu principal.", "cyan");
				LogSystem("/help           - Mostra esta lista de ajuda.", "cyan");
				break;

			case "/unlock":
			case "/fase":
				if (parts.Length < 2 || !int.TryParse(parts[1], out int fase))
				{
					LogSystem("Erro: Use /unlock <numero_da_fase> ou /fase <numero_da_fase>", "red");
					break;
				}
				var levelManager = GetNode<LevelManager>("/root/LevelManager");
				if (levelManager != null)
				{
					levelManager.NivelAtual = fase;
					LogSystem($"Sucesso: Fases liberadas até a Fase {fase}!", "green");
					
					// Salva a alteração
					SaveManager.Instance.SalvarJogo();
					
					// Atualiza a trilha se estiver na cena correspondente
					var currentScene = GetTree().CurrentScene;
					if (currentScene != null && currentScene.HasMethod("AtualizarTrilha"))
					{
						currentScene.Call("AtualizarTrilha");
					}
				}
				break;

			case "/score":
			case "/xp":
				if (parts.Length < 2 || !int.TryParse(parts[1], out int pontos))
				{
					LogSystem("Erro: Use /score <quantidade> ou /xp <quantidade>", "red");
					break;
				}
				var lm = GetNode<LevelManager>("/root/LevelManager");
				if (lm != null)
				{
					lm.PontuacaoTotal += pontos;
					LogSystem($"Sucesso: Adicionados {pontos} pontos de XP! Total: {lm.PontuacaoTotal}", "green");
					SaveManager.Instance.SalvarJogo();
					
					// Atualiza a trilha se estiver na cena correspondente
					var currentScene = GetTree().CurrentScene;
					if (currentScene != null && currentScene.HasMethod("AtualizarTrilha"))
					{
						currentScene.Call("AtualizarTrilha");
					}
				}
				break;

			case "/setname":
				if (parts.Length < 2)
				{
					LogSystem("Erro: Use /setname <nome_do_jogador>", "red");
					break;
				}
				string novoNome = string.Join(" ", parts, 1, parts.Length - 1);
				NomeJogador = novoNome;
				LogSystem($"Sucesso: Nome alterado para '{novoNome}'!", "green");
				SaveManager.Instance.SalvarJogo();
				break;

			case "/reset":
				var resetLM = GetNode<LevelManager>("/root/LevelManager");
				if (resetLM != null)
				{
					resetLM.NivelAtual = 1;
					resetLM.PontuacaoTotal = 0;
					NomeJogador = "José";
					SaveManager.Instance.SalvarJogo();
					LogSystem("Sucesso: Progresso de jogo completamente resetado!", "green");
					
					// Recarrega a cena atual para aplicar as alterações
					GetTree().ReloadCurrentScene();
				}
				break;

			case "/clear":
				if (_richTextLabel != null)
				{
					_richTextLabel.Clear();
					LogSystem("Console limpo.", "green");
				}
				break;

			case "/reload":
				LogSystem("Recarregando cena atual...", "yellow");
				GetTree().ReloadCurrentScene();
				break;

			case "/mainmenu":
				LogSystem("Retornando para o menu principal...", "yellow");
				GetTree().ChangeSceneToFile("res://ui/main_menu.tscn");
				break;

			default:
				LogSystem($"Comando '{cmd}' desconhecido. Digite /help para ajuda.", "red");
				break;
		}
	}
}
