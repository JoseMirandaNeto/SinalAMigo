@tool
extends Resource
class_name SinalLibras

enum CategoriaSinal {
	BASICO,
	VENDAS,
	SAUDACOES,
	ALIMENTOS
}

@export var nome_da_palavra: String = ""
@export var ilustracao: Texture2D
@export var video_sinal: VideoStream
@export var imagem_significado: Texture2D
@export var categoria: CategoriaSinal = CategoriaSinal.BASICO
