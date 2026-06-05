using Godot;
using System;

public partial class Player : Node2D
{
	CharacterBody2D player;
	float velocidade = 5;
	bool is_on_floor = false;
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		player = GetNode<CharacterBody2D>("CharacterBody2D");
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta){
		
	}
	
	public override void _PhysicsProcess(double delta)
	{
		var andarEsq = Input.IsActionPressed("ui_left");
		var andarDir = Input.IsActionPressed("ui_right");
		var pular = Input.IsActionJustPressed("ui_up");
		
		player.MoveAndSlide();

		Position += Vector2.Down * 250 * (float)delta;
		
		if (andarEsq)
		{
			Position += Vector2.Left * velocidade;
		}
		if (andarDir)
		{
			Position += Vector2.Right * velocidade;
		}
		
		if (player.IsOnFloor() && pular)
		{
			is_on_floor = false;
			Position += Vector2.Up * 125;
		}
		
		if (player.IsOnFloor())
		{
			GD.Print("Character is on the floor.");
			is_on_floor = true;
		}
	}
}
