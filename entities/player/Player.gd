extends Node2D

var player: CharacterBody2D
var velocidade: float = 5.0
var is_on_floor_flag: bool = false

func _ready() -> void:
	player = get_node("CharacterBody2D") as CharacterBody2D

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var andar_esq = Input.is_action_pressed("ui_left")
	var andar_dir = Input.is_action_pressed("ui_right")
	var pular = Input.is_action_just_pressed("ui_up")
	
	if player:
		player.move_and_slide()
		
		if player.is_on_floor() and pular:
			is_on_floor_flag = false
			position += Vector2.UP * 125.0
			
		if player.is_on_floor():
			print("Character is on the floor.")
			is_on_floor_flag = true

	position += Vector2.DOWN * 250.0 * delta
	
	if andar_esq:
		position += Vector2.LEFT * velocidade
	if andar_dir:
		position += Vector2.RIGHT * velocidade
