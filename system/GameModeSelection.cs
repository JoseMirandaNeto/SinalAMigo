using Godot;
using System;

public partial class GameModeSelection : Control
{
	private Button _btnVoltar;

	public override void _Ready()
	{
		_btnVoltar = GetNode<Button>("Button");
		if (_btnVoltar != null)
		{
			_btnVoltar.Pressed += OnBtnVoltarPressed;
		}
		else
		{
			GD.PrintErr("GameModeSelection: Botao de voltar nao encontrado!");
		}
	}

	private void OnBtnVoltarPressed()
	{
		string menuPath = "res://ui/main_menu.tscn";
		var error = GetTree().ChangeSceneToFile(menuPath);
		if (error != Error.Ok)
		{
			GD.PrintErr($"GameModeSelection: Erro ao retornar para o menu {menuPath}: {error}");
		}
		else
		{
			GD.Print("GameModeSelection: Retornando ao menu principal...");
		}
	}
}
