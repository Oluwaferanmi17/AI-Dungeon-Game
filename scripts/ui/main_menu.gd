extends Control

@onready var start_button: Button = $VBoxContainer/Button

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	GameManager.set_state(GameManager.State.PLAYING)
	GameState.change_scene("res://scenes/main/main.tscn")
	
	
