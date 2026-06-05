using Godot;
using System;

public partial class Carta : TextureButton
{
	[Export] public int ID; // Cartas com o mesmo ID formam um par
	public bool Virada = false;
	public bool Combinada = false;

	private Panel _background;
	private TextureRect _conteudo;
	private Label _labelTexto;
	private StyleBoxFlat _estiloNormal;
	
	// Cache para quando for configurada antes de _Ready
	private Texture2D _tempImagem;
	private string _tempTexto;
	private bool _tempMostrarImagem;
	private bool _configurado = false;

	// Cores baseadas no Sinalito
	private readonly Color _corVerso = new Color("#0056b3");   // Azul vibrante
	private readonly Color _corFrente = new Color("#ffffff");   // Branco para contraste
	private readonly Color _corAcerto = new Color("#8dc63f");   // Verde Sinalito

	public override void _Ready()
	{
		_background = GetNode<Panel>("Background");
		_conteudo = GetNode<TextureRect>("MarginContainer/Conteudo");
		_labelTexto = GetNode<Label>("MarginContainer/LabelTexto");
		
		// Garante que o pivô de escala seja o centro para a rotação de flip
		PivotOffset = Size / 2;
		Resized += () => PivotOffset = Size / 2;

		if (_conteudo != null)
		{
			_conteudo.Visible = false;
		}
		if (_labelTexto != null)
		{
			_labelTexto.Visible = false;
		}
		
		// Criando o estilo programaticamente para seguir a marca
		_estiloNormal = new StyleBoxFlat();
		_estiloNormal.BgColor = _corVerso;
		_estiloNormal.CornerRadiusTopLeft = 20;
		_estiloNormal.CornerRadiusTopRight = 20;
		_estiloNormal.CornerRadiusBottomLeft = 20;
		_estiloNormal.CornerRadiusBottomRight = 20;
		_estiloNormal.BorderWidthBottom = 4;
		_estiloNormal.BorderColor = new Color(0, 0.2f, 0.5f); // Azul escuro para a sombra 3D
		
		// Aplica o override no botão
		AddThemeStyleboxOverride("normal", _estiloNormal);

		// Se já foi configurado antes de entrar na árvore, aplica agora
		if (_configurado)
		{
			AplicarConfiguracao();
		}
	}

	public void ConfigurarCarta(Texture2D imagem, string texto, bool mostrarImagem)
	{
		_tempImagem = imagem;
		_tempTexto = texto;
		_tempMostrarImagem = mostrarImagem;
		_configurado = true;

		if (IsInsideTree())
		{
			AplicarConfiguracao();
		}
	}

	private void AplicarConfiguracao()
	{
		if (_tempMostrarImagem)
		{
			if (_conteudo != null)
			{
				_conteudo.Texture = _tempImagem;
				_conteudo.Visible = false;
			}
			// Não deletamos mais _labelTexto, apenas o ocultamos
			if (_labelTexto != null)
			{
				_labelTexto.Visible = false;
			}
		}
		else
		{
			if (_conteudo != null)
			{
				_conteudo.Visible = false;
				_conteudo.Texture = null;
			}

			if (_labelTexto != null)
			{
				_labelTexto.Text = _tempTexto;
				_labelTexto.Visible = false;
			}
		}
	}

	public void AplicarEstiloAcerto()
	{
		if (_background == null) return;

		StyleBoxFlat estiloAcerto = (StyleBoxFlat)_background.GetThemeStylebox("panel").Duplicate();
		estiloAcerto.BorderWidthBottom = 6;
		estiloAcerto.BorderColor = _corAcerto; // Borda verde de sucesso
		estiloAcerto.BgColor = new Color("#e2f0d9"); // Fundo esverdeado sutil
		
		_background.AddThemeStyleboxOverride("panel", estiloAcerto);
	}

	public void Virar(bool mostrar)
	{
		if (Virada == mostrar) return;
		Virada = mostrar;

		// Animação 3D de Flip (escala horizontal X para 0 e volta para 1)
		Tween tween = CreateTween().BindNode(this).SetTrans(Tween.TransitionType.Quad).SetEase(Tween.EaseType.Out);
		
		// Fase 1: Encolhe a escala X a zero para ocultar o lado anterior
		tween.TweenProperty(this, "scale:x", 0.0f, 0.15f);
		
		// Fase 2: Troca as texturas/visibilidade enquanto a escala é zero
		tween.TweenCallback(Callable.From(() => {
			// Atualiza visibilidade dos conteúdos internos
			if (_conteudo != null && _conteudo.Texture != null)
			{
				_conteudo.Visible = mostrar;
			}
			
			if (_labelTexto != null)
			{
				_labelTexto.Visible = mostrar;
			}

			// Atualiza cor do fundo
			StyleBoxFlat estilo = (StyleBoxFlat)_background.GetThemeStylebox("panel").Duplicate();
			if (mostrar)
			{
				estilo.BgColor = _corFrente; // Frente: Branca
				estilo.BorderColor = new Color(0.8f, 0.8f, 0.8f); // Borda cinza suave
			}
			else
			{
				estilo.BgColor = _corVerso; // Verso: Azul
				estilo.BorderColor = new Color(0, 0.2f, 0.5f);
			}
			_background.AddThemeStyleboxOverride("panel", estilo);
		}));

		// Fase 3: Restaura a escala X para 1.0 exibindo o novo lado
		tween.TweenProperty(this, "scale:x", 1.0f, 0.15f);
	}
}
