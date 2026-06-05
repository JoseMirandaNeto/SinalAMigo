using Godot;
using System;

public partial class SafeAreaHandler : MarginContainer
{
	public override void _Ready()
	{
		AjustarAreaSegura();
		
		// Se a tela girar, reajusta (útil para tablets)
		GetViewport().SizeChanged += AjustarAreaSegura;
	}

	private void AjustarAreaSegura()
	{
		// 1. Só realiza cálculos complexos de Safe Area no Android ou iOS.
		// No Windows/macOS/Linux a janela pode ser menor que a tela inteira, o que geraria valores negativos ou gigantescos.
		string osName = OS.GetName();
		if (osName != "Android" && osName != "iOS")
		{
			// Desktop não possui notches, mantemos a margem padrão vazia
			AddThemeConstantOverride("margin_left", 0);
			AddThemeConstantOverride("margin_top", 0);
			AddThemeConstantOverride("margin_right", 0);
			AddThemeConstantOverride("margin_bottom", 0);
			return;
		}

		// 2. Cálculo para celulares/tablets (Válido em tela cheia)
		Rect2I safeArea = DisplayServer.GetDisplaySafeArea();
		Vector2I windowSize = DisplayServer.WindowGetSize();

		int margemEsquerda = safeArea.Position.X;
		int margemSuperior = safeArea.Position.Y;
		int margemDireita = windowSize.X - safeArea.End.X;
		int margemInferior = windowSize.Y - safeArea.End.Y;

		// Compensação extra de segurança (ex: 20 pixels)
		int compensacaoExtra = 20; 

		AddThemeConstantOverride("margin_left", margemEsquerda + compensacaoExtra);
		AddThemeConstantOverride("margin_top", margemSuperior + compensacaoExtra);
		AddThemeConstantOverride("margin_right", margemDireita + compensacaoExtra);
		AddThemeConstantOverride("margin_bottom", margemInferior + compensacaoExtra);
		
		GD.Print($"SafeAreaHandler: Safe Area aplicada no dispositivo móvel. Margens: L:{margemEsquerda}, T:{margemSuperior}, R:{margemDireita}, B:{margemInferior}");
	}
}
