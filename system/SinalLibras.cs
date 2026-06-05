using Godot;
using System;

[GlobalClass] // Faz o Resource aparecer no menu "Create New Resource"
public partial class SinalLibras : Resource
{
	[Export] public string NomeDaPalavra; // Ex: "Obrigado" ou "Cartão de Crédito"
	
	[Export] public Texture2D Ilustracao; // A imagem estática do sinal
	
	[Export] public VideoStream VideoSinal; // Para o "Detetive do Contexto" ou vídeos curtos
	
	[Export] public Texture2D ImagemSignificado; // Foto do objeto real (útil para o Memory Game)
	
	[Export] public CategoriaSinal Categoria = CategoriaSinal.Basico;

	public enum CategoriaSinal
	{
		Basico,
		Vendas, // Foco no seu curso do SENAC
		Saudacoes,
		Alimentos
	}
}
