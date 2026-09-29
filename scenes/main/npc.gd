extends Area2D

@export var npc_id: String = "wizard"

func _ready() -> void:
	set_meta("npc_id", npc_id)
