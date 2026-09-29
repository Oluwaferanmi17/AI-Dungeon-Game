#extends Area2D
#
#func _ready() -> void:
	#body_entered.connect(_on_body_entered)
#
#func _on_body_entered(body: Node2D) -> void:
	#if body.is_in_group("player"):
		#GameState.change_scene("res://scenes/world/forest.tscn")

extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if "missing_merchant" in GameState.active_quests:
			GameState.complete_objective("missing_merchant", 1)  # "Investigate the forest"
		GameState.change_scene("res://scenes/world/forest.tscn")
